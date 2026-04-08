
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.7';

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31';
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function checkLatest() {
    console.log('--- Checking Latest Notification ---');
    const { data: notifs, error: notifError } = await supabase
        .from('user_notifications')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(1);
    
    if (notifError) console.error('Notif Error:', notifError);
    else console.log('Latest Notification:', JSON.stringify(notifs[0], null, 2));

    const collectorId = 'd6321a99-b6d8-4d72-b5c0-1b1fcd802b30';
    console.log(`\n--- Checking Devices for Collector: ${collectorId} ---`);
    const { data: devices, error: deviceError } = await supabase
        .from('user_devices')
        .select('*')
        .eq('resident_id', collectorId);
    
    if (deviceError) console.error('Device Error:', deviceError);
    else console.log('Collector Devices:', devices);
}

checkLatest();
