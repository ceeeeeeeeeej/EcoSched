const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmcWt0cXRzamNoYm1vcGFmZ3pmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyMDgwMTIsImV4cCI6MjA4NTc4NDAxMn0.Xu7Ncwr5bWYF8x2t5h7XHw_nPrjlTSkQEdnQB4OtcNo';

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

async function checkSchema() {
    try {
        console.log("Fetching a bin record to check its keys...");
        const { data, error } = await supabase.from('bins').select('*').limit(1);

        if (error) {
            console.error('Error fetching bin:', error.message);
            return;
        }

        if (data && data.length > 0) {
            console.log('Success! Here are the columns available in the bins table:');
            console.log(Object.keys(data[0]));
        } else {
            console.log('No data found in bins table.');
        }

        // Now test the exact patch using anon key
        console.log("\nTesting PATCH request on ECO-VIC-24...");
        const payload = {
            fill_level: 80.47,
            gps_lat: 9.0336,
            gps_lng: 126.2094
        };
        const { error: patchError } = await supabase.from('bins').update(payload).eq('bin_id', 'ECO-VIC-24');

        if (patchError) {
             console.error('PATCH Error:', patchError);
        } else {
             console.log("✅ Node JS PATCH succeeded with this payload. (This means the Arduino JSON format might be wrong)");
        }
    } catch (e) {
        console.error(e);
    }
}

checkSchema();
