const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmcWt0cXRzamNoYm1vcGFmZ3pmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyMDgwMTIsImV4cCI6MjA4NTc4NDAxMn0.Xu7Ncwr5bWYF8x2t5h7XHw_nPrjlTSkQEdnQB4OtcNo';
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function checkDuplicates() {
    console.log("Checking user_devices for duplicates...");
    const { data: devices, error } = await supabase.from('user_devices').select('*');
    if (error) {
        console.error("Error fetching devices:", error);
        return;
    }

    const map = {};
    for (const d of devices) {
        if (!d.resident_id) continue;
        if (!map[d.resident_id]) map[d.resident_id] = [];
        map[d.resident_id].push(d);
    }

    let hasDuplicates = false;
    for (const [resident_id, records] of Object.entries(map)) {
        if (records.length > 1) {
            hasDuplicates = true;
            console.log(`\nResident ID: ${resident_id} has ${records.length} registered devices:`);
            records.forEach(r => {
                console.log(`  - device_id: ${r.device_id}, fcm_token: ${r.fcm_token?.substring(0, 15)}...`);
            });
            
            // Auto delete older ones
            console.log("Attempting to delete older duplicates...");
            records.sort((a,b) => new Date(a.created_at) - new Date(b.created_at));
            const toKeep = records[records.length - 1];
            for (let i = 0; i < records.length - 1; i++) {
                console.log(`Deleting ${records[i].device_id}...`);
                await supabase.from('user_devices').delete().eq('device_id', records[i].device_id);
            }
            console.log(`Kept only ${toKeep.device_id}`);
        }
    }

    if (!hasDuplicates) {
        console.log("SUCCESS: No duplicate resident IDs found in user_devices.");
    }
}

checkDuplicates();
