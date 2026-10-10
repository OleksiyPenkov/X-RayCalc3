const fs = require('fs');
const path = require('path');

const DFM_PATH = path.join(__dirname, '..', '..', '..', 'Forms', 'frm_Main.dfm');
const ICONS_BASE = path.join(__dirname, '..');

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

const VIL_MENU_IMAGES = [
  { collName: 'Project\\01_New',                vilName: '01_New' },
  { collName: 'Project\\02_OpenProject',        vilName: '02_OpenProject' },
  { collName: 'Project\\03_Reopen',             vilName: '03_Reopen' },
  { collName: 'Project\\04_Save',               vilName: '04_Save' },
  { collName: 'Project\\05_Print',              vilName: '05_Print' },
  { collName: 'Project\\06_AddModel',           vilName: '06_AddModel' },
  { collName: 'Project\\07_Export',             vilName: '07_Export' },
  { collName: 'Project\\08_Copy',               vilName: '08_Copy' },
  { collName: 'Project\\09_Paste',              vilName: '09_Paste' },
  { collName: 'Project\\10_Edit',               vilName: '10_Edit' },
  { collName: 'Project\\11_AddExtension',       vilName: '11_AddExtension' },
  { collName: 'Project\\12_DeleteExtension',    vilName: '12_DeleteExtension' },
  { collName: 'Model\\add_layer',               vilName: 'add_layer' },
  { collName: 'Model\\add_period',              vilName: 'add_period' },
  { collName: 'Model\\add_row_32_h',            vilName: 'add_row_32_h' },
  { collName: 'Model\\clipboard_cut_32_h',      vilName: 'clipboard_cut' },
  { collName: 'Model\\clipboard_paste_lined_32',vilName: 'clipboard_paste' },
  { collName: 'Model\\decrease_indent_32',      vilName: 'decrease_indent' },
  { collName: 'Model\\delete_row_32_h',         vilName: 'delete_row' },
  { collName: 'Model\\increase_indent_32_h',    vilName: 'increase_indent' },
  { collName: 'Model\\clipboard_copy_lined_32', vilName: 'clipboard_copy' },
  { collName: 'Calc\\40_Play',                  vilName: '40_Play' },
  { collName: 'Calc\\41_Forward',               vilName: '41_Forward' },
  { collName: 'Calc\\42_AutoFit',               vilName: '42_AutoFit' },
  { collName: 'Calc\\43_DataLoad',              vilName: '43_DataLoad' },
  { collName: 'Calc\\44_DataPaste',             vilName: '44_DataPaste' },
  { collName: 'Calc\\45_ResultSave',            vilName: '45_ResultSave' },
  { collName: 'Calc\\46_CopyResult',            vilName: '46_CopyResult' },
  { collName: 'Calc\\47_CopyImage',             vilName: '47_CopyImage' },
  { collName: 'Menu\\Menu_Settings',            vilName: 'Menu_Settings' },
  { collName: 'Menu\\Menu_Exit',                vilName: 'Menu_Exit' },
  { collName: 'Menu\\Menu_NewFolder',           vilName: 'Menu_NewFolder' },
  { collName: 'Menu\\Menu_Undo',                vilName: 'Menu_Undo' },
  { collName: 'Menu\\Menu_Normalize',           vilName: 'Menu_Normalize' },
  { collName: 'Menu\\Menu_Smooth',              vilName: 'Menu_Smooth' },
  { collName: 'Menu\\Menu_Trim',                vilName: 'Menu_Trim' },
  { collName: 'Menu\\Menu_BatchJobs',           vilName: 'Menu_BatchJobs' },
  { collName: 'Menu\\Menu_Benchmark',           vilName: 'Menu_Benchmark' },
  { collName: 'Menu\\Menu_NewMaterial',         vilName: 'Menu_NewMaterial' },
  { collName: 'Menu\\Menu_EditTable',           vilName: 'Menu_EditTable' },
  { collName: 'Menu\\Menu_Help',                vilName: 'Menu_Help' },
  { collName: 'Menu\\Menu_About',               vilName: 'Menu_About' },
  { collName: 'Menu\\Menu_SaveAs',              vilName: 'Menu_SaveAs' },
];

const MENU_ICON_MAP = {
  'File2':                 0,
  'Openproject1':          1,
  'miRecent':              2,
  'Openproject2':          3,
  'Saveprojectas1':        42,
  'Settings1':             29,
  'Exit1':                 30,
  'New1':                  5,
  'Newextension1':         7,
  'Copymodel1':            7,
  'PasteModel1':           8,
  'NewFolder1':            31,
  'Add1':                  13,
  'Insert1':               13,
  'Delete1':               18,
  'Add2':                  12,
  'Insert2':               12,
  'Copy1':                 20,
  'Paste1':                16,
  'actProjecEditModelText1': 9,
  'Copyasimage1':          28,
  'Cut1':                  15,
  'Delete2':               11,
  'Undo1':                 32,
  'Loadfromfile1':         24,
  'Pastefromclipboard1':   25,
  'Normalize1':            33,
  'NormalizeAuto1':        33,
  'Smooth1':               34,
  'rim1':                  35,
  'Copytoclipboad1':       27,
  'Exporttofile1':         6,
  'Calc3':                 21,
  'Calcall1':              22,
  'Fitting1':              23,
  'Calcbatchjobs1':        36,
  'Benchmark1':            37,
  'Save1':                 26,
  'Saveplotasfile1':       6,
  'Copytoclipboard1':      27,
  'CopyasBMP1':            28,
  'CopyasWMF1':            28,
  'ExportFitResults1':     6,
  'ShowLibrary1':          38,
  'EditHenketable1':       39,
  'MaterialsLibrary1':     38,
  'UserManual1':           40,
  'About1':                41,
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

  const collMatch = dfm.match(/object ImageCollection: TImageCollection\n\s+Images = <\n/);
  if (!collMatch) { console.error('Cannot find ImageCollection'); process.exit(1); }

  const collStart = collMatch.index;
  const leftInColl = dfm.indexOf('\n    Left = ', collStart);
  if (leftInColl === -1) { console.error('Cannot find Left in ImageCollection'); process.exit(1); }

  const lastEndAngle = dfm.lastIndexOf('end>', leftInColl);

  const newItems = buildImageCollectionItems();

  const newItemsTrimmed = newItems.trimEnd();

  // The "end>" at lastEndAngle: "end" closes the last item, ">" closes the Images list


  const closingAnglePos = lastEndAngle + 3;
  const insertPos = closingAnglePos;

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

  dfm = dfm.slice(0, lastEndAngle) + 'end' + itemsText + '>' + dfm.slice(closingAnglePos + 1);

  console.log(`Step 1: Added ${NEW_ICONS.length} new icons to ImageCollection`);

  const formEnd = dfm.lastIndexOf('\nend');
  const vilMenuText = buildVilMenu();
  dfm = dfm.slice(0, formEnd) + '\n' + vilMenuText + dfm.slice(formEnd);

  console.log(`Step 2: Created vilMenu with ${VIL_MENU_IMAGES.length} images`);

  const mmMainMatch = /object mmMain: TMainMenu\n/.exec(dfm);
  if (!mmMainMatch) { console.error('Cannot find mmMain'); process.exit(1); }
  const mmMainEnd = mmMainMatch.index + mmMainMatch[0].length;
  dfm = dfm.slice(0, mmMainEnd) + '    Images = vilMenu\n' + dfm.slice(mmMainEnd);

  console.log('Step 3: Set mmMain.Images = vilMenu');

  let wired = 0;
  for (const [objName, imgIdx] of Object.entries(MENU_ICON_MAP)) {
    const pattern = new RegExp(`object ${objName}: TMenuItem\\n`);
    const match = pattern.exec(dfm);
    if (!match) {
      console.log(`  WARNING: Menu item '${objName}' not found`);
      continue;
    }

    const objStart = match.index + match[0].length;

    const nextChunk = dfm.slice(objStart, objStart + 300);
    const existingImgIdx = nextChunk.match(/^(\s+)ImageIndex = \d+\n/m);

    if (existingImgIdx) {
      const replaceStart = objStart + nextChunk.indexOf(existingImgIdx[0]);
      const replaceEnd = replaceStart + existingImgIdx[0].length;
      dfm = dfm.slice(0, replaceStart) + `        ImageIndex = ${imgIdx}\n` + dfm.slice(replaceEnd);
    } else {
      dfm = dfm.slice(0, objStart) + `        ImageIndex = ${imgIdx}\n` + dfm.slice(objStart);
    }
    wired++;
  }

  console.log(`Step 4: Wired ${wired}/${Object.keys(MENU_ICON_MAP).length} menu items with ImageIndex`);

  dfm = dfm.replace(/\n/g, '\r\n');
  fs.writeFileSync(DFM_PATH, dfm, 'utf-8');
  console.log('\nDone! frm_Main.dfm updated.');
}

main();
