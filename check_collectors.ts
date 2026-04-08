
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.7";

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31';
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function checkCollectors() {
    console.log('--- Checking registered_collectors ---');
    const { data, error } = await supabase
        .from('registered_collectors')
        .select('*');
    
    if (error) {
        console.error('Error:', error);
    } else {
        console.log('Data found:', data);
    }
}

checkCollectors();
