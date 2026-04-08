const fs = require('fs');
let content;
try {
  content = fs.readFileSync('analyze.json', 'utf16le');
} catch (e) {
  content = fs.readFileSync('analyze.json', 'utf8');
}
try {
  const data = JSON.parse(content);
  const errors = data.diagnostics.filter(d => d.severity === 'ERROR');
  for (const err of errors) {
    console.log(`${err.location.file}:${err.location.range.start.line} - ${err.problemMessage}`);
  }
} catch (e) {
  console.error("Parse error:", e);
}
