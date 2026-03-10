const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const supabaseKey = 'sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31';
const supabase = createClient(supabaseUrl, supabaseKey);

async function checkIds() {
    console.log("--- SPECIAL COLLECTIONS ---");
    const { data: collections, error: colError } = await supabase
        .from('special_collections')
        .select('id, resident_name, resident_id, status')
        .order('created_at', { ascending: false })
        .limit(5);

    if (colError) console.error(colError);
    else console.table(collections);

    console.log("\n--- USER DEVICES ---");
    const { data: devices, error: devError } = await supabase
        .from('user_devices')
        .select('device_id, fcm_token, barangay')
        .limit(5);

    if (devError) console.error(devError);
    else console.table(devices);
}

checkIds();
