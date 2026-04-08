import { createClient } from '@supabase/supabase-js';
import fs from 'fs';

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmcWt0cXRzamNoYm1vcGFmZ3pmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyMDgwMTIsImV4cCI6MjA4NTc4NDAxMn0.Xu7Ncwr5bWYF8x2t5h7XHw_nPrjlTSkQEdnQB4OtcNo';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function run() {
    try {
        const { data: scData } = await supabase.from('special_collections').select('*');
        const { data: adminData } = await supabase.from('users').select('*').in('role', ['admin', 'superadmin']);
        
        fs.writeFileSync('debug_output.json', JSON.stringify({
            specialCollectionsCount: scData ? scData.length : 0,
            adminsCount: adminData ? adminData.length : 0,
            admins: adminData
        }, null, 2));
        console.log('Saved to debug_output.json');
    } catch (e) {
        console.error('Exception:', e);
    }
}

run();
