const fs = require('fs');
const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31';

async function testPush() {
    try {
        const res = await fetch(`${SUPABASE_URL}/functions/v1/send-push`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
            },
            body: JSON.stringify({
                resident_id: "fc927778-dd7a-437f-b3f9-b0c46a4d1ec3", 
                title: 'Test Push 🚨',
                body: `This is a test to trace the Edge Function execution.`,
            }),
        });
        const text = await res.text();
        fs.writeFileSync('test_push_output.json', JSON.stringify({status: res.status, body: text}, null, 2));
    } catch(e) {
        fs.writeFileSync('test_push_output.json', JSON.stringify({error: e.message}, null, 2));
    }
}

testPush();
