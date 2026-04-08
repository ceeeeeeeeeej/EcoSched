
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.7";

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31';
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function checkCollectorDevices() {
    console.log('--- Checking collectors and their devices ---');
    const { data: users, error: userError } = await supabase
        .from('users')
        .select('id, email, role')
        .eq('role', 'collector');
    
    if (userError) return console.error('User Error:', userError);
    
    console.log('Collectors found:', users.length);
    
    for (const user of users) {
        const { data: devices, error: devError } = await supabase
            .from('user_devices')
            .select('*')
            .eq('resident_id', user.id);
        
        if (devError) console.error(`Device Error for ${user.email}:`, devError);
        else console.log(`Devices for ${user.email} (${user.id}):`, devices);
    }
}

checkCollectorDevices();
