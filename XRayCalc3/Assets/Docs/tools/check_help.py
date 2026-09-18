"""Link and page-anatomy checker for the X-Ray Calc 3 user manual.

Usage:  python XRayCalc3/Assets/Docs/tools/check_help.py [Help directory]

Checks every Help/*.html page:
  * every relative href / src resolves to a file in the Help folder;
  * every #anchor resolves to an id in the target page;
  * every entry of the "On this page" box points at an h2 of the same page;
  * every chapter (not the index, not print.html) has exactly one .topbar,
    one .bottom-nav, one .page-toc when it has h2 sections, and none of:
    a sidebar, a script.js reference, the old .warning class.
Exit status 1 when anything fails; each failure is printed as "file: message".
"""
import os
import re
import sys
from html.parser import HTMLParser

INDEX = "UserManual.html"
PRINT = "print.html"


class PageScan(HTMLParser):
    def __init__(self):
        super().__init__()
        self.ids = set()
        self.links = []          # (attr, value)
        self.classes = []        # every class attribute, split
        self.h2_ids = set()
        self.toc_links = []
        self._in_toc = 0
        self._div_depth = 0

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if "id" in a:
            self.ids.add(a["id"])
        if tag == "h2" and "id" in a:
            self.h2_ids.add(a["id"])
        if tag in ("a", "link") and a.get("href"):
            self.links.append(("href", a["href"]))
        if tag in ("img", "script") and a.get("src"):
            self.links.append(("src", a["src"]))
        cls = a.get("class", "")
        if cls:
            self.classes.extend(cls.split())
        if tag == "div":
            self._div_depth += 1
            if "page-toc" in cls.split():
                self._in_toc = self._div_depth
        if tag == "a" and self._in_toc and a.get("href"):
            self.toc_links.append(a["href"])

    def handle_endtag(self, tag):
        if tag == "div":
            if self._in_toc == self._div_depth:
                self._in_toc = 0
            self._div_depth -= 1


def scan(path):
    p = PageScan()
    with open(path, encoding="utf-8") as f:
        p.feed(f.read())
    return p


def main(help_dir):
    pages = sorted(f for f in os.listdir(help_dir) if f.lower().endswith(".html"))
    scans = {f: scan(os.path.join(help_dir, f)) for f in pages}
    failures = []

    def fail(page, msg):
        failures.append(f"{page}: {msg}")

    for page, s in scans.items():
        # links
        for attr, value in s.links:
            if re.match(r"^(https?:|mailto:|javascript:|data:)", value):
                continue
            target, _, anchor = value.partition("#")
            if target == "":
                if anchor and anchor not in s.ids:
                    fail(page, f"anchor #{anchor} not found on this page")
                continue
            full = os.path.normpath(os.path.join(help_dir, target))
            if not os.path.exists(full):
                fail(page, f"{attr} {value}: file not found")
                continue
            if anchor:
                t = scans.get(os.path.basename(target)) if os.path.dirname(target) == "" else None
                if t is None:
                    t = scan(full) if full.lower().endswith(".html") else None
                if t is not None and anchor not in t.ids:
                    fail(page, f"{value}: anchor not found in target")
        if page in (INDEX, PRINT):
            continue
        # anatomy
        for cls, want in (("topbar", 1), ("bottom-nav", 1)):
            n = s.classes.count(cls)
            if n != want:
                fail(page, f"expected {want} .{cls}, found {n}")
        toc = s.classes.count("page-toc")
        if s.h2_ids and toc != 1:
            fail(page, f"expected 1 .page-toc, found {toc}")
        if not s.h2_ids and toc:
            fail(page, "page-toc present but no h2 with id")
        for bad in ("sidebar", "warning", "top-nav", "page-nav", "back-to-top"):
            if bad in s.classes:
                fail(page, f"old class .{bad} still present")
        if any(v.endswith("script.js") for _, v in s.links):
            fail(page, "references script.js")
        for href in s.toc_links:
            anchor = href.lstrip("#")
            if not href.startswith("#"):
                fail(page, f"page-toc link {href} is not a local anchor")
            elif anchor not in s.h2_ids:
                fail(page, f"page-toc entry #{anchor} is not an h2 on this page")

    for line in failures:
        print(line)
    print(f"{len(pages)} pages, {len(failures)} failure(s)")
    return 1 if failures else 0


if __name__ == "__main__":
    here = os.path.dirname(os.path.abspath(__file__))
    d = sys.argv[1] if len(sys.argv) > 1 else os.path.join(here, "..", "Help")
    sys.exit(main(os.path.normpath(d)))
