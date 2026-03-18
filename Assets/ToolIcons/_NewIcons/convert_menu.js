const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

const SVG_DIR = path.join(__dirname, 'SVG');
const OUT_DIR = path.join(__dirname, '..', 'Menu');

async function convertMenuIcons() {
  const svgFiles = fs.readdirSync(SVG_DIR)
    .filter(f => f.startsWith('Menu_') && f.endsWith('.svg'))
    .sort();
  console.log(`Found ${svgFiles.length} menu SVG files`);

  fs.mkdirSync(OUT_DIR, { recursive: true });

  for (const svgFile of svgFiles) {
    const name = path.basename(svgFile, '.svg');
    const pngPath = path.join(OUT_DIR, name + '.png');

    await sharp(path.join(SVG_DIR, svgFile))
      .resize(32, 32)
      .png()
      .toFile(pngPath);

    console.log(`  ${name}.svg -> Menu/${name}.png`);
  }

  console.log(`\nDone! ${svgFiles.length} menu icons converted.`);
}

convertMenuIcons().catch(err => { console.error(err); process.exit(1); });
