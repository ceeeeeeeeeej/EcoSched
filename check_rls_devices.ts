
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.7';

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31';
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function checkRLS() {
    console.log('--- Checking RLS Policies for user_devices ---');
    const { data, error } = await supabase.rpc('get_policies_for_table', { table_name: 'user_devices' });
    
    if (error) {
        // Fallback to direct query if RPC doesn't exist
        const { data: policies, error: pgError } = await supabase
            .from('pg_policies')
            .select('*')
            .eq('tablename', 'user_devices');
            
        if (pgError) console.error('Error fetching policies:', pgError);
        else console.log('Policies found:', policies);
    } else {
        console.log('Policies found:', data);
    }
}

checkRLS();
