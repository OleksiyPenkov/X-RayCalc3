const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

const SVG_DIR = path.join(__dirname, 'SVG');
const PARENT_DIR = path.dirname(__dirname);

const TARGET_DIRS = {
  '01_New': 'Projects', '02_OpenProject': 'Projects', '03_Reopen': 'Projects',
  '04_Save': 'Projects', '05_Print': 'Projects', '06_AddModel': 'Projects',
  '07_Export': 'Projects', '08_Copy': 'Projects', '09_Paste': 'Projects',
  '10_Edit': 'Projects', '11_AddExtension': 'Projects', '12_DeleteExtension': 'Projects',
  'add_layer': 'Model', 'add_period': 'Model', 'add_row_32_h': 'Model',
  'clipboard_cut_32_h': 'Model', 'clipboard_copy_lined_32': 'Model',
  'clipboard_paste_lined_32': 'Model', 'decrease_indent_32': 'Model',
  'delete_row_32_h': 'Model', 'increase_indent_32_h': 'Model',
  '40_Play': 'Calc', '41_Forward': 'Calc', '42_AutoFit': 'Calc',
  '43_DataLoad': 'Calc', '44_DataPaste': 'Calc', '45_ResultSave': 'Calc',
  '46_CopyResult': 'Calc', '47_CopyImage': 'Calc',
  'Tree_ActiveModel': 'Tree', 'Tree_LinkedData': 'Tree',
};

// Icons needing more than the default single 32 px PNG. The project tree
// markers are drawn at 16 px, and downscaling a 32 px source to 16 blurs them,
// so each size is rendered from the SVG and added to the image collection as
// its own source image - the collection then picks one without resampling.
const SIZES = {
  'Tree_ActiveModel': [16, 32],
  'Tree_LinkedData': [16, 32],
};
const DEFAULT_SIZE = 32;

// Optional icon names on the command line convert just those, e.g.
//   node convert.js Tree_ActiveModel Tree_LinkedData
// Without arguments every SVG is reconverted, which rewrites all PNGs even
// where nothing changed.
const ONLY = process.argv.slice(2);

async function convertAll() {
  let svgFiles = fs.readdirSync(SVG_DIR).filter(f => f.endsWith('.svg')).sort();
  if (ONLY.length > 0)
    svgFiles = svgFiles.filter(f => ONLY.includes(path.basename(f, '.svg')));
  console.log(`Found ${svgFiles.length} SVG files`);

  for (const svgFile of svgFiles) {
    const name = path.basename(svgFile, '.svg');
    const subdir = TARGET_DIRS[name] || '';
    const outDir = subdir ? path.join(PARENT_DIR, subdir) : __dirname;

    fs.mkdirSync(outDir, { recursive: true });

    const svgPath = path.join(SVG_DIR, svgFile);
    const sizes = SIZES[name] || [DEFAULT_SIZE];

    for (const size of sizes) {
      // A single-size icon keeps its plain name, so existing PNGs are untouched.
      const suffix = sizes.length > 1 ? `_${size}` : '';
      const pngPath = path.join(outDir, name + suffix + '.png');

      // The multi-size SVGs use a 16 unit viewBox, so raise the render density
      // to hit the wanted size exactly instead of rasterising then resampling.
      // Everything else keeps sharp's default, as its PNGs were built that way.
      const opts = SIZES[name] ? { density: 72 * size / 16 } : {};

      await sharp(svgPath, opts)
        .resize(size, size)
        .png()
        .toFile(pngPath);

      console.log(`  ${name}.svg -> ${subdir}/${name}${suffix}.png (${size}px)`);
    }
  }

  console.log(`\nDone! ${svgFiles.length} icons converted.`);
}

convertAll().catch(err => { console.error(err); process.exit(1); });
