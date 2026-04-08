import { createClient } from '@supabase/supabase-js';
import fs from 'fs';

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmcWt0cXRzamNoYm1vcGFmZ3pmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyMDgwMTIsImV4cCI6MjA4NTc4NDAxMn0.Xu7Ncwr5bWYF8x2t5h7XHw_nPrjlTSkQEdnQB4OtcNo';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function run() {
    try {
        // Let's just try inserting a dummy notification for cristinepentin's ID to see if it works
        const { data, error } = await supabase
            .from('user_notifications')
            .select('*')
            .limit(10);
            
        console.log('Error?', error);
        console.log('Data:', data);
    } catch (e) {
        console.error('Exception:', e);
    }
}

run();
