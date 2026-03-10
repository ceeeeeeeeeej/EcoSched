const https = require('https');

const SUPABASE_URL = 'https://bfqktqtsjchbmopafgzf.supabase.co';
const SUPABASE_KEY = 'sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31';

// Select all bins, limit 5
const url = `${SUPABASE_URL}/rest/v1/bins?select=*&limit=5`;

console.log(`Listing bins from ${url}...`);

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
            console.log(`Status Code: ${res.statusCode}`);
            if (res.statusCode >= 200 && res.statusCode < 300) {
                const bins = JSON.parse(data);
                console.log(`Found ${bins.length} bins:`);
                console.log(JSON.stringify(bins, null, 2));
            } else {
                console.log('Error:', data);
            }
        } catch (e) {
            console.error(e);
            console.log('Raw:', data);
        }
    });

}).on('error', (e) => {
    console.error(e);
});
