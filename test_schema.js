const { createClient } = require('@supabase/supabase-js');
const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31';
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function checkSchema() {
    const { data, error } = await supabase.from('user_devices').select('*').limit(1);
    console.log("Devices Data:", data);
    console.log("Devices Error:", error);
}
checkSchema();
