// Supabase Edge Function: send-push-v2
// Sends FCM push notification via HTTP v1 API
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.7";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
};

console.log("🚀 Edge Function 'send-push-v2' v2-bulletproof loaded");

async function getAccessToken(clientEmail: string, privateKey: string) {
  if (!clientEmail || !privateKey) {
    throw new Error("Missing clientEmail or privateKey for FCM auth");
  }
  
  const header = { alg: "RS256", typ: "JWT" };
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: clientEmail,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  const b64 = (obj: object) => btoa(JSON.stringify(obj)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  const message = `${b64(header)}.${b64(payload)}`;

  const cleanedKey = privateKey
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\\n/g, "")
    .replace(/[^A-Za-z0-9+/=]/g, "");

  if (!cleanedKey) throw new Error("Private key is empty after cleaning");

  const binaryDer = Uint8Array.from(atob(cleanedKey), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(message));
  const encodedSignature = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${message}.${encodedSignature}`,
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Google OAuth Fetch failed: ${response.status} ${errorText}`);
  }

  const data = await response.json();
  return data.access_token;
}

Deno.serve(async (req: Request) => {
  // 1. Handle Preflight OPTIONS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const rawPayload = await req.json();
    
    // 🎁 Unwrap Database Webhook Payload OR Normal Payload
    const data = rawPayload.record ? rawPayload.record : rawPayload;

    const title = data.title;
    const body = data.message || data.body || data.notification_body;
    const type = data.type || "alert";
    const resident_id = data.user_id || data.resident_id; // Webhook uses 'user_id'
    const barangay = data.barangay;
    const broadcast = data.broadcast;
    const collapse_key = data.collapse_key;

    const msgBody = body || "New alert from EcoSched";
    const msgTitle = title || "EcoSched Alert";
    
    if (broadcast) {
      console.log(`📣 Broadcast push request (all devices)`);
    } else if (resident_id) {
      console.log(`📍 Targeted push request for user: ${resident_id}`);
    } else if (barangay) {
      console.log(`🏘️ Area push request for barangay: ${barangay}`);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseKey) {
      throw new Error("Missing Supabase environment variables");
    }

    // Connect to Supabase
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Get FCM tokens (broadcast = all, targeted = resident_id, area = barangay)
    let devicesQuery = supabase
      .from("user_devices")
      .select("fcm_token")
      .not("fcm_token", "is", null);

    if (broadcast) {
      // No filter needed
    } else if (resident_id) {
      devicesQuery = devicesQuery.eq("resident_id", resident_id);
    } else if (barangay) {
      // 🕵️ Case-Insensitive filtering (e.g. "Victoria" vs "victoria")
      devicesQuery = devicesQuery.ilike("barangay", barangay);
    } else {
       // If none of the above, we treat it as broadcast to be safe OR fail.
       // Let's assume broadcast if nothing is specified for backward compatibility.
       console.warn("⚠️ No targets (resident_id, barangay, broadcast) specified. Defaulting to broadcast.");
    }

    const { data: devices, error: devError } = await devicesQuery;

    if (devError) throw new Error(`DB Error while fetching tokens: ${devError.message}`);

    if (!devices || devices.length === 0) {
      console.warn(`⚠️ No tokens found for target. Type: ${resident_id ? 'targeted' : (barangay ? 'area' : 'broadcast')}`);
      return new Response(JSON.stringify({ 
        success: false, 
        sent: 0, 
        reason: "no_tokens_registered",
        message: "No FCM tokens found for the specified target."
      }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    console.log(`📱 Found ${devices.length} device records. Deduplicating tokens...`);

    // Get FCM Auth from Secret
    const saText = Deno.env.get("FCM_SERVICE_ACCOUNT");
    if (!saText) throw new Error("FCM_SERVICE_ACCOUNT secret is missing");

    let sa;
    try {
      sa = JSON.parse(saText);
    } catch (e: unknown) {
      const error = e instanceof Error ? e.message : String(e);
      throw new Error(`Failed to parse FCM_SERVICE_ACCOUNT JSON: ${error}`);
    }

    const accessToken = await getAccessToken(sa.client_email, sa.private_key);
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;
    let count = 0;

    // Deduplicate tokens
    const uniqueTokens = [...new Set(devices.map(d => d.fcm_token).filter(Boolean))];
    
    // Determine a stable collapse key for deduplication if not provided
    // For manual grouping: "truck_status", "bin_status", etc.
    let finalCollapseKey = collapse_key;
    if (!finalCollapseKey) {
      if (msgTitle.toLowerCase().includes("truck") || msgTitle.includes("🚛")) finalCollapseKey = "truck_arrival";
      if (msgTitle.toLowerCase().includes("bin") || msgTitle.includes("🗑️")) finalCollapseKey = "bin_status";
      if (msgTitle.toLowerCase().includes("reminder")) finalCollapseKey = "schedule_reminder";
    }

    for (const token of uniqueTokens) {
      try {
        const res = await fetch(fcmUrl, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token: token,
              notification: { title: msgTitle, body: msgBody },
              android: { 
                priority: "high",
                collapse_key: finalCollapseKey || undefined, // Overwrites notifications in the system tray with the same key
                notification: { 
                    channel_id: "ecosched_alerts",
                    tag: finalCollapseKey || undefined // Ensures visual overwriting on older Android versions
                } 
              },
              apns: {
                headers: {
                    'apns-collapse-id': finalCollapseKey || undefined
                }
              }
            },
          }),
        });
        if (res.ok) count++;
        else {
            const errText = await res.text();
            console.error(`❌ FCM failed for token: ${errText}`);
        }
      } catch (e: unknown) {
        const error = e instanceof Error ? e.message : String(e);
        console.error(`❌ Fetch error for token: ${error}`);
      }
    }

    console.log(`✅ Push cycle complete. Sent: ${count}/${devices.length}`);

    return new Response(JSON.stringify({ success: true, sent: count, total: devices.length }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (err: unknown) {
    const error = err instanceof Error ? err.message : String(err);
    console.error(`💥 Function error: ${error}`);
    return new Response(JSON.stringify({ error: error }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
