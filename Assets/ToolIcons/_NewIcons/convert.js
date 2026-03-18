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
};

async function convertAll() {
  const svgFiles = fs.readdirSync(SVG_DIR).filter(f => f.endsWith('.svg')).sort();
  console.log(`Found ${svgFiles.length} SVG files`);

  for (const svgFile of svgFiles) {
    const name = path.basename(svgFile, '.svg');
    const subdir = TARGET_DIRS[name] || '';
    const outDir = subdir ? path.join(PARENT_DIR, subdir) : __dirname;

    fs.mkdirSync(outDir, { recursive: true });

    const svgPath = path.join(SVG_DIR, svgFile);
    const pngPath = path.join(outDir, name + '.png');

    await sharp(svgPath)
      .resize(32, 32)
      .png()
      .toFile(pngPath);

    console.log(`  ${name}.svg -> ${subdir}/${name}.png`);
  }

  console.log(`\nDone! ${svgFiles.length} icons converted to 32x32 PNG.`);
}

convertAll().catch(err => { console.error(err); process.exit(1); });
