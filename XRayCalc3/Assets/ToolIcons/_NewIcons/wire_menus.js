/**
 * Wire icons into main menu:
 * 1. Add 14 new Menu icons to ImageCollection
 * 2. Create vilMenu TVirtualImageList referencing all needed icons
 * 3. Set mmMain.Images = vilMenu
 * 4. Set ImageIndex on each menu item
 */
const fs = require('fs');
const path = require('path');

const DFM_PATH = path.join(__dirname, '..', '..', '..', 'Forms', 'frm_Main.dfm');
const ICONS_BASE = path.join(__dirname, '..');

// ── New menu icons to add to ImageCollection ──
const NEW_ICONS = [
  { name: 'Menu\\Menu_Settings',    file: 'Menu/Menu_Settings.png' },
  { name: 'Menu\\Menu_Exit',        file: 'Menu/Menu_Exit.png' },
  { name: 'Menu\\Menu_NewFolder',   file: 'Menu/Menu_NewFolder.png' },
  { name: 'Menu\\Menu_Undo',        file: 'Menu/Menu_Undo.png' },
  { name: 'Menu\\Menu_Normalize',   file: 'Menu/Menu_Normalize.png' },
  { name: 'Menu\\Menu_Smooth',      file: 'Menu/Menu_Smooth.png' },
  { name: 'Menu\\Menu_Trim',        file: 'Menu/Menu_Trim.png' },
  { name: 'Menu\\Menu_BatchJobs',   file: 'Menu/Menu_BatchJobs.png' },
  { name: 'Menu\\Menu_Benchmark',   file: 'Menu/Menu_Benchmark.png' },
  { name: 'Menu\\Menu_NewMaterial', file: 'Menu/Menu_NewMaterial.png' },
  { name: 'Menu\\Menu_EditTable',   file: 'Menu/Menu_EditTable.png' },
  { name: 'Menu\\Menu_Help',        file: 'Menu/Menu_Help.png' },
  { name: 'Menu\\Menu_About',       file: 'Menu/Menu_About.png' },
  { name: 'Menu\\Menu_SaveAs',      file: 'Menu/Menu_SaveAs.png' },
];

// ── vilMenu image list: maps vilMenu index -> ImageCollection name ──
// Index 0-28 come from the existing 29 icons, 29-42 from the new menu icons
const VIL_MENU_IMAGES = [
  // Existing icons (collection indices 0-28)
  { collName: 'Project\\01_New',                vilName: '01_New' },             // 0
  { collName: 'Project\\02_OpenProject',        vilName: '02_OpenProject' },     // 1
  { collName: 'Project\\03_Reopen',             vilName: '03_Reopen' },          // 2
  { collName: 'Project\\04_Save',               vilName: '04_Save' },            // 3
  { collName: 'Project\\05_Print',              vilName: '05_Print' },           // 4
  { collName: 'Project\\06_AddModel',           vilName: '06_AddModel' },        // 5
  { collName: 'Project\\07_Export',             vilName: '07_Export' },           // 6
  { collName: 'Project\\08_Copy',               vilName: '08_Copy' },            // 7
  { collName: 'Project\\09_Paste',              vilName: '09_Paste' },           // 8
  { collName: 'Project\\10_Edit',               vilName: '10_Edit' },            // 9
  { collName: 'Project\\11_AddExtension',       vilName: '11_AddExtension' },    // 10
  { collName: 'Project\\12_DeleteExtension',    vilName: '12_DeleteExtension' }, // 11
  { collName: 'Model\\add_layer',               vilName: 'add_layer' },          // 12
  { collName: 'Model\\add_period',              vilName: 'add_period' },         // 13
  { collName: 'Model\\add_row_32_h',            vilName: 'add_row_32_h' },       // 14
  { collName: 'Model\\clipboard_cut_32_h',      vilName: 'clipboard_cut' },      // 15
  { collName: 'Model\\clipboard_paste_lined_32',vilName: 'clipboard_paste' },    // 16
  { collName: 'Model\\decrease_indent_32',      vilName: 'decrease_indent' },    // 17
  { collName: 'Model\\delete_row_32_h',         vilName: 'delete_row' },         // 18
  { collName: 'Model\\increase_indent_32_h',    vilName: 'increase_indent' },    // 19
  { collName: 'Model\\clipboard_copy_lined_32', vilName: 'clipboard_copy' },     // 20
  { collName: 'Calc\\40_Play',                  vilName: '40_Play' },            // 21
  { collName: 'Calc\\41_Forward',               vilName: '41_Forward' },         // 22
  { collName: 'Calc\\42_AutoFit',               vilName: '42_AutoFit' },         // 23
  { collName: 'Calc\\43_DataLoad',              vilName: '43_DataLoad' },        // 24
  { collName: 'Calc\\44_DataPaste',             vilName: '44_DataPaste' },       // 25
  { collName: 'Calc\\45_ResultSave',            vilName: '45_ResultSave' },      // 26
  { collName: 'Calc\\46_CopyResult',            vilName: '46_CopyResult' },      // 27
  { collName: 'Calc\\47_CopyImage',             vilName: '47_CopyImage' },       // 28
  // New menu icons (collection indices 29-42)
  { collName: 'Menu\\Menu_Settings',            vilName: 'Menu_Settings' },      // 29
  { collName: 'Menu\\Menu_Exit',                vilName: 'Menu_Exit' },          // 30
  { collName: 'Menu\\Menu_NewFolder',           vilName: 'Menu_NewFolder' },     // 31
  { collName: 'Menu\\Menu_Undo',                vilName: 'Menu_Undo' },          // 32
  { collName: 'Menu\\Menu_Normalize',           vilName: 'Menu_Normalize' },     // 33
  { collName: 'Menu\\Menu_Smooth',              vilName: 'Menu_Smooth' },        // 34
  { collName: 'Menu\\Menu_Trim',                vilName: 'Menu_Trim' },          // 35
  { collName: 'Menu\\Menu_BatchJobs',           vilName: 'Menu_BatchJobs' },     // 36
  { collName: 'Menu\\Menu_Benchmark',           vilName: 'Menu_Benchmark' },     // 37
  { collName: 'Menu\\Menu_NewMaterial',         vilName: 'Menu_NewMaterial' },   // 38
  { collName: 'Menu\\Menu_EditTable',           vilName: 'Menu_EditTable' },     // 39
  { collName: 'Menu\\Menu_Help',                vilName: 'Menu_Help' },          // 40
  { collName: 'Menu\\Menu_About',               vilName: 'Menu_About' },         // 41
  { collName: 'Menu\\Menu_SaveAs',              vilName: 'Menu_SaveAs' },        // 42
];

// ── Menu item -> vilMenu ImageIndex mapping ──
// Object name in DFM -> index in vilMenu
const MENU_ICON_MAP = {
  // File menu
  'File2':                 0,   // New project         -> 01_New
  'Openproject1':          1,   // Open project        -> 02_OpenProject
  'miRecent':              2,   // Recent projects     -> 03_Reopen
  'Openproject2':          3,   // Save project        -> 04_Save
  'Saveprojectas1':        42,  // Save As             -> Menu_SaveAs
  'Settings1':             29,  // Settings            -> Menu_Settings
  'Exit1':                 30,  // Exit                -> Menu_Exit
  // Project menu
  'New1':                  5,   // New model           -> 06_AddModel
  'Newextension1':         7,   // Duplicate model     -> 08_Copy
  'Copymodel1':            7,   // Copy model          -> 08_Copy
  'PasteModel1':           8,   // Paste model         -> 09_Paste
  'NewFolder1':            31,  // New Folder          -> Menu_NewFolder
  // Structure menu
  'Add1':                  13,  // Add Stack           -> add_period
  'Insert1':               13,  // Insert Stack        -> add_period
  'Delete1':               18,  // Delete Stack        -> delete_row
  'Add2':                  12,  // Add Layer           -> add_layer
  'Insert2':               12,  // Insert Layer        -> add_layer
  'Copy1':                 20,  // Copy Layer          -> clipboard_copy
  'Paste1':                16,  // Paste Layer         -> clipboard_paste
  'actProjecEditModelText1': 9, // Edit as text        -> 10_Edit
  'Copyasimage1':          28,  // Copy as image       -> 47_CopyImage
  'Cut1':                  15,  // Cut Layer           -> clipboard_cut
  'Delete2':               11,  // Delete Layer        -> 12_DeleteExtension
  'Undo1':                 32,  // Undo                -> Menu_Undo
  // Data menu
  'Loadfromfile1':         24,  // Load                -> 43_DataLoad
  'Pastefromclipboard1':   25,  // From clipboard      -> 44_DataPaste
  'Normalize1':            33,  // Normalize           -> Menu_Normalize
  'NormalizeAuto1':        33,  // Normalize Auto      -> Menu_Normalize
  'Smooth1':               34,  // Smooth              -> Menu_Smooth
  'rim1':                  35,  // Trim                -> Menu_Trim
  'Copytoclipboad1':       27,  // Copy to clipboard   -> 46_CopyResult
  'Exporttofile1':         6,   // Export to file      -> 07_Export
  // Calc menu
  'Calc3':                 21,  // Run                 -> 40_Play
  'Calcall1':              22,  // Calc all            -> 41_Forward
  'Fitting1':              23,  // Auto Fitting        -> 42_AutoFit
  'Calcbatchjobs1':        36,  // Batch jobs          -> Menu_BatchJobs
  'Benchmark1':            37,  // Benchmark           -> Menu_Benchmark
  // Result menu
  'Save1':                 26,  // Export              -> 45_ResultSave
  'Saveplotasfile1':       6,   // Save as graphics    -> 07_Export
  'Copytoclipboard1':      27,  // Copy to clipboard   -> 46_CopyResult
  'CopyasBMP1':            28,  // Copy as BMP         -> 47_CopyImage
  'CopyasWMF1':            28,  // Copy as WMF         -> 47_CopyImage
  'ExportFitResults1':     6,   // Export fit results  -> 07_Export
  // Tools menu
  'ShowLibrary1':          38,  // New material        -> Menu_NewMaterial
  'EditHenketable1':       39,  // Edit Henke table    -> Menu_EditTable
  'MaterialsLibrary1':     38,  // Materials Library   -> Menu_NewMaterial
  // Help menu
  'UserManual1':           40,  // User Manual         -> Menu_Help
  'About1':                41,  // About               -> Menu_About
};

function pngToHexBlock(pngPath, indent) {
  const buf = fs.readFileSync(pngPath);
  const hex = buf.toString('hex').toUpperCase();
  const INDENT = ' '.repeat(indent);
  const LINE_LEN = 64;
  const lines = [];
  for (let i = 0; i < hex.length; i += LINE_LEN) {
    lines.push(INDENT + hex.slice(i, i + LINE_LEN));
  }
  return lines.join('\n');
}

function buildImageCollectionItems() {
  let items = '';
  for (const icon of NEW_ICONS) {
    const pngPath = path.join(ICONS_BASE, icon.file);
    const hex = pngToHexBlock(pngPath, 14);
    items += `      item\n`;
    items += `        Name = '${icon.name}'\n`;
    items += `        SourceImages = <\n`;
    items += `          item\n`;
    items += `            Image.Data = {\n`;
    items += hex + '}\n';
    items += `          end>\n`;
    items += `      end\n`;
  }
  return items;
}

function buildVilMenu() {
  let s = '';
  s += `  object vilMenu: TVirtualImageList\n`;
  s += `    Images = <\n`;
  for (let i = 0; i < VIL_MENU_IMAGES.length; i++) {
    const img = VIL_MENU_IMAGES[i];
    s += `      item\n`;
    s += `        CollectionIndex = ${i < 29 ? i : 29 + (i - 29)}\n`;
    s += `        CollectionName = '${img.collName}'\n`;
    s += `        Name = '${img.vilName}'\n`;
    if (i < VIL_MENU_IMAGES.length - 1) {
      s += `      end\n`;
    } else {
      s += `      end>\n`;
    }
  }
  s += `    ImageCollection = ImageCollection\n`;
  s += `    Left = 711\n`;
  s += `    Top = 240\n`;
  s += `  end\n`;
  return s;
}

function main() {
  let dfm = fs.readFileSync(DFM_PATH, 'utf-8');
  dfm = dfm.replace(/\r\n/g, '\n');

  // ── Step 1: Add new icons to ImageCollection ──
  // Find the closing of the Images list (the line with just ">")
  // that comes before the "Left = " in ImageCollection
  const collMatch = dfm.match(/object ImageCollection: TImageCollection\n\s+Images = <\n/);
  if (!collMatch) { console.error('Cannot find ImageCollection'); process.exit(1); }

  // Find the end of the last image item - look for the pattern "end>\n    Left"
  // within the ImageCollection
  const collStart = collMatch.index;
  const leftInColl = dfm.indexOf('\n    Left = ', collStart);
  if (leftInColl === -1) { console.error('Cannot find Left in ImageCollection'); process.exit(1); }

  // The last "end>" before Left is the end of the Images list
  const lastEndAngle = dfm.lastIndexOf('end>', leftInColl);
  // Insert new items just before this "end>" and change it to "end\n" + new items + "end>"
  // Actually, we need to insert after the last "end" (item close) but before the ">" (list close)
  // The structure is:  "      end\n" (last item end) + "  (various)  end>" (? no)
  // Let me look: the end> closes the Images list. We need to insert items before end>

  // Find the position right before the closing ">" of the Images list
  // The pattern is: "      end\n" (last item) then some whitespace + ">"
  // Actually in DFM the list close is just adding ">" to the last "end"
  // So "end>" means end of last item AND close of list

  // Strategy: replace the last "end>" with "end\n" + new items + last-item-end-with-close
  // But our new items already end with "end\n", so we need the very last one to be "end>"

  const newItems = buildImageCollectionItems();
  // The newItems ends with "      end\n", change the last "end" to "end>"
  // No wait - we insert BEFORE the closing >. The last existing item is "      end>"
  // We change it to "      end\n" + newItems (where last item ends with "end>")

  // Replace "end>" at lastEndAngle with "end\n" + newItems where last "end\n" becomes "end>"
  const newItemsTrimmed = newItems.trimEnd();
  // Replace the final "end" in newItems with "end>"  -- no, the "end>" closes the list
  // Let me just: replace existing "end>" with "end\n" + items, where last item has "end>"

  // Simplest approach: insert new items text before the "> on the Images list close
  // The "end>" at lastEndAngle: "end" closes the last item, ">" closes the Images list
  // Insert between: change "end>" to "end\n{new items}end>"
  // But new items each end with "      end\n", the last should end with "      end>"

  // Actually the right way: the list looks like <item...end item...end>
  // The > at the end closes the list. Just insert "item...end " before the >

  // Find exact position of the ">" that closes the list
  const closingAnglePos = lastEndAngle + 3; // "end" is 3 chars, then ">"
  // Insert new items between "end" and ">"
  const insertPos = closingAnglePos; // position of ">"

  // Build items where last ends with "end>" (no newline before >)
  let itemsText = '';
  for (let i = 0; i < NEW_ICONS.length; i++) {
    const icon = NEW_ICONS[i];
    const pngPath = path.join(ICONS_BASE, icon.file);
    const hex = pngToHexBlock(pngPath, 14);
    itemsText += `\n      item\n`;
    itemsText += `        Name = '${icon.name}'\n`;
    itemsText += `        SourceImages = <\n`;
    itemsText += `          item\n`;
    itemsText += `            Image.Data = {\n`;
    itemsText += hex + '}\n';
    itemsText += `          end>\n`;
    if (i < NEW_ICONS.length - 1) {
      itemsText += `      end`;
    } else {
      itemsText += `      end`;
    }
  }

  // Replace "end>" with "end" + itemsText + ">"
  dfm = dfm.slice(0, lastEndAngle) + 'end' + itemsText + '>' + dfm.slice(closingAnglePos + 1);

  console.log(`Step 1: Added ${NEW_ICONS.length} new icons to ImageCollection`);

  // ── Step 2: Add vilMenu TVirtualImageList ──
  // Insert it right before the final "end" of the form
  const formEnd = dfm.lastIndexOf('\nend');
  const vilMenuText = buildVilMenu();
  dfm = dfm.slice(0, formEnd) + '\n' + vilMenuText + dfm.slice(formEnd);

  console.log(`Step 2: Created vilMenu with ${VIL_MENU_IMAGES.length} images`);

  // ── Step 3: Set mmMain.Images = vilMenu ──
  // Find "object mmMain: TMainMenu" and add Images property
  const mmMainMatch = /object mmMain: TMainMenu\n/.exec(dfm);
  if (!mmMainMatch) { console.error('Cannot find mmMain'); process.exit(1); }
  const mmMainEnd = mmMainMatch.index + mmMainMatch[0].length;
  // Insert "    Images = vilMenu\n" after the object line
  dfm = dfm.slice(0, mmMainEnd) + '    Images = vilMenu\n' + dfm.slice(mmMainEnd);

  console.log('Step 3: Set mmMain.Images = vilMenu');

  // ── Step 4: Set ImageIndex on menu items ──
  let wired = 0;
  for (const [objName, imgIdx] of Object.entries(MENU_ICON_MAP)) {
    // Find "object objName: TMenuItem" and add/update ImageIndex
    const pattern = new RegExp(`object ${objName}: TMenuItem\\n`);
    const match = pattern.exec(dfm);
    if (!match) {
      console.log(`  WARNING: Menu item '${objName}' not found`);
      continue;
    }

    const objStart = match.index + match[0].length;

    // Check if ImageIndex already exists on next few lines
    const nextChunk = dfm.slice(objStart, objStart + 300);
    const existingImgIdx = nextChunk.match(/^(\s+)ImageIndex = \d+\n/m);

    if (existingImgIdx) {
      // Replace existing ImageIndex
      const replaceStart = objStart + nextChunk.indexOf(existingImgIdx[0]);
      const replaceEnd = replaceStart + existingImgIdx[0].length;
      dfm = dfm.slice(0, replaceStart) + `        ImageIndex = ${imgIdx}\n` + dfm.slice(replaceEnd);
    } else {
      // Insert ImageIndex after the object line
      dfm = dfm.slice(0, objStart) + `        ImageIndex = ${imgIdx}\n` + dfm.slice(objStart);
    }
    wired++;
  }

  console.log(`Step 4: Wired ${wired}/${Object.keys(MENU_ICON_MAP).length} menu items with ImageIndex`);

  // ── Write back ──
  dfm = dfm.replace(/\n/g, '\r\n');
  fs.writeFileSync(DFM_PATH, dfm, 'utf-8');
  console.log('\nDone! frm_Main.dfm updated.');
}

main();
