
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.7";

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31';
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function checkUsers() {
    console.log('--- Checking users with role=collector ---');
    const { data, error } = await supabase
        .from('users')
        .select('id, email, role, status');
    
    if (error) {
        console.error('Error:', error);
    } else {
        console.log('All Users:', data);
        const collectors = data.filter(u => u.role === 'collector');
        console.log('Collectors:', collectors);
    }
}

checkUsers();
