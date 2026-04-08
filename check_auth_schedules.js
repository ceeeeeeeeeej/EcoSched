import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmcWt0cXRzamNoYm1vcGFmZ3pmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyMDgwMTIsImV4cCI6MjA4NTc4NDAxMn0.Xu7Ncwr5bWYF8x2t5h7XHw_nPrjlTSkQEdnQB4OtcNo';
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function run() {
    // Sign in as admin
    const { data: signInData, error: signInErr } = await supabase.auth.signInWithPassword({
        email: 'cristine@gmail.com',
        password: 'admin123'
    });
    
    if (signInErr) {
        console.error("Login failed:", signInErr);
        // Try without login too
    } else {
        console.log("Logged in as:", signInData?.user?.email);
    }

    console.log("\nFetching area_schedules (with auth)...");
    const { data, error } = await supabase.from('area_schedules').select('*');
    if (error) {
        console.error("Error:", error);
    } else {
        console.log(`Found ${data.length} area_schedules:`);
        console.log(JSON.stringify(data, null, 2));
    }
}
run();
