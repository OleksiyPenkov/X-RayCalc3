"""Quick GUI viewer for Universal Mirror best_curves .dat files."""

import os
import glob
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.widgets import CheckButtons, Button

CURVES_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "results", "best_curves")

# Load all .dat files
curves = {}
for path in sorted(glob.glob(os.path.join(CURVES_DIR, "*.dat"))):
    name = os.path.splitext(os.path.basename(path))[0]
    data = np.loadtxt(path, skiprows=1)
    curves[name] = (data[:, 0], data[:, 1])

if not curves:
    print(f"No .dat files found in {CURVES_DIR}")
    exit(1)

# Color palette for elements
COLORS = [
    "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728",
    "#9467bd", "#8c564b", "#e377c2", "#17becf",
]

# Create figure with toolbar, chart, and side panel
fig, ax = plt.subplots(figsize=(10, 6))
fig.subplots_adjust(left=0.12, right=0.82, bottom=0.15)

# Plot all curves
lines = {}
names = list(curves.keys())
for i, name in enumerate(names):
    angle, refl = curves[name]
    color = COLORS[i % len(COLORS)]
    line, = ax.plot(angle, refl, label=name, color=color, linewidth=1.5)
    lines[name] = line

ax.set_xlabel("Angle (degrees)")
ax.set_ylabel("Reflectivity")
ax.set_title("Universal Mirror - Best Curves")
ax.set_yscale("log")
ax.grid(True, alpha=0.3)
ax.legend(loc="upper right")

# Checkboxes to toggle curves
checkbox_ax = fig.add_axes([0.84, 0.3, 0.14, 0.5])
checkbox_ax.set_frame_on(False)
visibility = [True] * len(names)
check = CheckButtons(checkbox_ax, names, visibility)

# Style checkbox labels to match curve colors
for i, label in enumerate(check.labels):
    label.set_color(COLORS[i % len(COLORS)])
    label.set_fontsize(11)

def toggle(label):
    lines[label].set_visible(not lines[label].get_visible())
    ax.legend(loc="upper right")
    fig.canvas.draw_idle()

check.on_clicked(toggle)

# Log/Linear Y-axis toggle button
btn_ax = fig.add_axes([0.84, 0.05, 0.14, 0.06])
btn_scale = Button(btn_ax, "Linear Y", color="0.92", hovercolor="0.80")

def toggle_scale(event):
    if ax.get_yscale() == "log":
        ax.set_yscale("linear")
        btn_scale.label.set_text("Log Y")
    else:
        ax.set_yscale("log")
        btn_scale.label.set_text("Linear Y")
    fig.canvas.draw_idle()

btn_scale.on_clicked(toggle_scale)

# Pan/Zoom buttons
pan_ax = fig.add_axes([0.84, 0.19, 0.065, 0.06])
btn_pan = Button(pan_ax, "Pan", color="0.92", hovercolor="0.80")

zoom_ax = fig.add_axes([0.915, 0.19, 0.065, 0.06])
btn_zoom = Button(zoom_ax, "Zoom", color="0.92", hovercolor="0.80")

reset_ax = fig.add_axes([0.84, 0.12, 0.14, 0.06])
btn_reset = Button(reset_ax, "Reset View", color="0.92", hovercolor="0.80")

toolbar = fig.canvas.manager.toolbar

def activate_pan(event):
    if toolbar:
        toolbar.pan()

def activate_zoom(event):
    if toolbar:
        toolbar.zoom()

def reset_view(event):
    ax.autoscale()
    fig.canvas.draw_idle()

btn_pan.on_clicked(activate_pan)
btn_zoom.on_clicked(activate_zoom)
btn_reset.on_clicked(reset_view)

plt.show()
