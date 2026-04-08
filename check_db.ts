
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.7';

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31';
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function checkDatabase() {
    console.log('--- Checking user_devices ---');
    const { data: devices, error: deviceError } = await supabase
        .from('user_devices')
        .select('*');
    
    if (deviceError) console.error('Device Error:', deviceError);
    else console.log('All Devices:', devices);

    console.log('\n--- Checking latest user_notifications ---');
    const { data: notifications, error: notifError } = await supabase
        .from('user_notifications')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(10);
    
    if (notifError) console.error('Notification Error:', notifError);
    else console.log('Latest 10 Notifications:', notifications);
}

checkDatabase();
