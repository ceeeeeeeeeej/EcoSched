// Supabase Edge Function: send-push
// Sends FCM push notification via HTTP v1 API
// Requires secrets: FCM_PROJECT_ID, FCM_CLIENT_EMAIL, FCM_PRIVATE_KEY

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.7";

console.log("🚀 Edge Function 'send-push' v5-v1-api loaded");

// Helper to generate Google OAuth2 Access Token for FCM scope
async function getAccessToken(clientEmail: string, privateKey: string) {
  const header = { alg: "RS256", typ: "JWT" };
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: clientEmail,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  const encodedHeader = btoa(JSON.stringify(header)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  const encodedPayload = btoa(JSON.stringify(payload)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  const message = `${encodedHeader}.${encodedPayload}`;

  // Clean the private key (remove headers/footers and whitespace)
  const pemHeader = "-----BEGIN PRIVATE KEY-----";
  const pemFooter = "-----END PRIVATE KEY-----";
  const pemContents = privateKey
    .replace(pemHeader, "")
    .replace(pemFooter, "")
    .replace(/\s/g, "");

  const binaryDer = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(message),
  );

  const encodedSignature = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");

  const jwt = `${message}.${encodedSignature}`;

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const data = await response.json();
  if (!response.ok) throw new Error(`OAuth Error: ${JSON.stringify(data)}`);
  return data.access_token;
}

Deno.serve(async (req: Request) => {
  // Handle CORS
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
        "Access-Control-Max-Age": "86400",
      },
    });
  }

  try {
    const { resident_id, title, notification_body } = await req.json();
    const msgBody = notification_body || "Your request status has been updated.";

    if (!resident_id || !title) {
      return new Response(JSON.stringify({ error: "Missing resident_id or title" }), {
        status: 400,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    const saJson = Deno.env.get("FCM_SERVICE_ACCOUNT");
    let projectId = Deno.env.get("FCM_PROJECT_ID");
    let clientEmail = Deno.env.get("FCM_CLIENT_EMAIL");
    let privateKey = Deno.env.get("FCM_PRIVATE_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    // Fallback to Service Account JSON if individual keys are missing
    if (saJson && (!projectId || !clientEmail || !privateKey)) {
      try {
        const sa = JSON.parse(saJson);
        projectId = projectId || sa.project_id;
        clientEmail = clientEmail || sa.client_email;
        privateKey = privateKey || sa.private_key;
        console.log("📂 Credentials supplemented from FCM_SERVICE_ACCOUNT JSON");
      } catch (e) {
        console.error("❌ FCM_SERVICE_ACCOUNT is not valid JSON");
      }
    }

    if (!projectId || !clientEmail || !privateKey) {
      const missing = [];
      if (!projectId) missing.push("FCM_PROJECT_ID");
      if (!clientEmail) missing.push("FCM_CLIENT_EMAIL");
      if (!privateKey) missing.push("FCM_PRIVATE_KEY");
      
      console.error("❌ FCM V1 credentials missing:", missing.join(", "));
      return new Response(JSON.stringify({ 
        error: "FCM V1 configuration missing", 
        missing_keys: missing,
        has_sa_json: !!saJson
      }), {
        status: 500,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    // Connect to Supabase to find tokens
    const supabase = createClient(supabaseUrl, supabaseKey);
    const { data: devices, error: devError } = await supabase
      .from("user_devices")
      .select("fcm_token")
      .eq("resident_id", resident_id)
      .not("fcm_token", "is", null);

    if (devError || !devices || devices.length === 0) {
      console.warn("⚠️ No FCM tokens for:", resident_id);
      return new Response(JSON.stringify({ success: true, sent: 0, reason: "no_tokens" }), {
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    const accessToken = await getAccessToken(clientEmail, privateKey);
    const fcmV1Url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
    
    let successCount = 0;
    const errors = [];

    for (const { fcm_token } of devices) {
      const payload = {
        message: {
          token: fcm_token,
          notification: { title, body: msgBody },
          data: { type: "approval", click_action: "FLUTTER_NOTIFICATION_CLICK" },
          android: { priority: "high", notification: { channel_id: "ecosched_alerts", sound: "default" } },
          apns: { payload: { aps: { sound: "default" } } },
        },
      };

      const res = await fetch(fcmV1Url, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(payload),
      });

      if (res.ok) {
        successCount++;
      } else {
        const err = await res.json();
        errors.push(err);
      }
    }

    return new Response(
      JSON.stringify({ success: true, sent: successCount, total: devices.length, errors }),
      {
        headers: { 
          "Content-Type": "application/json", 
          "Access-Control-Allow-Origin": "*",
          "X-Edge-Function-Version": "v5-v1-api"
        },
      }
    );
  } catch (err) {
    console.error("💥 send-push error:", err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  }
});
