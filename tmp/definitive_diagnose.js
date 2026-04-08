import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmcWt0cXRzamNoYm1vcGFmZ3pmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyMDgwMTIsImV4cCI6MjA4NTc4NDAxMn0.Xu7Ncwr5bWYF8x2t5h7XHw_nPrjlTSkQEdnQB4OtcNo';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function diagnose() {
    try {
        console.log('--- DEFINITIVE NOTIFICATION DIAGNOSTIC (V2) ---');

        // Check tables
        const tables = ['users', 'profiles', 'registered_collectors', 'user_notifications', 'special_collections'];
        for (const t of tables) {
            const { count, error } = await supabase.from(t).select('*', { count: 'exact', head: true });
            if (error) console.log(`Table [${t}]: Error - ${error.message}`);
            else console.log(`Table [${t}]: Found ${count} rows.`);
        }

        // 1. Identify Collector from whatever table works
        let collectorId = null;
        const { data: reg } = await supabase.from('registered_collectors').select('*').limit(1);
        if (reg && reg.length > 0) {
            collectorId = reg[0].user_id;
            console.log(`Found Collector ID from registered_collectors: ${collectorId} (${reg[0].email})`);
        } else {
             const { data: u } = await supabase.from('users').select('*').limit(1);
             if (u && u.length > 0) {
                 collectorId = u[0].id;
                 console.log(`Found Collector ID from users: ${collectorId}`);
             }
        }

        if (!collectorId) {
            console.log('No collector ID found. Diagnostics cannot proceed.');
            return;
        }

        // 2. Clear "New Pickup Request" for this collector
        const { count: delCount, error: delErr } = await supabase
            .from('user_notifications')
            .delete({ count: 'exact' })
            .ilike('title', '%New Pickup Request%')
            .eq('user_id', collectorId);
        
        if (delErr) console.error('Delete error:', delErr);
        else console.log(`Deleted ${delCount} "New Pickup Request" notifications for collector.`);

        // 3. Trigger Test Item
        const { data: scItems } = await supabase.from('special_collections').select('*').limit(1);
        if (scItems && scItems.length > 0) {
            const item = scItems[0];
            console.log(`\nTesting trigger on SC Item: ${item.id} (Status: ${item.status})`);
            
            // Set to approved first
            await supabase.from('special_collections').update({ status: 'approved' }).eq('id', item.id);
            // Set to scheduled
            await supabase.from('special_collections').update({ 
                status: 'scheduled', 
                scheduled_date: new Date().toISOString() 
            }).eq('id', item.id);
            
            console.log('Update sequence complete. Waiting for trigger...');
            await new Promise(r => setTimeout(r, 2000));

            const { data: notifs } = await supabase
                .from('user_notifications')
                .select('*')
                .eq('user_id', collectorId)
                .order('created_at', { ascending: false })
                .limit(5);

            if (notifs && notifs.length > 0) {
                console.log('Recent Notifications for collector:');
                notifs.forEach(n => console.log(` - [${n.title}]: ${n.message}`));
            } else {
                console.log('No recent notifications found for collector.');
            }
        }

    } catch (err) {
        console.error('DIAGNOSTIC FAILED:', err);
    }
}

diagnose();
