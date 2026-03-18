"""Convert all SVG icons to 32x32 PNG files with transparent backgrounds."""
import os
import glob
import cairosvg

SVG_DIR = os.path.join(os.path.dirname(__file__), "SVG")
PNG_DIR = os.path.dirname(__file__)

# Map SVG files to their target subdirectories
TARGET_DIRS = {
    # Project icons -> Projects/
    "01_New": "Projects", "02_OpenProject": "Projects", "03_Reopen": "Projects",
    "04_Save": "Projects", "05_Print": "Projects", "06_AddModel": "Projects",
    "07_Export": "Projects", "08_Copy": "Projects", "09_Paste": "Projects",
    "10_Edit": "Projects", "11_AddExtension": "Projects", "12_DeleteExtension": "Projects",
    # Model icons -> Model/
    "add_layer": "Model", "add_period": "Model", "add_row_32_h": "Model",
    "clipboard_cut_32_h": "Model", "clipboard_copy_lined_32": "Model",
    "clipboard_paste_lined_32": "Model", "decrease_indent_32": "Model",
    "delete_row_32_h": "Model", "increase_indent_32_h": "Model",
    # Calc icons -> Calc/
    "40_Play": "Calc", "41_Forward": "Calc", "42_AutoFit": "Calc",
    "43_DataLoad": "Calc", "44_DataPaste": "Calc", "45_ResultSave": "Calc",
    "46_CopyResult": "Calc", "47_CopyImage": "Calc",
}

PARENT_DIR = os.path.dirname(PNG_DIR)

def convert_all():
    svg_files = glob.glob(os.path.join(SVG_DIR, "*.svg"))
    print(f"Found {len(svg_files)} SVG files")

    for svg_path in sorted(svg_files):
        name = os.path.splitext(os.path.basename(svg_path))[0]
        target_subdir = TARGET_DIRS.get(name, "")
        if target_subdir:
            out_dir = os.path.join(PARENT_DIR, target_subdir)
        else:
            out_dir = PNG_DIR

        os.makedirs(out_dir, exist_ok=True)
        png_path = os.path.join(out_dir, name + ".png")

        cairosvg.svg2png(
            url=svg_path,
            write_to=png_path,
            output_width=32,
            output_height=32,
        )
        print(f"  {name}.svg -> {os.path.relpath(png_path, PARENT_DIR)}")

    print(f"\nDone! {len(svg_files)} icons converted.")

if __name__ == "__main__":
    convert_all()
