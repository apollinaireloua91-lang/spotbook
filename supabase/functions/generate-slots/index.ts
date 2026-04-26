// generate-slots — Pro availability → time_slots materialization (cron + manual).
// Auth: Vault-stored shared secret via get_cron_shared_secret() RPC. Used by
// pg_cron daily AND callable from another Edge Function (Edge → Edge).
// Bypassing the gateway (verify_jwt=false) sidesteps the legacy JWT migration.
//
// Modes:
//   POST {} — regenerate for ALL approved Pros (cron daily)
//   POST { proId } — single-Pro regeneration (e.g., after Pro saves availability)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const DAYS_AHEAD = 30;
const SLOT_GRANULARITY_MINUTES = 15;

function securityHeadersFor(): Record<string, string> {
  return {
    "Access-Control-Allow-Origin": "https://getspotbook.app",
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
  };
}

function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...securityHeadersFor(), "Content-Type": "application/json" },
  });
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let r = 0;
  for (let i = 0; i < a.length; i++) r |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return r === 0;
}

function isValidUuid(v: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(v);
}

let _cachedCronSecret: string | null = null;
async function assertCronAuth(req: Request): Promise<Response | null> {
  const auth = req.headers.get("Authorization") ?? "";
  if (!_cachedCronSecret) {
    const url = Deno.env.get("SUPABASE_URL") ?? "";
    const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!url || !key) return jsonResponse({ error: "server_misconfigured" }, 500);
    const c = createClient(url, key);
    const { data, error } = await c.rpc("get_cron_shared_secret");
    if (error || typeof data !== "string" || !data.length) {
      console.error("[generate-slots] vault read failed:", error);
      return jsonResponse({ error: "server_misconfigured" }, 500);
    }
    _cachedCronSecret = data;
  }
  if (!timingSafeEqual(auth, `Bearer ${_cachedCronSecret}`)) {
    return jsonResponse({ error: "forbidden" }, 403);
  }
  return null;
}

interface AvailabilityRule {
  pro_id: string;
  day_of_week: number;
  start_time: string;
  end_time: string;
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
  return `${String(Math.floor(m / 60)).padStart(2, "0")}:${String(m % 60).padStart(2, "0")}`;
}

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
      last.end = Math.max(last.end, cur.end);
    } else {
      merged.push({ ...cur });
    }
  }
  return merged;
}

function subtractBreak(
  ranges: Array<{ start: number; end: number }>,
  breakRange: { start: number; end: number } | null,
): Array<{ start: number; end: number }> {
  if (!breakRange) return ranges;
  const out: Array<{ start: number; end: number }> = [];
  for (const r of ranges) {
    if (breakRange.end <= r.start || breakRange.start >= r.end) {
      out.push(r);
      continue;
    }
    if (breakRange.start > r.start) out.push({ start: r.start, end: breakRange.start });
    if (breakRange.end < r.end) out.push({ start: breakRange.end, end: r.end });
  }
  return out;
}

async function generateForPro(
  supabase: ReturnType<typeof createClient>,
  proId: string,
): Promise<number> {
  const [rulesRes, exceptionsRes, profileRes, existingBookedRes] = await Promise.all([
    supabase.from("availability_rules")
      .select("pro_id, day_of_week, start_time, end_time, lunch_break_start, lunch_break_end")
      .eq("pro_id", proId),
    supabase.from("availability_exceptions")
      .select("exception_date, is_closed, custom_start, custom_end")
      .eq("pro_id", proId),
    supabase.from("profiles_pro")
      .select("availability")
      .eq("id", proId)
      .maybeSingle(),
    supabase.from("time_slots")
      .select("date, start_time, end_time, is_available")
      .eq("pro_id", proId)
      .eq("is_available", false),
  ]);

  const rules = (rulesRes.data ?? []) as AvailabilityRule[];
  const exceptions = (exceptionsRes.data ?? []) as AvailabilityException[];
  const blockedSet = new Set<string>(
    (((profileRes.data?.availability as Record<string, unknown>) ?? {})?.blocked_dates as string[]) ?? [],
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

    if (blockedSet.has(dateStr)) continue;

    const ex = exceptions.find((e) => e.exception_date === dateStr);
    if (ex && ex.is_closed) continue;

    let ranges: Array<{ start: number; end: number }> = [];
    let lunchBreak: { start: number; end: number } | null = null;

    if (ex && ex.custom_start && ex.custom_end) {
      ranges = [{ start: timeToMinutes(ex.custom_start), end: timeToMinutes(ex.custom_end) }];
    } else {
      const matching = rules.filter((r) => r.day_of_week === dayOfWeek);
      if (matching.length === 0) continue;

      ranges = matching.map((r) => ({
        start: timeToMinutes(r.start_time),
        end: timeToMinutes(r.end_time),
      }));

      const firstWithLunch = matching.find((r) => r.lunch_break_start && r.lunch_break_end);
      if (firstWithLunch) {
        lunchBreak = {
          start: timeToMinutes(firstWithLunch.lunch_break_start!),
          end: timeToMinutes(firstWithLunch.lunch_break_end!),
        };
      }
    }

    ranges = mergeRanges(ranges);
    ranges = subtractBreak(ranges, lunchBreak);

    for (const range of ranges) {
      for (let t = range.start; t + SLOT_GRANULARITY_MINUTES <= range.end; t += SLOT_GRANULARITY_MINUTES) {
        const startStr = minutesToTime(t);
        const endStr = minutesToTime(t + SLOT_GRANULARITY_MINUTES);
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
  if (req.method === "OPTIONS") return new Response("ok", { headers: securityHeadersFor() });
  if (req.method !== "POST") return jsonResponse({ error: "method_not_allowed" }, 405);

  const forbidden = await assertCronAuth(req);
  if (forbidden) return forbidden;

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    let targetProId: string | null = null;
    try {
      const body = await req.json();
      const rawId = body?.proId;
      if (rawId && typeof rawId === "string" && isValidUuid(rawId)) {
        targetProId = rawId;
      }
    } catch {
      // empty body → all-pros mode
    }

    const errors: Array<{ pro_id: string; error: string }> = [];
    let totalSlots = 0;

    if (targetProId) {
      try {
        totalSlots = await generateForPro(supabase, targetProId);
      } catch (e) {
        errors.push({ pro_id: targetProId, error: (e as Error).message });
      }
    } else {
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
    console.error("[generate-slots] error:", error);
    return jsonResponse({ error: "internal_error" }, 500);
  }
});
