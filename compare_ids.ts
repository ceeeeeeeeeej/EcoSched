
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.7";

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31';
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function compareIds() {
    console.log('--- USERS (Role: collector) ---');
    const { data: users } = await supabase.from('users').select('id, email').eq('role', 'collector');
    console.log(users);

    console.log('\n--- ALL USER_DEVICES ---');
    const { data: devices } = await supabase.from('user_devices').select('resident_id, device_id');
    console.log(devices);
    
    if (users && devices) {
        const userIds = new Set(users.map(u => u.id));
        const deviceUserIds = new Set(devices.map(d => d.resident_id));
        
        console.log('\n--- Intersection ---');
        users.forEach(u => {
            if (deviceUserIds.has(u.id)) {
                console.log(`MATCH found for ${u.email} (${u.id})`);
            } else {
                console.log(`NO DEVICE found for ${u.email} (${u.id})`);
            }
        });
    }
}

compareIds();
