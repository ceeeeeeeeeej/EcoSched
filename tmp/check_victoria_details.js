import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmcWt0cXRzamNoYm1vcGFmZ3pmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyMDgwMTIsImV4cCI6MjA4NTc4NDAxMn0.Xu7Ncwr5bWYF8x2t5h7XHw_nPrjlTSkQEdnQB4OtcNo';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function checkSchedules() {
    const { data, error } = await supabase
        .from('collection_schedules')
        .select('*')
        .or('zone.ilike.%victoria%,zone.ilike.%vict%')
        .order('scheduled_date', { ascending: false });

    if (error) {
        console.error('Error fetching schedules:', error);
        return;
    }

    console.log(JSON.stringify(data.map(s => ({
        id: s.id,
        zone: s.zone,
        date: s.scheduled_date,
        status: s.status,
        name: s.name,
        desc: s.description
    })), null, 2));
}

checkSchedules();
