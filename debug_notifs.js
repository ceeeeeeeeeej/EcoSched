
const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31';
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function checkData() {
    console.log('--- Checking Users table for collectors ---');
    const { data: users, error: userError } = await supabase
        .from('users')
        .select('*')
        .eq('role', 'collector');
    
    if (userError) console.error('Error fetching users:', userError);
    else console.log('Users (Collectors):', users);

    console.log('\n--- Checking Registered Collectors table ---');
    const { data: regCollectors, error: regError } = await supabase
        .from('registered_collectors')
        .select('*');
    
    if (regError) console.error('Error fetching registered_collectors:', regError);
    else console.log('Registered Collectors:', regCollectors);

    console.log('\n--- Checking Notifications table ---');
    const { data: notifications, error: notifError } = await supabase
        .from('notifications')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(10);
    
    if (notifError) console.error('Error fetching notifications:', notifError);
    else console.log('Recent Notifications:', notifications);
}

checkData();
