// Supabase Edge Function: send-push
// Sends FCM push notification via HTTP v1 API
// Requires secrets: FCM_PROJECT_ID, FCM_CLIENT_EMAIL, FCM_PRIVATE_KEY

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.7";

console.log("🚀 Edge Function 'send-push' v8-v1-trace loaded");

// Helper to generate Google OAuth2 Access Token for FCM scope
async function getAccessToken(clientEmail: string, privateKey: string) {
  try {
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

    // Keep only valid Base64 characters [A-Za-z0-9+/=]
    const cleanedKey = privateKey
      .replace(/-----BEGIN PRIVATE KEY-----/g, "")
      .replace(/-----END PRIVATE KEY-----/g, "")
      .replace(/\\n/g, "") // remove literal \n if exists
      .replace(/[^A-Za-z0-9+/=]/g, ""); // strip EVERYTHING else (spaces, quotes, etc)

    if (!cleanedKey || cleanedKey.length < 100) {
        console.error("❌ Private key is too short after cleaning:", cleanedKey.length);
        throw new Error("Private key is missing or invalid");
    }

    let binaryDer;
    try {
        binaryDer = Uint8Array.from(atob(cleanedKey), (c) => c.charCodeAt(0));
    } catch (e: any) {
        console.error("❌ atob failed for cleanedKey length:", cleanedKey.length);
        throw new Error(`Base64 decoding failed: ${e?.message || String(e)}`);
    }

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

    console.log("🔑 Requesting OAuth token from Google...");
    const response = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
    });

    if (!response.ok) {
        const errorText = await response.text();
        console.error("❌ Google OAuth Error:", errorText);
        throw new Error(`Google OAuth Failed (${response.status}): ${errorText}`);
    }

    const data = await response.json();
    return data.access_token;
  } catch (err: any) {
    console.error("❌ getAccessToken detail:", err);
    throw err;
  }
}

Deno.serve(async (req: Request) => {
  console.log("📍 Trace: Serve Start");
  
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
    console.log("📍 Trace: JSON Parsed", { resident_id, title });

    const saJson = Deno.env.get("FCM_SERVICE_ACCOUNT");
    let projectId = Deno.env.get("FCM_PROJECT_ID");
    let clientEmail = Deno.env.get("FCM_CLIENT_EMAIL");
    let privateKey = Deno.env.get("FCM_PRIVATE_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    // Fallback to Service Account JSON
    if (saJson && (!projectId || !clientEmail || !privateKey)) {
      try {
        const sa = JSON.parse(saJson);
        projectId = projectId || sa.project_id;
        clientEmail = clientEmail || sa.client_email;
        privateKey = privateKey || sa.private_key;
        console.log("📂 Credentials supplemented from FCM_SERVICE_ACCOUNT JSON");
      } catch (_e) {
        console.error("❌ FCM_SERVICE_ACCOUNT is not valid JSON");
      }
    }

    if (!projectId || !clientEmail || !privateKey) {
      console.error("❌ Missing credentials trace:", { projectId: !!projectId, clientEmail: !!clientEmail, privateKey: !!privateKey });
      return new Response(JSON.stringify({ error: "Configuration missing", missing: [!projectId && "projectId", !clientEmail && "clientEmail", !privateKey && "privateKey"].filter(Boolean) }), {
        status: 500,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    // Connect to Supabase
    console.log("📍 Trace: Fetching Tokens");
    const supabase = createClient(supabaseUrl!, supabaseKey!);
    const { data: devices, error: devError } = await supabase
      .from("user_devices")
      .select("fcm_token")
      .eq("resident_id", resident_id)
      .not("fcm_token", "is", null);

    if (devError || !devices || devices.length === 0) {
      console.warn("⚠️ No tokens found");
      return new Response(JSON.stringify({ success: true, sent: 0, reason: "no_tokens" }), {
        status: 200,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    console.log("📍 Trace: Generating Access Token");
    const accessToken = await getAccessToken(clientEmail, privateKey);
    const fcmV1Url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
    
    console.log("📍 Trace: Sending to Google FCM");
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
        const err = await res.text(); // Use text() to be safe from SyntaxError
        errors.push(err);
      }
    }

    return new Response(
      JSON.stringify({ success: true, sent: successCount, total: devices.length, errors }),
      {
        headers: { 
          "Content-Type": "application/json", 
          "Access-Control-Allow-Origin": "*",
          "X-Edge-Function-Version": "v10-pk-filter"
        },
      }
    );
  } catch (err: any) {
    console.error("💥 Top-level error:", err);
    return new Response(JSON.stringify({ 
        error: String(err),
        stack: err instanceof Error ? err.stack : undefined
    }), {
      status: 500,
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  }
});
