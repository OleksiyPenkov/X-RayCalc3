/**
 * Replace PNG icon data in frm_Main.dfm ImageCollection with new icons.
 *
 * DFM format for each icon:
 *   item
 *     Name = 'Category\IconName'
 *     SourceImages = <
 *       item
 *         Image.Data = {
 *           89504E47...   (hex lines, 68 chars each, 14-space indent)
 *           ...AE426082}
 *       end>
 *   end
 */
const fs = require('fs');
const path = require('path');

const DFM_PATH = path.join(__dirname, '..', '..', '..', 'Forms', 'frm_Main.dfm');
const ICONS_BASE = path.join(__dirname, '..');

// Map DFM Name -> PNG file path (relative to ICONS_BASE)
const ICON_MAP = {
  // Project
  'Project\\01_New':            'Projects/01_New.png',
  'Project\\02_OpenProject':    'Projects/02_OpenProject.png',
  'Project\\03_Reopen':         'Projects/03_Reopen.png',
  'Project\\04_Save':           'Projects/04_Save.png',
  'Project\\05_Print':          'Projects/05_Print.png',
  'Project\\06_AddModel':       'Projects/06_AddModel.png',
  'Project\\07_Export':         'Projects/07_Export.png',
  'Project\\08_Copy':           'Projects/08_Copy.png',
  'Project\\09_Paste':          'Projects/09_Paste.png',
  'Project\\10_Edit':           'Projects/10_Edit.png',
  'Project\\11_AddExtension':   'Projects/11_AddExtension.png',
  'Project\\12_DeleteExtension':'Projects/12_DeleteExtension.png',
  // Model
  'Model\\add_layer':               'Model/add_layer.png',
  'Model\\add_period':              'Model/add_period.png',
  'Model\\add_row_32_h':            'Model/add_row_32_h.png',
  'Model\\clipboard_cut_32_h':      'Model/clipboard_cut_32_h.png',
  'Model\\clipboard_copy_lined_32': 'Model/clipboard_copy_lined_32.png',
  'Model\\clipboard_paste_lined_32':'Model/clipboard_paste_lined_32.png',
  'Model\\decrease_indent_32':      'Model/decrease_indent_32.png',
  'Model\\delete_row_32_h':         'Model/delete_row_32_h.png',
  'Model\\increase_indent_32_h':    'Model/increase_indent_32_h.png',
  // Calc
  'Calc\\40_Play':       'Calc/40_Play.png',
  'Calc\\41_Forward':    'Calc/41_Forward.png',
  'Calc\\42_AutoFit':    'Calc/42_AutoFit.png',
  'Calc\\43_DataLoad':   'Calc/43_DataLoad.png',
  'Calc\\44_DataPaste':  'Calc/44_DataPaste.png',
  'Calc\\45_ResultSave': 'Calc/45_ResultSave.png',
  'Calc\\46_CopyResult': 'Calc/46_CopyResult.png',
  'Calc\\47_CopyImage':  'Calc/47_CopyImage.png',
};

function pngToHexBlock(pngPath) {
  const buf = fs.readFileSync(pngPath);
  const hex = buf.toString('hex').toUpperCase();
  const INDENT = '              '; // 14 spaces
  const LINE_LEN = 64; // chars per line (32 bytes)
  const lines = [];
  for (let i = 0; i < hex.length; i += LINE_LEN) {
    lines.push(INDENT + hex.slice(i, i + LINE_LEN));
  }
  return lines.join('\n');
}

function main() {
  let dfm = fs.readFileSync(DFM_PATH, 'utf-8');
  // Normalize line endings to \n for processing
  dfm = dfm.replace(/\r\n/g, '\n');

  let replaced = 0;
  let errors = [];

  for (const [dfmName, pngRelPath] of Object.entries(ICON_MAP)) {
    const pngPath = path.join(ICONS_BASE, pngRelPath);
    if (!fs.existsSync(pngPath)) {
      errors.push(`  MISSING: ${pngRelPath}`);
      continue;
    }

    // Find the Name = 'dfmName' line and then the Image.Data block after it
    // Escape backslashes for regex
    const escapedName = dfmName.replace(/\\/g, '\\\\');
    const namePattern = new RegExp(`Name = '${escapedName}'`);
    const nameMatch = namePattern.exec(dfm);
    if (!nameMatch) {
      errors.push(`  NOT FOUND in DFM: ${dfmName}`);
      continue;
    }

    // Find Image.Data = { ... } after this name
    const searchStart = nameMatch.index;
    const dataStartMarker = 'Image.Data = {';
    const dataStartIdx = dfm.indexOf(dataStartMarker, searchStart);
    if (dataStartIdx === -1 || dataStartIdx - searchStart > 500) {
      errors.push(`  No Image.Data near: ${dfmName}`);
      continue;
    }

    // Find the closing }
    const hexStartIdx = dataStartIdx + dataStartMarker.length;
    const dataEndIdx = dfm.indexOf('}', hexStartIdx);
    if (dataEndIdx === -1) {
      errors.push(`  No closing } for: ${dfmName}`);
      continue;
    }

    // Replace the hex content
    const newHex = '\n' + pngToHexBlock(pngPath);
    dfm = dfm.slice(0, hexStartIdx) + newHex + dfm.slice(dataEndIdx);
    replaced++;
    console.log(`  OK: ${dfmName} <- ${pngRelPath}`);
  }

  // Restore \r\n line endings (DFM standard on Windows)
  dfm = dfm.replace(/\n/g, '\r\n');

  fs.writeFileSync(DFM_PATH, dfm, 'utf-8');
  console.log(`\nReplaced ${replaced}/${Object.keys(ICON_MAP).length} icons in frm_Main.dfm`);

  if (errors.length > 0) {
    console.log('\nErrors:');
    errors.forEach(e => console.log(e));
  }
}

main();
