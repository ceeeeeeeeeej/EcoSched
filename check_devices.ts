
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.7";

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31';
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function checkDevices() {
    console.log('--- Checking user_devices ---');
    // Using a select that might bypass RLS if it's open, or at least show column error if missing.
    const { data, error } = await supabase
        .from('user_devices')
        .select('*');
    
    if (error) {
        console.error('Error:', error);
    } else {
        console.log('Devices Data:', data);
    }
}

checkDevices();
