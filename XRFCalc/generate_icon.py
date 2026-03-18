"""Generate XRFCalc app icon (.ico) with multiple sizes.

Design: Stylized X-ray fluorescence spectrum with peak curves
on a rounded-rect background, using the project's duotone palette.
"""

from PIL import Image, ImageDraw, ImageFont
import math
import os

NAVY = (25, 55, 95)
BLUE = (45, 100, 170)
TEAL = (60, 180, 220)
WHITE = (255, 255, 255)
BG_DARK = (20, 40, 70)
BG_GRAD_TOP = (15, 30, 55)
BG_GRAD_BOT = (30, 55, 95)
PEAK_YELLOW = (255, 200, 60)
PEAK_CYAN = (80, 220, 240)
PEAK_GREEN = (100, 220, 140)


def draw_icon(size):
    """Draw the icon at the given size using 4x supersampling."""
    ss = 4
    s = size * ss
    img = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Rounded rect background with gradient
    margin = s * 5 // 100
    r = s * 18 // 100
    for y in range(margin, s - margin):
        t = (y - margin) / max(1, (s - 2 * margin))
        c = tuple(int(BG_GRAD_TOP[i] + (BG_GRAD_BOT[i] - BG_GRAD_TOP[i]) * t) for i in range(3))
        d.line([(margin, y), (s - margin - 1, y)], fill=c + (255,))
    # Mask to rounded rect
    mask = Image.new('L', (s, s), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle([margin, margin, s - margin - 1, s - margin - 1], radius=r, fill=255)
    img.putalpha(mask)

    # Rounded rect border
    d.rounded_rectangle([margin, margin, s - margin - 1, s - margin - 1],
                        radius=r, outline=TEAL + (200,), width=max(1, s // 40))

    # Draw spectrum peaks (fluorescence lines)
    # Chart area
    cx_left = s * 15 // 100
    cx_right = s * 85 // 100
    cy_bottom = s * 78 // 100
    cy_top = s * 15 // 100
    chart_w = cx_right - cx_left
    chart_h = cy_bottom - cy_top

    # Baseline
    bw = max(1, s // 80)
    d.line([(cx_left, cy_bottom), (cx_right, cy_bottom)], fill=TEAL + (120,), width=bw)

    # Peak definitions: (x_fraction, height_fraction, width_sigma, color)
    peaks = [
        (0.18, 0.55, 0.04, PEAK_GREEN),
        (0.38, 0.85, 0.035, PEAK_CYAN),
        (0.55, 0.45, 0.03, PEAK_YELLOW),
        (0.72, 0.70, 0.04, TEAL),
        (0.88, 0.30, 0.025, PEAK_CYAN),
    ]

    # Build combined curve
    n_points = 200
    curve_y = [0.0] * n_points
    for px, ph, pw, _ in peaks:
        for i in range(n_points):
            x = i / (n_points - 1)
            dx = (x - px) / pw
            curve_y[i] += ph * math.exp(-0.5 * dx * dx)

    # Add small baseline noise
    import random
    random.seed(42)
    for i in range(n_points):
        curve_y[i] += 0.02 + 0.01 * random.random()

    # Draw filled area under curve with gradient
    for i in range(n_points - 1):
        x1 = cx_left + int(i / (n_points - 1) * chart_w)
        x2 = cx_left + int((i + 1) / (n_points - 1) * chart_w)
        y1 = cy_bottom - int(curve_y[i] * chart_h)
        y2 = cy_bottom - int(curve_y[i + 1] * chart_h)

        # Fill polygon under the curve segment
        poly = [(x1, y1), (x2, y2), (x2, cy_bottom), (x1, cy_bottom)]
        avg_h = (curve_y[i] + curve_y[i + 1]) / 2
        alpha = int(40 + 60 * avg_h)
        d.polygon(poly, fill=TEAL[:3] + (alpha,))

    # Draw curve line
    line_w = max(2, s // 50)
    points = []
    for i in range(n_points):
        x = cx_left + int(i / (n_points - 1) * chart_w)
        y = cy_bottom - int(curve_y[i] * chart_h)
        points.append((x, y))

    # Draw with per-peak coloring
    for i in range(len(points) - 1):
        frac = i / (n_points - 1)
        # Find dominant peak color
        best_color = TEAL
        best_val = 0
        for px, ph, pw, pc in peaks:
            dx = (frac - px) / pw
            val = ph * math.exp(-0.5 * dx * dx)
            if val > best_val:
                best_val = val
                best_color = pc
        # Blend with teal based on height
        t = min(1.0, best_val * 2)
        c = tuple(int(TEAL[j] * (1 - t) + best_color[j] * t) for j in range(3))
        d.line([points[i], points[i + 1]], fill=c + (255,), width=line_w)

    # Draw peak dots at tips
    for px, ph, pw, pc in peaks:
        x = cx_left + int(px * chart_w)
        y = cy_bottom - int((ph + 0.02) * chart_h)
        dot_r = max(2, s // 40)
        d.ellipse([x - dot_r, y - dot_r, x + dot_r, y + dot_r],
                  fill=pc + (255,), outline=WHITE + (180,), width=max(1, s // 120))

    # "XRF" text at bottom
    text_y = s * 82 // 100
    font_size = s * 14 // 100
    try:
        font = ImageFont.truetype("segoeui.ttf", font_size)
        font_bold = ImageFont.truetype("segoeuib.ttf", font_size)
    except (OSError, IOError):
        try:
            font = ImageFont.truetype("arial.ttf", font_size)
            font_bold = ImageFont.truetype("arialbd.ttf", font_size)
        except (OSError, IOError):
            font = ImageFont.load_default()
            font_bold = font

    text = "XRF"
    bbox = d.textbbox((0, 0), text, font=font_bold)
    tw = bbox[2] - bbox[0]
    tx = (s - tw) // 2
    # Shadow
    d.text((tx + max(1, s // 120), text_y + max(1, s // 120)), text,
           fill=(0, 0, 0, 100), font=font_bold)
    # Main text
    d.text((tx, text_y), text, fill=PEAK_YELLOW + (255,), font=font_bold)

    # Downscale with LANCZOS
    img = img.resize((size, size), Image.LANCZOS)
    return img


def main():
    sizes = [16, 24, 32, 48, 64, 128, 256]
    images = []
    for sz in sizes:
        print(f"  Generating {sz}x{sz}...")
        images.append(draw_icon(sz))

    out_dir = os.path.dirname(os.path.abspath(__file__))
    ico_path = os.path.join(out_dir, 'XRFCalc.ico')

    # Save as .ico with all sizes
    images[0].save(ico_path, format='ICO', sizes=[(s, s) for s in sizes],
                   append_images=images[1:])
    print(f"  Saved: {ico_path}")

    # Also save 256px PNG for reference
    png_path = os.path.join(out_dir, 'XRFCalc_256.png')
    images[-1].save(png_path)
    print(f"  Saved: {png_path}")


if __name__ == '__main__':
    main()
