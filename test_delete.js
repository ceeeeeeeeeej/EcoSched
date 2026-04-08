import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmcWt0cXRzamNoYm1vcGFmZ3pmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyMDgwMTIsImV4cCI6MjA4NTc4NDAxMn0.Xu7Ncwr5bWYF8x2t5h7XHw_nPrjlTSkQEdnQB4OtcNo';
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function run() {
    console.log("Adding a test area schedule...");
    const { data: insertData, error: insertError } = await supabase
        .from('area_schedules')
        .insert({
            area: 'test_area',
            schedule_name: 'Test Delete',
            days: ['monday'],
            time: '08:00:00'
        })
        .select()
        .single();
    
    if (insertError) {
        console.error("Insert failed:", insertError);
        return;
    }
    
    console.log("Inserted successfully:", insertData.id);

    console.log("Attempting to delete without authentication (how the app does it if not passing auth context explicitly)...");
    const { data: deleteData, error: deleteError } = await supabase
        .from('area_schedules')
        .delete()
        .eq('id', insertData.id)
        .select();
        
    console.log("Delete result data:", deleteData);
    console.log("Delete error:", deleteError);
}
run();
