
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.7";

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31';
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function checkColumns() {
    console.log('--- Checking notifications table columns ---');
    const { data: notifications, error } = await supabase
        .from('user_devices')
        .select('*')
        .limit(1);
    
    if (error) {
        console.error('Error:', error);
    } else if (notifications && notifications.length > 0) {
        console.log('Columns found:', Object.keys(notifications[0]));
    } else {
        console.log('No notifications found to check columns.');
        // Try to insert a dummy one and then delete it to see columns? No, better just check schema if possible.
        // But we can't easily check schema with anon key.
        // Let's try to select a non-existent column to see if it errors.
        const { error: err2 } = await supabase.from('notifications').select('user_id').limit(1);
        if (err2) console.log('user_id column might be missing:', err2.message);
        else console.log('user_id column exists.');
        
        const { error: err3 } = await supabase.from('notifications').select('barangay').limit(1);
        if (err3) console.log('barangay column might be missing:', err3.message);
        else console.log('barangay column exists.');
    }
}

checkColumns();
