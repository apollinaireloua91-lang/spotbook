// ════════════════════════════════════════════════════════════════════════════
// generate-slots — Pro availability → time_slots materialization
// ────────────────────────────────────────────────────────────────────────────
// Reads each Pro's `availability_rules` + `availability_exceptions` +
// `profiles_pro.availability.blocked_dates` and generates `time_slots` rows
// for the next 30 days.
//
// Granularity: 15-minute slots. This enables multi-service bookings of any
// total duration (30, 45, 60, 75, 90... min) by reserving consecutive slots.
//
// Crucially: this function NEVER overwrites a slot where `is_available = false`
// (i.e. already booked) — we filter those out before upsert. Bookings are
// immutable history; only free slots get regenerated.
//
// Trigger modes:
//   - POST with empty body  → regenerate for ALL approved pros (cron daily)
//   - POST with { proId }   → regenerate for ONE pro (called after save)
//
// Security: service_role only.
// ════════════════════════════════════════════════════════════════════════════

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  assertServiceRoleOnly,
  isValidUuid,
  jsonResponse,
  securityHeaders,
} from "../_shared/security.ts";

const DAYS_AHEAD = 30;
const SLOT_GRANULARITY_MINUTES = 15;

interface AvailabilityRule {
  pro_id: string;
  day_of_week: number; // 0 = Sunday (JS convention, matches DB)
  start_time: string; // "09:00:00"
  end_time: string; // "18:00:00"
  lunch_break_start: string | null;
  lunch_break_end: string | null;
}

interface AvailabilityException {
  exception_date: string;
  is_closed: boolean;
  custom_start: string | null;
  custom_end: string | null;
}

interface SlotRow {
  pro_id: string;
  date: string;
  start_time: string;
  end_time: string;
  is_available: boolean;
}

function timeToMinutes(t: string): number {
  const [h, m] = t.split(":").map(Number);
  return h * 60 + (m || 0);
}

function minutesToTime(m: number): string {
  const h = Math.floor(m / 60);
  const min = m % 60;
  return `${String(h).padStart(2, "0")}:${String(min).padStart(2, "0")}`;
}

/**
 * Merge overlapping time ranges. Input [{9:00-12:00}, {11:00-14:00}] yields
 * [{9:00-14:00}]. Produces a defensive-copy, non-mutating.
 */
function mergeRanges(
  ranges: Array<{ start: number; end: number }>,
): Array<{ start: number; end: number }> {
  if (ranges.length === 0) return [];
  const sorted = [...ranges].sort((a, b) => a.start - b.start);
  const merged = [sorted[0]];
  for (let i = 1; i < sorted.length; i++) {
    const last = merged[merged.length - 1];
    const cur = sorted[i];
    if (cur.start <= last.end) {
      // Overlap — extend last
      last.end = Math.max(last.end, cur.end);
    } else {
      merged.push({ ...cur });
    }
  }
  return merged;
}

/**
 * Subtract a lunch break range from a list of time ranges.
 * E.g. [{9-18}] minus {12-13} = [{9-12}, {13-18}].
 */
function subtractBreak(
  ranges: Array<{ start: number; end: number }>,
  breakRange: { start: number; end: number } | null,
): Array<{ start: number; end: number }> {
  if (!breakRange) return ranges;
  const out: Array<{ start: number; end: number }> = [];
  for (const r of ranges) {
    if (breakRange.end <= r.start || breakRange.start >= r.end) {
      // No intersection
      out.push(r);
      continue;
    }
    // Keep the part before the break (if any)
    if (breakRange.start > r.start) {
      out.push({ start: r.start, end: breakRange.start });
    }
    // Keep the part after the break (if any)
    if (breakRange.end < r.end) {
      out.push({ start: breakRange.end, end: r.end });
    }
  }
  return out;
}

async function generateForPro(
  supabase: ReturnType<typeof createClient>,
  proId: string,
): Promise<number> {
  // Load rules, exceptions, and blocked_dates for this Pro.
  const [rulesRes, exceptionsRes, profileRes, existingBookedRes] =
    await Promise.all([
      supabase
        .from("availability_rules")
        .select("pro_id, day_of_week, start_time, end_time, lunch_break_start, lunch_break_end")
        .eq("pro_id", proId),
      supabase
        .from("availability_exceptions")
        .select("exception_date, is_closed, custom_start, custom_end")
        .eq("pro_id", proId),
      supabase
        .from("profiles_pro")
        .select("availability")
        .eq("id", proId)
        .maybeSingle(),
      // All slots that are NOT available (i.e. booked). We preserve these.
      supabase
        .from("time_slots")
        .select("date, start_time, end_time, is_available")
        .eq("pro_id", proId)
        .eq("is_available", false),
    ]);

  const rules = (rulesRes.data ?? []) as AvailabilityRule[];
  const exceptions = (exceptionsRes.data ?? []) as AvailabilityException[];
  const blockedSet = new Set<string>(
    (((profileRes.data?.availability as Record<string, unknown>) ?? {})
      ?.blocked_dates as string[]) ?? [],
  );
  const bookedKeys = new Set<string>(
    (existingBookedRes.data ?? []).map(
      (s: { date: string; start_time: string }) =>
        `${s.date}|${s.start_time.substring(0, 5)}`,
    ),
  );

  if (rules.length === 0) return 0;

  const today = new Date();
  today.setUTCHours(0, 0, 0, 0);

  const proSlots: SlotRow[] = [];

  for (let dayOffset = 0; dayOffset < DAYS_AHEAD; dayOffset++) {
    const date = new Date(today);
    date.setUTCDate(date.getUTCDate() + dayOffset);
    const dateStr = date.toISOString().split("T")[0];
    const dayOfWeek = date.getUTCDay();

    // 1) Blocked date → skip entirely
    if (blockedSet.has(dateStr)) continue;

    // 2) Check for exception on this date
    const ex = exceptions.find((e) => e.exception_date === dateStr);
    if (ex && ex.is_closed) continue;

    // 3) Build ranges for this day
    let ranges: Array<{ start: number; end: number }> = [];
    let lunchBreak: { start: number; end: number } | null = null;

    if (ex && ex.custom_start && ex.custom_end) {
      // Exception with custom hours overrides the weekly rule
      ranges = [
        {
          start: timeToMinutes(ex.custom_start),
          end: timeToMinutes(ex.custom_end),
        },
      ];
    } else {
      // Use weekly rules for this day of week
      const matching = rules.filter((r) => r.day_of_week === dayOfWeek);
      if (matching.length === 0) continue;

      ranges = matching.map((r) => ({
        start: timeToMinutes(r.start_time),
        end: timeToMinutes(r.end_time),
      }));

      // Use the first matching rule's lunch break (Pro should only have 1 rule/day)
      const firstWithLunch = matching.find(
        (r) => r.lunch_break_start && r.lunch_break_end,
      );
      if (firstWithLunch) {
        lunchBreak = {
          start: timeToMinutes(firstWithLunch.lunch_break_start!),
          end: timeToMinutes(firstWithLunch.lunch_break_end!),
        };
      }
    }

    // 4) Merge overlapping ranges, then subtract lunch break
    ranges = mergeRanges(ranges);
    ranges = subtractBreak(ranges, lunchBreak);

    // 5) Generate 15-min slots within each final range
    for (const range of ranges) {
      for (
        let t = range.start;
        t + SLOT_GRANULARITY_MINUTES <= range.end;
        t += SLOT_GRANULARITY_MINUTES
      ) {
        const startStr = minutesToTime(t);
        const endStr = minutesToTime(t + SLOT_GRANULARITY_MINUTES);
        // Skip slots that are already booked (preserve history)
        if (bookedKeys.has(`${dateStr}|${startStr}`)) continue;
        proSlots.push({
          pro_id: proId,
          date: dateStr,
          start_time: startStr,
          end_time: endStr,
          is_available: true,
        });
      }
    }
  }

  if (proSlots.length === 0) return 0;

  // Upsert — `onConflict` idempotent on (pro_id, date, start_time).
  // NOTE: doesn't overwrite `is_available = false` slots because we already
  // excluded them above via bookedKeys.
  const { error } = await supabase
    .from("time_slots")
    .upsert(proSlots, { onConflict: "pro_id,date,start_time" });

  if (error) {
    console.error(`[generate-slots] upsert failed pro=${proId}:`, error.message);
    throw error;
  }

  return proSlots.length;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: securityHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  const forbidden = assertServiceRoleOnly(req);
  if (forbidden) return forbidden;

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    // Parse optional proId to support single-pro regeneration
    let targetProId: string | null = null;
    try {
      const body = await req.json();
      const rawId = body?.proId;
      if (rawId && typeof rawId === "string" && isValidUuid(rawId)) {
        targetProId = rawId;
      }
    } catch {
      // empty body = all-pros mode
    }

    const errors: Array<{ pro_id: string; error: string }> = [];
    let totalSlots = 0;

    if (targetProId) {
      // Single-pro mode — no KYC filter (pro must be able to preview slots
      // even before approval in testing)
      try {
        totalSlots = await generateForPro(supabase, targetProId);
      } catch (e) {
        errors.push({ pro_id: targetProId, error: (e as Error).message });
      }
    } else {
      // All approved pros (cron mode)
      const { data: pros, error: prosErr } = await supabase
        .from("profiles_pro")
        .select("id")
        .eq("kyc_status", "approved");
      if (prosErr) throw prosErr;

      for (const pro of (pros ?? []) as Array<{ id: string }>) {
        try {
          totalSlots += await generateForPro(supabase, pro.id);
        } catch (e) {
          errors.push({ pro_id: pro.id, error: (e as Error).message });
        }
      }
    }

    return jsonResponse({
      success: errors.length === 0,
      generated: totalSlots,
      proId: targetProId,
      errors: errors.length > 0 ? errors : undefined,
    });
  } catch (error) {
    console.error("generate-slots error:", error);
    return jsonResponse({ error: "internal_error" }, 500);
  }
});
