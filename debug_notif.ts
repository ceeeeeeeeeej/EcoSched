
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.7';

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function debugNotifications() {
    const collectorId = 'd6321a99-b6d8-4d72-b5c0-1b1fcd802b30';
    console.log(`--- Debugging for Collector: ${collectorId} ---`);

    // 1. Check devices for this collector
    const { data: devices, error: deviceError } = await supabase
        .from('user_devices')
        .select('*')
        .or(`resident_id.eq.${collectorId},user_id.eq.${collectorId}`);

    console.log('Devices for collector:', devices);

    // 2. Check latest notifications for this collector
    const { data: notifications, error: notifError } = await supabase
        .from('user_notifications')
        .select('*')
        .eq('user_id', collectorId)
        .order('created_at', { ascending: false })
        .limit(5);

    console.log('Recent notifications for collector:', notifications);

    // 3. Check role to be sure
    const { data: user, error: userError } = await supabase
        .from('users')
        .select('role, barangay')
        .eq('id', collectorId)
        .single();
    
    console.log('Collector profile:', user);
}

debugNotifications();
