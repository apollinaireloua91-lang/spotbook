import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const now = new Date();
    const twoHoursAgo = new Date(now.getTime() - 2 * 60 * 60 * 1000);
    let sentCount = 0;

    // Find completed bookings where review hasn't been requested yet
    // and the booking was completed at least 2 hours ago
    const { data: bookings } = await supabase
      .from("bookings")
      .select(
        "id, client_id, time_slots(pro_id), services(name)"
      )
      .eq("status", "completed")
      .is("review_requested_at", null)
      .lte("updated_at", twoHoursAgo.toISOString());

    for (const booking of bookings ?? []) {
      const service = booking.services as Record<string, unknown> | null;
      const serviceName = (service?.name as string) ?? "votre prestation";

      // Send push to client asking for review
      await fetch(`${supabaseUrl}/functions/v1/send-push-notification`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${serviceKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          userId: booking.client_id,
          title: "Comment s'est passé votre RDV ?",
          body: `Donnez votre avis sur « ${serviceName} »`,
          type: "review_request",
          data: { bookingId: booking.id as string },
        }),
      });

      // Mark as review requested
      await supabase
        .from("bookings")
        .update({ review_requested_at: now.toISOString() })
        .eq("id", booking.id);

      sentCount++;
    }

    return new Response(
      JSON.stringify({ success: true, review_requests_sent: sentCount }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
