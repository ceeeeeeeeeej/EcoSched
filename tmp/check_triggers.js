const { createClient } = require('@supabase/supabase-js');
const supabase = createClient('https://bfqktqtsjchbmopafgzf.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmcWt0cXRzamNoYm1vcGFmZ3pmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyMDgwMTIsImV4cCI6MjA4NTc4NDAxMn0.Xu7Ncwr5bWYF8x2t5h7XHw_nPrjlTSkQEdnQB4OtcNo');

(async () => {
    const { data, error } = await supabase.rpc('execute_sql', {
        sql_query: "SELECT trigger_name, event_manipulation, event_object_table FROM information_schema.triggers WHERE event_object_table = 'special_collections';"
    });

    if (error) {
        console.error('SQL Execution Error:', error);
    } else {
        console.log('Triggers found:', JSON.stringify(data, null, 2));
    }
    process.exit(0);
})();
