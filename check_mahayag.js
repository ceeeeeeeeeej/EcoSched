import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmcWt0cXRzamNoYm1vcGFmZ3pmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyMDgwMTIsImV4cCI6MjA4NTc4NDAxMn0.Xu7Ncwr5bWYF8x2t5h7XHw_nPrjlTSkQEdnQB4OtcNo';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function checkTables() {
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

    console.log('--- Table Status Check ---');
    for (const table of tables) {
        const { data, count, error } = await supabase
            .from(table)
            .select('*', { count: 'exact', head: true });
        
        if (error) {
            console.log(`Table ${table.padEnd(25)}: ERROR - ${error.message}`);
        } else {
            console.log(`Table ${table.padEnd(25)}: ${count} rows`);
        }
    }
    
    console.log('\n--- Checking for "Mahayag" in all tables ---');
    for (const table of tables) {
        // We can't search all columns easily, but we can try common ones
        const { data, error } = await supabase
            .from(table)
            .select('*')
            .or('area.ilike.%Mahayag%,address.ilike.%Mahayag%,name.ilike.%Mahayag%,description.ilike.%Mahayag%')
            .limit(5);
        
        if (!error && data && data.length > 0) {
            console.log(`FOUND in ${table}:`, JSON.stringify(data, null, 2));
        }
    }
}

checkTables();
