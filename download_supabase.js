const https = require('https');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const url = 'https://github.com/supabase/cli/releases/download/v1.200.0/supabase_windows_amd64.zip';
const zipPath = path.join(__dirname, 'supabase.zip');
const extractPath = path.join(__dirname, 'supabase_cli');

console.log('Downloading Supabase CLI...');

const file = fs.createWriteStream(zipPath);

https.get(url, (response) => {
  if (response.statusCode === 301 || response.statusCode === 302) {
    https.get(response.headers.location, (res) => {
      res.pipe(file);
      file.on('finish', () => {
        file.close(() => {
          console.log('Downloaded successfully. Extracting...');
          try {
             // using powershell to extract since unzipping in pure node requires external deps
             execSync(`powershell -Command "Expand-Archive -Path '${zipPath}' -DestinationPath '${extractPath}' -Force"`);
             console.log('Extracted successfully. You can now use .\\supabase_cli\\supabase.exe');
          } catch(e) {
             console.error('Failed to extract', e.message);
          }
        });
      });
    }).on('error', (err) => {
      fs.unlink(zipPath, () => {});
      console.error('Download error:', err.message);
    });
  }
}).on('error', (err) => {
  fs.unlink(zipPath, () => {});
  console.error('Download error:', err.message);
});
