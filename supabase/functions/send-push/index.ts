// Supabase Edge Function: send-push
// Sends FCM push notification to a specific device token
// Environment variable required: FCM_SERVER_KEY

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.7';

const FCM_URL = 'https://fcm.googleapis.com/fcm/send';

console.log("🚀 Edge Function 'send-push' loaded");

Deno.serve(async (req: Request) => {
    // Handle CORS preflight
    if (req.method === 'OPTIONS') {
        return new Response(null, {
            status: 204,
            headers: {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'POST, OPTIONS',
                'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
                'Access-Control-Max-Age': '86400',
            },
        });
    }

    try {
        console.log("📥 Incoming request:", req.method);
        const bodyText = await req.text();
        console.log("📦 Request body:", bodyText);

        let body;
        try {
            body = JSON.parse(bodyText);
        } catch (e) {
            return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
                status: 400,
                headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
            });
        }

        const { resident_id, title, notification_body } = body;
        const msgBody = notification_body || body.body; // handle 'body' field

        if (!resident_id || !title || !msgBody) {
            return new Response(JSON.stringify({ error: 'Missing required fields: resident_id, title, body' }), {
                status: 400,
                headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
            });
        }

        const supabaseUrl = Deno.env.get('SUPABASE_URL');
        const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
        const fcmKey = Deno.env.get('FCM_SERVER_KEY');

        if (!fcmKey) {
            console.error("❌ FCM_SERVER_KEY missing");
            return new Response(JSON.stringify({ error: 'FCM_SERVER_KEY not configured' }), {
                status: 500,
                headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
            });
        }

        if (!supabaseUrl || !supabaseKey) {
            console.error("❌ Supabase environment variables missing");
            return new Response(JSON.stringify({ error: 'Supabase configuration missing' }), {
                status: 500,
                headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
            });
        }

        // Look up FCM token for the resident from user_devices table
        console.log("🔍 Fetching tokens for resident:", resident_id);
        const supabase = createClient(supabaseUrl, supabaseKey);
        const { data: devices, error: devError } = await supabase
            .from('user_devices')
            .select('fcm_token')
            .eq('resident_id', resident_id)
            .not('fcm_token', 'is', null)
            .order('created_at', { ascending: false })
            .limit(5);

        if (devError) {
            console.error('❌ Error fetching device tokens:', devError);
            return new Response(JSON.stringify({ error: devError.message }), {
                status: 500,
                headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
            });
        }

        if (!devices || devices.length === 0) {
            console.warn('⚠️ No FCM tokens found for resident:', resident_id);
            return new Response(JSON.stringify({ success: true, sent: 0, reason: 'no_tokens' }), {
                status: 200,
                headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
            });
        }

        const tokens: string[] = devices.map((d: { fcm_token: string }) => d.fcm_token).filter(Boolean);
        console.log(`✅ Found ${tokens.length} tokens. Sending to FCM...`);

        // Send FCM notification using legacy HTTP API
        const fcmPayload = {
            registration_ids: tokens,
            notification: {
                title,
                body: msgBody,
                sound: 'default',
                android_channel_id: 'ecosched_alerts',
            },
            data: {
                type: 'approval',
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            priority: 'high',
        };

        const fcmResponse = await fetch(FCM_URL, {
            method: 'POST',
            headers: {
                'Authorization': `key=${fcmKey}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(fcmPayload),
        });

        const fcmResult = await fcmResponse.json();
        console.log('✅ FCM response:', JSON.stringify(fcmResult));

        return new Response(
            JSON.stringify({ success: true, sent: tokens.length, fcm: fcmResult }),
            {
                status: 200,
                headers: { 
                    'Content-Type': 'application/json', 
                    'Access-Control-Allow-Origin': '*',
                    'X-Edge-Function-Version': 'v3-hardened'
                },
            }
        );
    } catch (err) {
        console.error('💥 send-push error:', err);
        return new Response(JSON.stringify({ error: String(err) }), {
            status: 500,
            headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
        });
    }
});
