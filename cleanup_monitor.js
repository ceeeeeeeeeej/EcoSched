
const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_KEY = 'sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31';
const TARGET_BIN = 'BIN-1189';

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

async function main() {
    console.log('🔄 Connecting to Supabase...');

    // 1. DELETE DUMMY SENSORS
    console.log(`\n🗑️ Removing sensors that are NOT ${TARGET_BIN}...`);
    const { error: deleteError } = await supabase
        .from('bins')
        .delete()
        .neq('bin_id', TARGET_BIN); // Delete everything NOT equal to target

    if (deleteError) {
        console.error('❌ Error deleting dummy sensors:', deleteError.message);
        console.log('  (You might need to enable DELETE policy for RLS in Supabase Dashboard)');
    } else {
        console.log('✅ Dummy sensors removed.');
    }

    // 2. MONITOR REAL SENSOR
    console.log(`\n📡 Monitoring ${TARGET_BIN} for updates...`);
    console.log('   (Press Ctrl+C to stop)');

    setInterval(async () => {
        const { data, error } = await supabase
            .from('bins')
            .select('*')
            .eq('bin_id', TARGET_BIN)
            .single();

        if (error) {
            console.error('❌ Error reading bin:', error.message);
        } else if (data) {
            const lastUpdate = new Date(data.updated_at);
            const now = new Date();
            const diffSeconds = Math.round((now - lastUpdate) / 1000);

            let status = '🔴 OFFLINE';
            if (diffSeconds < 60) status = '🟢 ONLINE (Active)';
            else if (diffSeconds < 300) status = '🟡 IDLE';

            console.log(`[${now.toLocaleTimeString()}] Status: ${status} | Fill: ${data.fill_level}% | Last Update: ${diffSeconds}s ago`);
        } else {
            console.log(`⚠️ Bin ${TARGET_BIN} not found.`);
        }
    }, 3000); // Check every 3 seconds
}

main();
