// PROTOTYPE - NOT FOR PRODUCTION
// Bundles the game into a single self-contained HTML file: dist/LootCity.html
import * as esbuild from 'esbuild';
import fs from 'fs';
const r = await esbuild.build({ entryPoints: ['src/main.js'], bundle: true, minify: true, format: 'iife', write: false, target: 'es2020', legalComments: 'none' });
const js = r.outputFiles[0].text.replace(/<\/script>/g, '<\\/script>');
let html = fs.readFileSync('index.html', 'utf8');
html = html.replace('<script type="module" src="./src/main.js"></script>', () => `<script>${js}</script>`);
fs.mkdirSync('dist', { recursive: true });
fs.writeFileSync('dist/LootCity.html', html);
console.log('dist/LootCity.html', (html.length / 1024).toFixed(0), 'KB');
