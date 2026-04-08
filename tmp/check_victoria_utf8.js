import { createClient } from '@supabase/supabase-js';
import fs from 'fs';

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

    const output = data.map(s => `ID: ${s.id} | Date: ${s.scheduled_date} | Status: ${s.status} | Name: ${s.name}`).join('\n');
    fs.writeFileSync('tmp/victoria_utf8.txt', output, 'utf8');
    console.log('Saved to tmp/victoria_utf8.txt');
}

checkSchedules();
