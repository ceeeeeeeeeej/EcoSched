
// Import Supabase client (using fetch polyfill for node)
const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_KEY = 'sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31';

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

async function testConnection() {
    console.log('Testing connection to Supabase...');
    console.log('URL:', SUPABASE_URL);

    // 1. Try to read from 'bins'
    console.log('\n--- Attempting to SELECT * from bins ---');
    const { data, error } = await supabase.from('bins').select('*');

    if (error) {
        console.error('❌ ERROR Reading bins:');
        console.error(error);
        if (error.code === '42501') {
            console.error('🚨 DIAGNOSIS: RLS POLICY VIOLATION (Permission Denied)');
            console.error('You need to add a policy allowing SELECT for "anon" and "authenticated" roles.');
        } else if (error.code === 'PGRST204') {
            console.error('🚨 DIAGNOSIS: Table "bins" does not exist?'); // Unlikely for this code
        }
    } else {
        console.log(`✅ SUCCESS: Retrieved ${data.length} records.`);
        if (data.length === 0) {
            console.warn('⚠️ WARNING: The table is accessible but EMPTY.');
            console.warn('The Arduino may be updating a record that does not exist, or RLS is hiding rows.');
        } else {
            console.log('Data sample:', data[0]);
        }
    }
}

testConnection();
