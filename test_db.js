const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31';
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function checkTokens() {
    console.log("Reading...");
    const { data: users, error: err1 } = await supabase.from('users').select('*').eq('role', 'collector').limit(5);
    const { data: devices, error: err2 } = await supabase.from('user_devices').select('*').limit(20);
    const { data: bins, error: err3 } = await supabase.from('bins').select('*').limit(20);
    
    fs.writeFileSync('test_output.json', JSON.stringify({users, devices, bins, err1, err2, err3}, null, 2));
    console.log("Done.");
}
checkTokens();
