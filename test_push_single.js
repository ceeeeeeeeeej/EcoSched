const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmcWt0cXRzamNoYm1vcGFmZ3pmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyMDgwMTIsImV4cCI6MjA4NTc4NDAxMn0.Xu7Ncwr5bWYF8x2t5h7XHw_nPrjlTSkQEdnQB4OtcNo';
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function testPush() {
    console.log("Invoking send-push-v2 EXACTLY ONCE...");
    
    // Fetch a resident_id from user_devices to test on
    const { data: devs } = await supabase.from('user_devices').select('resident_id').not('resident_id', 'is', null).limit(1);
    if (!devs || devs.length === 0) { console.log("No devices found."); return; }
    
    const targetUserId = devs[0].resident_id;
    console.log(`Targeting user: ${targetUserId}`);

    const { data, error } = await supabase.functions.invoke('send-push-v2', {
        body: {
            resident_id: targetUserId,
            title: 'TEST PUSH | EXPERIMENT 🛠️',
            body: `This is a test. If you see this TWICE, the Edge Function is broken. If ONCE, the Admin UI is broken.`,
        }
    });

    if (error) console.error("Error calling edge function:", error);
    else console.log("Response:", data);
}

testPush();
