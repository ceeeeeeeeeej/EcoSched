const https = require('https');

const options = {
    hostname: 'bfqktqtsjchbmopafgzf.supabase.co',
    path: '/rest/v1/bins?select=*',
    method: 'GET',
    headers: {
        'apikey': 'sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31',
        'Authorization': 'Bearer sb_publishable_ucEKoeLHhbxBVtzDABvVIg_eKIhIQ31'
    }
};

https.get(options, res => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => console.log(JSON.parse(data)));
});
