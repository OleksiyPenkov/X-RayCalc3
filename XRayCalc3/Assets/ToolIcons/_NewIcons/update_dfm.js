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
  'Model\\layer_add':                'Model/layer_add.png',
  'Model\\layer_insert':             'Model/layer_insert.png',
  'Model\\layer_delete':             'Model/layer_delete.png',
  'Model\\layer_up':                 'Model/layer_up.png',
  'Model\\layer_down':               'Model/layer_down.png',
  'Model\\stack_add':                'Model/stack_add.png',
  'Model\\stack_insert':             'Model/stack_insert.png',
  'Model\\stack_delete':             'Model/stack_delete.png',
  'Model\\clipboard_cut_32_h':       'Model/clipboard_cut_32_h.png',
  'Model\\clipboard_copy_lined_32':  'Model/clipboard_copy_lined_32.png',
  'Model\\clipboard_paste_lined_32': 'Model/clipboard_paste_lined_32.png',
  // Calc
  'Calc\\40_Play':       'Calc/40_Play.png',
  'Calc\\41_Forward':    'Calc/41_Forward.png',
  'Calc\\42_AutoFit':    'Calc/42_AutoFit.png',
  'Calc\\43_DataLoad':   'Calc/43_DataLoad.png',
  'Calc\\44_DataPaste':  'Calc/44_DataPaste.png',
  'Calc\\45_ResultSave': 'Calc/45_ResultSave.png',
  'Calc\\46_CopyResult': 'Calc/46_CopyResult.png',
  'Calc\\47_CopyImage':  'Calc/47_CopyImage.png',
  // Menu
  'Menu\\Menu_Settings': 'Menu/Menu_Settings.png',
  'Menu\\Menu_Exit': 'Menu/Menu_Exit.png',
  'Menu\\Menu_NewFolder': 'Menu/Menu_NewFolder.png',
  'Menu\\Menu_Undo': 'Menu/Menu_Undo.png',
  'Menu\\Menu_Normalize': 'Menu/Menu_Normalize.png',
  'Menu\\Menu_Smooth': 'Menu/Menu_Smooth.png',
  'Menu\\Menu_Trim': 'Menu/Menu_Trim.png',
  'Menu\\Menu_BatchJobs': 'Menu/Menu_BatchJobs.png',
  'Menu\\Menu_Benchmark': 'Menu/Menu_Benchmark.png',
  'Menu\\Menu_NewMaterial': 'Menu/Menu_NewMaterial.png',
  'Menu\\Menu_EditTable': 'Menu/Menu_EditTable.png',
  'Menu\\Menu_Help': 'Menu/Menu_Help.png',
  'Menu\\Menu_About': 'Menu/Menu_About.png',
  'Menu\\Menu_SaveAs': 'Menu/Menu_SaveAs.png',
  // Project tree markers. Several PNGs become several source images on one
  // collection item, so TVirtualImageList picks the matching size instead of
  // resampling a 32 px source down to the 16 px the tree draws.
  'Tree\\ActiveModel': ['Tree/Tree_ActiveModel_16.png', 'Tree/Tree_ActiveModel_32.png'],
  'Tree\\LinkedData':  ['Tree/Tree_LinkedData_16.png', 'Tree/Tree_LinkedData_32.png'],
};

// Optional DFM names on the command line update just those, e.g.
//   node update_dfm.js "Tree\ActiveModel" "Tree\LinkedData"
// Without arguments every mapped icon is rewritten.
const ONLY = process.argv.slice(2);

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

const SOURCES_HEADER = '        SourceImages = <\n';
const SOURCES_TERMINATOR = '\n          end>';

/**
 * Body of a SourceImages collection: one item per PNG, the last closing the
 * collection with 'end>'. A single PNG reproduces the original formatting
 * byte for byte, so single-source items are left untouched.
 */
function sourceImagesBlock(pngPaths) {
  return pngPaths.map(p =>
    '          item\n' +
    '            Image.Data = {\n' +
    pngToHexBlock(p) + '}\n' +
    '          end').join('\n') + '>';
}

/**
 * Append a brand new icon item to the end of the ImageCollection's Images
 * collection. The last item of a DFM collection ends with 'end>', so the new
 * item is spliced in by turning that terminator back into a plain 'end'.
 */
function appendItem(dfm, dfmName, pngPaths) {
  const objStart = dfm.indexOf('object ImageCollection: TImageCollection');
  if (objStart === -1)
    throw new Error('ImageCollection not found in DFM');
  // The Left/Top properties follow the Images collection.
  const propsIdx = dfm.indexOf('\n    Left = ', objStart);
  const termIdx = dfm.lastIndexOf('      end>', propsIdx);
  if (termIdx === -1)
    throw new Error('End of the Images collection not found');

  const item =
    '      end\n' +
    '      item\n' +
    `        Name = '${dfmName}'\n` +
    SOURCES_HEADER +
    sourceImagesBlock(pngPaths) + '\n' +
    '      end>';

  return dfm.slice(0, termIdx) + item + dfm.slice(termIdx + '      end>'.length);
}

function main() {
  let dfm = fs.readFileSync(DFM_PATH, 'utf-8');
  // Normalize line endings to \n for processing
  dfm = dfm.replace(/\r\n/g, '\n');

  let replaced = 0;
  let added = 0;
  let errors = [];

  let entries = Object.entries(ICON_MAP);
  if (ONLY.length > 0)
    entries = entries.filter(([dfmName]) => ONLY.includes(dfmName));

  for (const [dfmName, pngRelPath] of entries) {
    // A value may be one PNG or several sizes of the same icon.
    const relPaths = Array.isArray(pngRelPath) ? pngRelPath : [pngRelPath];
    const pngPaths = relPaths.map(r => path.join(ICONS_BASE, r));
    const missing = relPaths.filter((r, i) => !fs.existsSync(pngPaths[i]));
    if (missing.length > 0) {
      errors.push(`  MISSING: ${missing.join(', ')}`);
      continue;
    }

    // Find the Name = 'dfmName' line and then the Image.Data block after it
    // Escape backslashes for regex
    const escapedName = dfmName.replace(/\\/g, '\\\\');
    const namePattern = new RegExp(`Name = '${escapedName}'`);
    const nameMatch = namePattern.exec(dfm);
    if (!nameMatch) {
      // Not in the DFM yet - add it rather than treating it as an error.
      dfm = appendItem(dfm, dfmName, pngPaths);
      added++;
      console.log(`  ADDED: ${dfmName} <- ${relPaths.join(', ')}`);
      continue;
    }

    // Replace the whole SourceImages collection, so an icon can go from one
    // source image to several without the block being rebuilt by hand.
    const searchStart = nameMatch.index;
    const sourcesIdx = dfm.indexOf(SOURCES_HEADER, searchStart);
    if (sourcesIdx === -1 || sourcesIdx - searchStart > 500) {
      errors.push(`  No SourceImages near: ${dfmName}`);
      continue;
    }

    const bodyStart = sourcesIdx + SOURCES_HEADER.length;
    const termIdx = dfm.indexOf(SOURCES_TERMINATOR, bodyStart);
    if (termIdx === -1) {
      errors.push(`  No end of SourceImages for: ${dfmName}`);
      continue;
    }

    const bodyEnd = termIdx + SOURCES_TERMINATOR.length;
    dfm = dfm.slice(0, bodyStart) + sourceImagesBlock(pngPaths) + dfm.slice(bodyEnd);
    replaced++;
    console.log(`  OK: ${dfmName} <- ${relPaths.join(', ')}`);
  }

  // Restore \r\n line endings (DFM standard on Windows)
  dfm = dfm.replace(/\n/g, '\r\n');

  fs.writeFileSync(DFM_PATH, dfm, 'utf-8');
  console.log(`\nReplaced ${replaced}/${entries.length} icons in frm_Main.dfm, added ${added}`);

  if (errors.length > 0) {
    console.log('\nErrors:');
    errors.forEach(e => console.log(e));
  }
}

main();
