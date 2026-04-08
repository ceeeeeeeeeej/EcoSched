
const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_KEY = 'sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31';

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

async function cleanup() {
    const tables = ['collection_schedules', 'user_notifications', 'resident_feedback'];
    
    for (const table of tables) {
        console.log(`🧹 Cleaning table: ${table}...`);
        
        // Fetch all to filter locally (since we can't do complex ILIKE easily with anon key on all columns)
        const { data, error } = await supabase.from(table).select('*');
        if (error) {
            console.error(`Error fetching ${table}:`, error);
            continue;
        }

        const toDelete = (data || []).filter(row => {
            const str = JSON.stringify(row).toLowerCase();
            return str.includes('mahayag') || str.includes('visitor');
        }).map(r => r.id);

        if (toDelete.length > 0) {
            console.log(`🗑️ Deleting ${toDelete.length} records from ${table}...`);
            // Delete in chunks of 50 to avoid URL length issues or other limits
            for (let i = 0; i < toDelete.length; i += 50) {
                const chunk = toDelete.slice(i, i + 50);
                const { error: delError } = await supabase.from(table).delete().in('id', chunk);
                if (delError) {
                    console.error(`Error deleting from ${table}:`, delError);
                }
            }
        } else {
            console.log(`✅ No matches found in ${table}.`);
        }
    }
    console.log('✨ Cleanup complete.');
}

cleanup();
