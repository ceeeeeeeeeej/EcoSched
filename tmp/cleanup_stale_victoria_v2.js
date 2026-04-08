import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmcWt0cXRzamNoYm1vcGFmZ3pmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyMDgwMTIsImV4cCI6MjA4NTc4NDAxMn0.Xu7Ncwr5bWYF8x2t5h7XHw_nPrjlTSkQEdnQB4OtcNo';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function cleanupStaleSchedules() {
    console.log('Fetching stale Victoria schedules...');
    
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayIso = today.toISOString();

    // First, find them to be sure
    const { data: toUpdate, error: fetchError } = await supabase
        .from('collection_schedules')
        .select('id, zone, status, scheduled_date')
        .lt('scheduled_date', todayIso)
        .neq('status', 'completed');

    if (fetchError) {
        console.error('Error fetching records:', fetchError);
        return;
    }

    console.log(`Found ${toUpdate?.length || 0} stale records to clean up.`);

    if (toUpdate && toUpdate.length > 0) {
        const ids = toUpdate.map(r => r.id);
        const { error: updateError } = await supabase
            .from('collection_schedules')
            .update({ status: 'completed' })
            .in('id', ids);

        if (updateError) {
            console.error('Error updating records:', updateError);
        } else {
            console.log(`Successfully marked ${ids.length} records as completed.`);
        }
    }
}

cleanupStaleSchedules();
