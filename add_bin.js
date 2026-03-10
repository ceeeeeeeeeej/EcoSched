const https = require('https');

const data = JSON.stringify({
    bin_id: 'BIN-1189',
    address: 'Near Main Gate',
    fill_level: 0,
    status: 'active',
    latitude: 9.0104,
    longitude: 126.148
});

const options = {
    hostname: 'bfqktqtsjchbmopafgzf.supabase.co',
    path: '/rest/v1/bins',
    method: 'POST',
    headers: {
        'apikey': 'sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31',
        'Authorization': 'Bearer sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31',
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal'
    }
};

const req = https.request(options, res => {
    console.log('Status:', res.statusCode);
});

req.on('error', e => {
    console.error('Error:', e);
});

req.write(data);
req.end();
