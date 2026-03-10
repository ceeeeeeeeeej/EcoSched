const https = require('https');

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_KEY = 'sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31';
const BIN_ID = 'BIN-1189';

const url = `${SUPABASE_URL}/rest/v1/bins?bin_id=eq.${BIN_ID}&select=*`;

console.log(`Checking for bin ${BIN_ID} at ${url}...`);

const options = {
    headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`
    }
};

https.get(url, options, (res) => {
    let data = '';

    res.on('data', (chunk) => {
        data += chunk;
    });

    res.on('end', () => {
        try {
            if (res.statusCode >= 200 && res.statusCode < 300) {
                const bins = JSON.parse(data);
                if (Array.isArray(bins) && bins.length > 0) {
                    console.log('✅ SUCCESS: Bin found!');
                    console.log(bins[0]);
                } else {
                    console.error('❌ FAILURE: Bin not found in database.');
                    console.log('Response:', data);
                }
            } else {
                console.error(`❌ FAILURE: HTTP ${res.statusCode}`);
                console.log('Response:', data);
            }
        } catch (e) {
            console.error('❌ ERROR: Could not parse response.');
            console.error(e);
            console.log('Raw data:', data);
        }
    });

}).on('error', (e) => {
    console.error('❌ ERROR: Request failed.');
    console.error(e);
});
