const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmcWt0cXRzamNoYm1vcGFmZ3pmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyMDgwMTIsImV4cCI6MjA4NTc4NDAxMn0.Xu7Ncwr5bWYF8x2t5h7XHw_nPrjlTSkQEdnQB4OtcNo';
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function forceClean() {
    console.log("Fetching exact user_devices...");
    const { data: devs } = await supabase.from('user_devices').select('*').limit(2000);
    
    const byResident = {};
    for (const d of devs) {
        if (!d.resident_id) continue;
        if (!byResident[d.resident_id]) byResident[d.resident_id] = [];
        byResident[d.resident_id].push(d);
    }
    
    let deletedCount = 0;
    for (const [resId, records] of Object.entries(byResident)) {
        if (records.length > 1) {
            console.log(`User ${resId} has ${records.length} tokens. Enforcing ONLY 1 token.`);
            // Sort by created_at ascending (oldest first)
            records.sort((a,b) => new Date(a.created_at) - new Date(b.created_at));
            
            // Delete all except the last one (newest)
            for (let i = 0; i < records.length - 1; i++) {
                const doomed = records[i];
                console.log(`  -> Deleting duplicate row: ${doomed.device_id || doomed.fcm_token}`);
                // Use a matching column to delete. If they both have the same device_id, edge case:
                // We'll delete by fcm_token or created_at.
                const { error } = await supabase.from('user_devices')
                    .delete()
                    .match({ resident_id: doomed.resident_id, created_at: doomed.created_at });
                
                if (error) console.error("  -> Error deleting:", error);
                else deletedCount++;
            }
        }
    }
    
    console.log(`Finished targeted deduplication. Deleted ${deletedCount} rows.`);
}

forceClean();
