import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';
const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31';
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function checkSchema() {
    console.log('Checking collection_schedules table...');
    const { data: cols, error: err } = await supabase.rpc('get_table_columns', { table_name: 'collection_schedules' });
    if (err) {
        console.log('RPC failed, trying query...');
        const { data, error } = await supabase.from('collection_schedules').select('*').limit(1);
        if (error) console.error('Error fetching data:', error);
        else if (data && data.length > 0) console.log('Columns found:', Object.keys(data[0]));
        else console.log('Table is empty, cannot determine columns from data.');
    } else {
        console.log('Columns:', cols);
    }
}

checkSchema();
