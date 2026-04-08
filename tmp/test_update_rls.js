import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmcWt0cXRzamNoYm1vcGFmZ3pmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyMDgwMTIsImV4cCI6MjA4NTc4NDAxMn0.Xu7Ncwr5bWYF8x2t5h7XHw_nPrjlTSkQEdnQB4OtcNo';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function testUpdate() {
    const id = 'e5113fca-b077-431d-afc8-bd509a960619'; // One of the stale ones
    console.log(`Checking record ${id}...`);
    
    const { data: before } = await supabase.from('collection_schedules').select('status').eq('id', id).single();
    console.log('Status before:', before?.status);

    console.log('Attempting update...');
    const { data, error, count } = await supabase
        .from('collection_schedules')
        .update({ status: 'completed' })
        .eq('id', id)
        .select();

    if (error) {
        console.error('Update error:', error);
    } else {
        console.log('Update success! New status:', data?.[0]?.status);
        console.log('Rows affected:', data?.length);
    }
}

testUpdate();
