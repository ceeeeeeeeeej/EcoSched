// Supabase Edge Function: send-push
// Sends FCM push notification via HTTP v1 API
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.7";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
};

console.log("🚀 Edge Function 'send-push' v14-bulletproof loaded");

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
    const { resident_id, title, body, notification_body } = await req.json();
    const msgBody = body || notification_body || "New bin alert from EcoSched";
    
    console.log(`📍 Incoming push request for user: ${resident_id}`);

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseKey) {
      throw new Error("Missing Supabase environment variables");
    }

    // Connect to Supabase
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Get FCM tokens
    const { data: devices, error: devError } = await supabase
      .from("user_devices")
      .select("fcm_token")
      .eq("resident_id", resident_id)
      .not("fcm_token", "is", null);

    if (devError) throw new Error(`DB Error while fetching tokens: ${devError.message}`);

    if (!devices || devices.length === 0) {
      console.warn(`⚠️ No tokens found for resident_id: ${resident_id}`);
      return new Response(JSON.stringify({ success: true, sent: 0, reason: "no_tokens" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Get FCM Auth from Secret
    const saText = Deno.env.get("FCM_SERVICE_ACCOUNT");
    if (!saText) throw new Error("FCM_SERVICE_ACCOUNT secret is missing");

    let sa;
    try {
      sa = JSON.parse(saText);
    } catch (e) {
      const error = e instanceof Error ? e.message : String(e);
      throw new Error(`Failed to parse FCM_SERVICE_ACCOUNT JSON: ${error}`);
    }

    if (!sa.project_id || !sa.client_email || !sa.private_key) {
      throw new Error("FCM_SERVICE_ACCOUNT JSON is missing required fields");
    }

    const accessToken = await getAccessToken(sa.client_email, sa.private_key);
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;
    let count = 0;

    for (const dev of devices) {
      try {
        const res = await fetch(fcmUrl, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token: dev.fcm_token,
              notification: { title: title || "EcoSched Alert", body: msgBody },
              android: { 
                priority: "high",
                notification: { channel_id: "ecosched_alerts" } 
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