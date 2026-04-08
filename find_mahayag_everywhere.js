const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmcWt0cXRzamNoYm1vcGFmZ3pmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyMDgwMTIsImV4cCI6MjA4NTc4NDAxMn0.Xu7Ncwr5bWYF8x2t5h7XHw_nPrjlTSkQEdnQB4OtcNo';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function run() {
    // Get all tables from public schema using a trick (querying an non-existent table to see error if needed, 
    // but better to just use a known list and then try to find others)
    const knownTables = [
        'users', 'registered_collectors', 'user_activities', 'user_notifications', 
        'system_settings', 'resident_feedback', 'scheduled_pickups', 
        'special_collections', 'bins', 'collection_schedules', 'area_schedules', 
        'announcements', 'reminders', 'routes'
    ];

    console.log('Searching for "Mahayag" everywhere...');

    for (const table of knownTables) {
        try {
            const { data, error } = await supabase.from(table).select('*');
            if (error) continue;

            const matches = (data || []).filter(row => {
                const rowStr = JSON.stringify(row).toLowerCase();
                return rowStr.includes('mahayag');
            });

            if (matches.length > 0) {
                console.log(`\n!!! FOUND in ${table} !!!`);
                console.log(JSON.stringify(matches, null, 2));
            }
        } catch (e) {}
    }
}

run();
