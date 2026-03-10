const fs = require('fs');
const https = require('https');
const path = require('path');

const PROJECT_REF = 'bfqktqtsjchbmopafgzf';
const FUNCTION_SLUG = 'send-push-v2';
const FILE_PATH = path.join(__dirname, 'supabase', 'functions', 'send-push', 'test.ts');

const TOKEN = process.argv[2];

if (!TOKEN) {
    console.error('Usage: node deploy_manual.js <SUPABASE_PERSONAL_ACCESS_TOKEN>');
    process.exit(1);
}

const content = fs.readFileSync(FILE_PATH, 'utf8');
const base64Content = Buffer.from(content).toString('base64');

const deploy = async () => {
    console.log(`Updating test function "${FUNCTION_SLUG}" with ZERO dependencies...`);
    
    const body = {
        name: FUNCTION_SLUG,
        slug: FUNCTION_SLUG,
        body: base64Content,
        verify_jwt: false
    };

    const result = await makeRequest('PATCH', `/functions/${FUNCTION_SLUG}`, body);
    if (result) {
        console.log('✅ Update successful!');
        console.log('Response:', JSON.stringify(result, null, 2));
    } else {
        console.error('❌ Update failed.');
    }
};

function makeRequest(method, endpoint, body = null) {
    return new Promise((resolve) => {
        const options = {
            hostname: 'api.supabase.com',
            port: 443,
            path: `/v1/projects/${PROJECT_REF}${endpoint}`,
            method: method,
            headers: {
                'Authorization': `Bearer ${TOKEN}`,
                'Content-Type': 'application/json'
            }
        };

        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => {
                let json;
                try {
                    json = JSON.parse(data);
                } catch (e) {
                    json = data;
                }

                if (res.statusCode >= 200 && res.statusCode < 300) {
                    resolve(json);
                } else {
                    console.error(`Request failed with status ${res.statusCode}:`, data);
                    resolve(null);
                }
            });
        });

        req.on('error', (e) => {
            console.error('Request error:', e.message);
            resolve(null);
        });

        if (body) {
            req.write(JSON.stringify(body));
        }
        req.end();
    });
}

deploy();
