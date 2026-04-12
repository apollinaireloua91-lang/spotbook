import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { assertServiceRoleOnly, jsonResponse, securityHeaders } from "../_shared/security.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: securityHeaders });
  }

  const forbidden = assertServiceRoleOnly(req);
  if (forbidden) return forbidden;

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const { data: pros, error: prosErr } = await supabase
      .from("profiles_pro")
      .select("id")
      .eq("kyc_status", "approved");
    if (prosErr) throw prosErr;

    let totalSlots = 0;

    for (const pro of pros ?? []) {
      const { data: rules, error: rulesErr } = await supabase
        .from("availability_rules")
        .select("*")
        .eq("pro_id", pro.id);
      if (rulesErr || !rules?.length) continue;

      const today = new Date();
      today.setHours(0, 0, 0, 0);

      for (let dayOffset = 0; dayOffset < 14; dayOffset++) {
        const date = new Date(today);
        date.setDate(date.getDate() + dayOffset);
        const dayOfWeek = date.getDay(); // 0=Sun ... 6=Sat
        const dateStr = date.toISOString().split("T")[0];

        const matchingRules = rules.filter(
          (r: Record<string, unknown>) => r.day_of_week === dayOfWeek
        );

        for (const rule of matchingRules) {
          const slotDuration = (rule.slot_duration_minutes as number) || 60;
          const [startH, startM] = (rule.start_time as string)
            .split(":")
            .map(Number);
          const [endH, endM] = (rule.end_time as string)
            .split(":")
            .map(Number);
          const startMinutes = startH * 60 + startM;
          const endMinutes = endH * 60 + endM;

          for (
            let slotStart = startMinutes;
            slotStart + slotDuration <= endMinutes;
            slotStart += slotDuration
          ) {
            const slotStartStr = `${String(Math.floor(slotStart / 60)).padStart(2, "0")}:${String(slotStart % 60).padStart(2, "0")}`;
            const slotEndMin = slotStart + slotDuration;
            const slotEndStr = `${String(Math.floor(slotEndMin / 60)).padStart(2, "0")}:${String(slotEndMin % 60).padStart(2, "0")}`;

            // Upsert to avoid duplicates
            await supabase.from("time_slots").upsert(
              {
                pro_id: pro.id,
                date: dateStr,
                start_time: slotStartStr,
                end_time: slotEndStr,
                is_available: true,
              },
              { onConflict: "pro_id,date,start_time" }
            );
            totalSlots++;
          }
        }
      }
    }

    return jsonResponse({ success: true, generated: totalSlots });
  } catch (error) {
    console.error("generate-slots error:", error);
    return jsonResponse({ error: "internal_error" }, 500);
  }
});
