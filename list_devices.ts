
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.7";

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31';
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function listAllDevices() {
    console.log('--- Listing all user_devices with user info ---');
    const { data: devices, error: devError } = await supabase
        .from('user_devices')
        .select('*');
    
    if (devError) return console.error('Device Error:', devError);
    
    for (const dev of devices) {
        const { data: user, error: userError } = await supabase
            .from('users')
            .select('email, role')
            .eq('id', dev.resident_id)
            .maybeSingle();
        
        console.log(`Device ID: ${dev.device_id} | User: ${dev.resident_id} | Email: ${user?.email ?? 'N/A'} | Role: ${user?.role ?? 'N/A'}`);
    }
}

listAllDevices();
