const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const supabaseAnonKey = 'sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31';

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
    data.forEach(bin => {
        console.log(`ID: ${bin.bin_id || bin.id}, Zone: ${bin.zone}, Lat: ${bin.location_lat}, Lng: ${bin.location_lng}, GPS_Lat: ${bin.gps_lat}`);
    });
}

checkBins();
