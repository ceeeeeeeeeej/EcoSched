import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmcWt0cXRzamNoYm1vcGFmZ3pmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyMDgwMTIsImV4cCI6MjA4NTc4NDAxMn0.Xu7Ncwr5bWYF8x2t5h7XHw_nPrjlTSkQEdnQB4OtcNo';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function diagnose() {
    console.log('--- DIAGNOSING COLLECTOR NOTIFICATIONS RAW ---');

    console.log('\n1. Users:');
    const { data: users, error: userError } = await supabase
        .from('users')
        .select('id, email, role, status');

    if (userError) console.error(userError);
    else users.forEach(u => console.log(`USER: id=${u.id}, email=${u.email}, role=[${u.role}], status=[${u.status}]`));

    if (users) {
        const collectorIds = users.filter(u => u.role.toLowerCase() === 'collector').map(u => u.id);
        
        console.log('\n2. Attempting CLEAR "New Pickup Request" for collectors:');
        const { count, error: delErr } = await supabase
            .from('user_notifications')
            .delete({ count: 'exact' })
            .ilike('title', 'New Pickup Request')
            .in('user_id', collectorIds);
        
        console.log(`Deleted ${count} notifications.`);

        console.log('\n3. Searching for "New Special Collection" for collectors:');
        const { data: schNotifs } = await supabase
            .from('user_notifications')
            .select('*')
            .in('user_id', collectorIds)
            .ilike('title', '%Special Collection%');

        if (schNotifs.length === 0) console.log('No "New Special Collection" found.');
        else schNotifs.forEach(n => console.log(`SCH_NOTIF: title=[${n.title}]`));

        console.log('\n4. IMMEDIATE CHECK for "New Pickup Request" (checking for re-insertion):');
        const { data: check } = await supabase
            .from('user_notifications')
            .select('id, title')
            .ilike('title', 'New Pickup Request')
            .in('user_id', collectorIds);
        
        if (check.length > 0) console.log('WARNING: "New Pickup Request" re-appeared immediately!');
        else console.log('Confirm: "New Pickup Request" is gone from DB for collectors.');
    }

    // 5. Query triggers on special_collections
    console.log('\n5. Triggers on public.special_collections:');
    const { data: triggers, error: trigError } = await supabase.from('pg_trigger').select('tgname').limit(10); 
    // Usually we can't query pg_trigger directly unless we have an RPC.
    
    // Let's try to update one item to 'scheduled' and see if a notification appears.
    const testItemId = '88b7d729-7eab-4720-942b-e1f2031a2f08'; // From earlier
    console.log(`\n6. TESTING TRIGGER: Updating status to 'scheduled' for item ${testItemId}`);
    
    // First, set it to something else to ensure a transition
    await supabase.from('special_collections').update({ status: 'approved' }).eq('id', testItemId);
    
    // Now set it to 'scheduled'
    const { error: updError } = await supabase.from('special_collections').update({ status: 'scheduled' }).eq('id', testItemId);
    
    if (updError) console.error('Update error:', updError);
    else console.log('Update successful. Checking user_notifications...');

    const { data: finalCheck } = await supabase
        .from('user_notifications')
        .select('*')
        .in('user_id', collectorIds)
        .ilike('title', '%Special Collection%');
    
    if (finalCheck.length > 0) console.log(`SUCCESS! Found ${finalCheck.length} scheduling notifications.`);
    else console.log('FAILURE: Still no scheduling notifications found for collectors.');
}

diagnose();
