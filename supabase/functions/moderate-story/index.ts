// Supabase Edge Function: Automated NSFW & Content Shield Moderation
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-factory@2";

const GCP_VISION_API_KEY = Deno.env.get("GCP_VISION_API_KEY") || "";

serve(async (req) => {
  try {
    const { story_id, media_url } = await req.json();

    if (!story_id || !media_url) {
      return new Response(JSON.stringify({ error: "Missing story_id or media_url" }), { status: 400 });
    }

    let isAdult = false;
    let isViolent = false;

    if (GCP_VISION_API_KEY) {
      const visionUrl = `https://vision.googleapis.com/v1/images:annotate?key=${GCP_VISION_API_KEY}`;
      const visionRes = await fetch(visionUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          requests: [
            {
              image: { source: { imageUri: media_url } },
              features: [{ type: "SAFE_SEARCH_DETECTION" }],
            },
          ],
        }),
      });

      const data = await visionRes.json();
      const safeSearch = data.responses?.[0]?.safeSearchAnnotation;

      if (safeSearch) {
        const adultLikelihood = safeSearch.adult;
        const violenceLikelihood = safeSearch.violence;

        if (adultLikelihood === "VERY_LIKELY" || adultLikelihood === "LIKELY") {
          isAdult = true;
        }
        if (violenceLikelihood === "VERY_LIKELY" || violenceLikelihood === "LIKELY") {
          isViolent = true;
        }
      }
    }

    if (isAdult || isViolent) {
      const supabaseAdmin = createClient(
        Deno.env.get("SUPABASE_URL") ?? "",
        Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
      );

      await supabaseAdmin
        .from("stories")
        .update({ is_flagged: true })
        .eq("id", story_id);

      return new Response(JSON.stringify({ flagged: true, reason: "NSFW/Violent Content Detected" }), { status: 200 });
    }

    return new Response(JSON.stringify({ flagged: false, status: "Clean" }), { status: 200 });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
});
