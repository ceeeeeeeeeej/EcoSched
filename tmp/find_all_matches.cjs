
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_KEY = 'sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31';

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

async function findMatches() {
    const tables = ['collection_schedules', 'area_schedules', 'user_notifications', 'resident_feedback', 'users'];
    const results = {};

    for (const table of tables) {
        console.log(`Checking table: ${table}...`);
        const { data, error } = await supabase.from(table).select('*');
        if (error) {
            console.error(`Error checking ${table}:`, error);
            continue;
        }

        const matches = (data || []).filter(row => {
            const str = JSON.stringify(row).toLowerCase();
            return str.includes('mahayag') || str.includes('visitor');
        });

        if (matches.length > 0) {
            results[table] = matches.map(m => ({
                id: m.id,
                summary: m.name || m.area || m.zone || m.title || m.message || m.comments || 'No summary'
            }));
        }
    }

    fs.writeFileSync('tmp/db_matches.json', JSON.stringify(results, null, 2));
    console.log('✅ Matches saved to tmp/db_matches.json');
}

findMatches();
