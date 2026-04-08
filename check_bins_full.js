const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmcWt0cXRzamNoYm1vcGFmZ3pmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyMDgwMTIsImV4cCI6MjA4NTc4NDAxMn0.Xu7Ncwr5bWYF8x2t5h7XHw_nPrjlTSkQEdnQB4OtcNo';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function checkBins() {
    console.log('--- Checking Bins Table ---');
    const { data, error } = await supabase
        .from('bins')
        .select('*');

    if (error) {
        console.error('Error fetching bins:', error);
        return;
    }

    console.log(`Found ${data.length} bins:`);
    console.log(JSON.stringify(data, null, 2));
}

checkBins();
