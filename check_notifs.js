const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmcWt0cXRzamNoYm1vcGFmZ3pmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyMDgwMTIsImV4cCI6MjA4NTc4NDAxMn0.Xu7Ncwr5bWYF8x2t5h7XHw_nPrjlTSkQEdnQB4OtcNo';
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function checkDoubleClicks() {
    const { data } = await supabase
        .from('user_notifications')
        .select('title, created_at, user_id')
        .order('created_at', { ascending: false })
        .limit(20);
        
    fs.writeFileSync('clean_notifs.json', JSON.stringify(data, null, 2));
}

checkDoubleClicks();
