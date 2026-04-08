const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmcWt0cXRzamNoYm1vcGFmZ3pmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyMDgwMTIsImV4cCI6MjA4NTc4NDAxMn0.Xu7Ncwr5bWYF8x2t5h7XHw_nPrjlTSkQEdnQB4OtcNo';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

const tables = [
    'users',
    'registered_collectors',
    'user_activities',
    'user_notifications',
    'system_settings',
    'resident_feedback',
    'scheduled_pickups',
    'special_collections',
    'bins',
    'collection_schedules',
    'area_schedules',
    'announcements',
    'reminders'
];

async function run() {
    console.log('--- TABLE ROW COUNTS ---');
    for (const table of tables) {
        const { count, error } = await supabase
            .from(table)
            .select('*', { count: 'exact', head: true });
        
        if (error) {
            console.log(`${table.padEnd(25)}: ERROR - ${error.message}`);
        } else {
            console.log(`${table.padEnd(25)}: ${count} rows`);
        }
    }

    console.log('\n--- SEARCHING FOR MAHAYAG ---');
    for (const table of tables) {
        // Try searching by 'area' if it exists, then fallback to 'address' or 'description'
        const { data, error } = await supabase
            .from(table)
            .select('*')
            .limit(10);
        
        if (!error && data) {
            const matches = data.filter(row => {
                const str = JSON.stringify(row).toLowerCase();
                return str.includes('mahayag');
            });
            
            if (matches.length > 0) {
                console.log(`FOUND ${matches.length} matches in ${table}:`);
                console.log(JSON.stringify(matches, null, 2));
            }
        }
    }
}

run();
