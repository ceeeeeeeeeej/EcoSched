import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmcWt0cXRzamNoYm1vcGFmZ3pmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyMDgwMTIsImV4cCI6MjA4NTc4NDAxMn0.Xu7Ncwr5bWYF8x2t5h7XHw_nPrjlTSkQEdnQB4OtcNo';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function cleanupStaleSchedules() {
    console.log('Cleaning up stale schedules for Victoria...');
    
    // Mark as completed for anything BEFORE today that is 'on_the_way' or 'scheduled'
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayIso = today.toISOString();

    const { data, error } = await supabase
        .from('collection_schedules')
        .update({ status: 'completed' })
        .lt('scheduled_date', todayIso)
        .or('status.eq.on_the_way,status.eq.scheduled,status.eq.Scheduled,status.eq.on-the-way'); // case-insensitive or exact matches

    if (error) {
        console.error('Error cleaning up records:', error);
        return;
    }

    console.log('Successfully cleaned up old Victoria records.');
}

cleanupStaleSchedules();
