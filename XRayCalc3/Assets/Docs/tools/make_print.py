"""Builds Help/print.html (all chapters in one page) and Help/UserManual.pdf.

Usage:  python XRayCalc3/Assets/Docs/tools/make_print.py [--no-pdf]

The chapter order is the one the index and the prev/next links use. Each
chapter's <div class="container"> body is taken as is, minus the breadcrumb
bar, the "On this page" box and the bottom navigation. The PDF is printed
with Microsoft Edge in headless mode (Chrome works the same if you set
BROWSER below).
"""
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
HELP = os.path.normpath(os.path.join(HERE, "..", "Help"))
BROWSER = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

VERSION = "10"
CHAPTERS = [
    "Introduction.html", "QuickStart.html", "Installation.html", "Overview.html",
    "QuickReference.html", "Projects.html", "Models.html", "Data.html",
    "Calculation.html", "Fitting.html", "Results.html", "Charts.html",
    "Profiles.html", "Tools.html", "Settings.html", "UniversalMirror.html",
    "MCPServer.html", "FileFormats.html", "Examples.html", "Troubleshooting.html",
    "SourceCode.html", "Wiki.html",
]

PRINT_CSS = """
  .topbar, .page-toc, .bottom-nav { display: none !important; }
  .container { max-width: none; padding: 0; }
  .chapter { page-break-before: always; }
  .chapter:first-of-type { page-break-before: avoid; }
  .chapter h1 { font-size: 26px; border-bottom: 2px solid #1a5276; padding-bottom: 6px; }
  .chapter h1 .num { color: #2980b9; margin-right: 10px; }
  figure, table, .note, .tip, .warn, pre { page-break-inside: avoid; }
  h2, h3 { page-break-after: avoid; }
  .title-page { text-align: center; padding-top: 180px; page-break-after: always; }
  .title-page h1 { font-size: 40px; border: none; margin-bottom: 8px; }
  .title-page .sub { font-size: 18px; color: #555; }
  .title-page .meta { margin-top: 60px; color: #777; font-size: 14px; line-height: 1.8; }
  .toc { page-break-after: always; }
  .toc ol { columns: 2; font-size: 14px; }
  .toc li { margin-bottom: 6px; }
  .toc a { text-decoration: none; color: #1a5276; }
  a { color: #1a5276; text-decoration: none; }
"""


def chapter_body(name):
    with open(os.path.join(HELP, name), encoding="utf-8") as f:
        src = f.read()
    m = re.search(r'<div class="container">(.*)</div>\s*</body>', src, re.S)
    body = m.group(1)
    title = re.search(r"<h1>(.*?)</h1>", body, re.S).group(1)
    body = re.sub(r'<div class="page-toc">.*?</div>\s*</div>', "", body, count=1, flags=re.S)
    body = re.sub(r'<div class="bottom-nav">.*?</div>', "", body, count=1, flags=re.S)
    # prev/next removed; internal cross-links become in-document anchors
    anchor = os.path.splitext(name)[0]
    for other in CHAPTERS:
        body = body.replace(f'href="{other}"', f'href="#{os.path.splitext(other)[0]}"')
        body = body.replace(f'href="{other}#', f'href="#')
    body = body.replace('href="UserManual.html"', 'href="#toc"')
    return anchor, title, body


def build():
    parts = []
    toc = []
    for i, name in enumerate(CHAPTERS, 1):
        anchor, title, body = chapter_body(name)
        body = re.sub(r"<h1>(.*?)</h1>", rf'<h1><span class="num">{i}</span>\1</h1>', body, count=1, flags=re.S)
        parts.append(f'<div class="chapter" id="{anchor}">\n{body}\n</div>\n')
        toc.append(f'  <li><a href="#{anchor}">{re.sub(r"<[^>]+>", "", title)}</a></li>')

    page = f'''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>X-Ray Calc 3 — User Manual</title>
<link rel="stylesheet" href="style.css">
<style>{PRINT_CSS}</style>
</head>
<body>

<div class="container">

<div class="title-page">
  <h1>X-Ray Calc 3</h1>
  <div class="sub">User Manual</div>
  <div class="meta">Version {VERSION}<br>Copyright &copy; 2001&ndash;2026 Oleksiy Penkov<br>
  Penkov, O. V., Li, M., Mikki, S., Devizenko, A. &amp; Kopylets, I. (2024). <em>J. Appl. Cryst.</em> <strong>57</strong>, 555&ndash;566.</div>
</div>

<div class="toc" id="toc">
<h1>Contents</h1>
<ol>
{chr(10).join(toc)}
</ol>
</div>

{"".join(parts)}
</div>

</body>
</html>
'''
    out = os.path.join(HELP, "print.html")
    with open(out, "w", encoding="utf-8", newline="\n") as f:
        f.write(page)
    print(f"print.html: {len(CHAPTERS)} chapters")
    return out


def pdf(print_html):
    out = os.path.join(HELP, "UserManual.pdf")
    url = "file:///" + print_html.replace("\\", "/")
    cmd = [BROWSER, "--headless", "--disable-gpu", "--no-pdf-header-footer",
           f"--print-to-pdf={out}", url]
    subprocess.run(cmd, check=True, timeout=180, capture_output=True)
    print(f"UserManual.pdf: {os.path.getsize(out)} bytes")


if __name__ == "__main__":
    p = build()
    if "--no-pdf" not in sys.argv:
        pdf(p)
