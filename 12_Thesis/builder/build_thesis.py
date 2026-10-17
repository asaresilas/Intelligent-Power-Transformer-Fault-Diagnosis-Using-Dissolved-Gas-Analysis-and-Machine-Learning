"""Builds the MPhil thesis (.docx) from the chapter sources in 12_Thesis/source.

Source syntax (one block per paragraph, blocks separated by blank lines):
  # TITLE                     chapter (new page; "CHAPTER n" above the title)
  ## Heading / ### Heading     numbered second / third level headings (n.m / n.m.k)
  #### Heading                unnumbered fourth level (italic)
  - item / * item / 1. item   lettered (a., b., ...), bulleted, or numbered list items
  $$ unicode-math $$ {#eq:id} display equation, numbered (n.m) at the right
  where: ... then lines ": symbol = meaning"   symbol list under an equation
  ![caption](path){#fig:id width=15}           figure, caption below ("Fig. n.m")
  Table: caption {#tab:id} followed by | a | b | rows (row 2 = |---| alignment row) and optional "Source: ..."
  [[TABLE:name]]              table generated from a result file by tables.py
  \\newpage                    page break
Inline: **bold**, *italic*, ~sub~, ^sup^, {{fact}} (value from facts.py), @fig:id / @tab:id / @eq:id / @sec:id.
Chemical formulae H2, CH4, C2H6, C2H4, C2H2, CO2, CO get subscripts automatically.
"""
import csv
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from docx_writer import Docx, run_xml, field_xml, TEXT_WIDTH_TWIPS  # noqa: E402
import facts as F  # noqa: E402
import tables as T  # noqa: E402

THESIS = Path(__file__).resolve().parents[1]
ROOT = THESIS.parent
SRC = THESIS / "source"
OUT = THESIS / "build"
OUT.mkdir(exist_ok=True)

CHEM = re.compile(r"(?<![A-Za-z0-9_.\-])(C2H6|C2H4|C2H2|CH4|CO2|H2|O2|N2)(?![A-Za-z0-9_])")
INLINE = re.compile(r"(\*\*.+?\*\*|\*[^*\s][^*]*?\*|~[^~]+?~|\^[^^]+?\^)")


class State:
    def __init__(self):
        self.chapter = 0
        self.h2 = 0
        self.h3 = 0
        self.fig = 0
        self.tab = 0
        self.eq = 0
        self.labels = {}       # id -> text ("Fig. 3.1")
        self.toc = []          # (level, number, text, bookmark)
        self.figs = []         # (number, title, bookmark)
        self.tabs = []
        self.appendix = None   # letter when in appendices
        self.bm = 0

    def bookmark(self, prefix):
        self.bm += 1
        return f"_{prefix}{self.bm:04d}"


def fact_sub(text):
    def rep(m):
        key = m.group(1).strip()
        if key not in F.FACTS:
            raise KeyError(f"unknown fact {{{{{key}}}}}")
        return str(F.FACTS[key])
    return re.sub(r"\{\{([^}]+)\}\}", rep, text)


DRAFT = bool(__import__("os").environ.get("THESIS_DRAFT"))
MISSING = set()


def ref_sub(text, st):
    def rep(m):
        key = m.group(1)
        if key not in st.labels:
            if DRAFT:
                MISSING.add(key)
                return "[??]"
            raise KeyError(f"unknown cross-reference @{key}")
        return st.labels[key]
    return re.sub(r"@((?:fig|tab|eq|sec|app):[A-Za-z0-9_\-]+)", rep, text)


def runs(text, bold=False, italic=False, size=None, chem=True):
    """Inline markup -> run xml."""
    out = []
    for part in INLINE.split(text):
        if not part:
            continue
        b, i, v, t = bold, italic, None, part
        if part.startswith("**") and part.endswith("**") and len(part) > 4:
            b, t = True, part[2:-2]
        elif part.startswith("*") and part.endswith("*") and len(part) > 2:
            i, t = True, part[1:-1]
        elif part.startswith("~") and part.endswith("~"):
            v, t = "subscript", part[1:-1]
        elif part.startswith("^") and part.endswith("^"):
            v, t = "superscript", part[1:-1]
        if v or not chem:
            out.append(run_xml(t, bold=b, italic=i, vert=v, size=size))
            continue
        pos = 0
        for m in CHEM.finditer(t):
            out.append(run_xml(t[pos:m.start()], bold=b, italic=i, size=size))
            for ch in m.group(1):
                out.append(run_xml(ch, bold=b, italic=i, size=size, vert="subscript" if ch.isdigit() else None))
            pos = m.end()
        out.append(run_xml(t[pos:], bold=b, italic=i, size=size))
    return "".join(x for x in out if "<w:t" in x or "<w:tab" in x)


# ---------------------------------------------------------------- first pass: numbering
def number_pass(blocks_by_file, st):
    """Assigns numbers to headings, figures, tables, equations so that forward references work."""
    for fname, blocks in blocks_by_file:
        for blk in blocks:
            first = blk[0]
            if first.startswith("# "):
                if first.startswith("# APPENDIX "):
                    st.appendix = first.split()[2] if st.appendix is None else first.split()[2]
                    st.fig = st.tab = st.eq = 0
                    m = re.search(r"\{#(app:[\w\-]+)\}", first)
                    if m:
                        st.labels[m.group(1)] = "Appendix " + st.appendix
                    continue
                st.chapter += 1
                st.h2 = st.h3 = st.fig = st.tab = st.eq = 0
                m = re.search(r"\{#(sec:[\w\-]+)\}", first)
                if m:
                    st.labels[m.group(1)] = f"Chapter {st.chapter}"
            elif first.startswith("## "):
                st.h2 += 1
                st.h3 = 0
                m = re.search(r"\{#(sec:[\w\-]+)\}", first)
                if m:
                    st.labels[m.group(1)] = f"Section {st.chapter}.{st.h2}"
            elif first.startswith("### "):
                st.h3 += 1
                m = re.search(r"\{#(sec:[\w\-]+)\}", first)
                if m:
                    st.labels[m.group(1)] = f"Section {st.chapter}.{st.h2}.{st.h3}"
            for line in blk:
                for kind, rx in (("fig", r"^!\[.*\]\(.*\)\{#(fig:[\w\-]+)"), ("tab", r"^(?:Table:.*|\[\[TABLE:[^\]]+\]\]).*\{#(tab:[\w\-]+)\}"),
                                 ("eq", r"^\$\$.*\$\$\s*\{#(eq:[\w\-]+)\}")):
                    m = re.search(rx, line)
                    if m:
                        if kind == "fig":
                            st.fig += 1
                            n = st.fig
                            st.labels[m.group(1)] = f"Fig. {pref(st)}{n}"
                        elif kind == "tab":
                            st.tab += 1
                            st.labels[m.group(1)] = f"Table {pref(st)}{st.tab}"
                        else:
                            st.eq += 1
                            st.labels[m.group(1)] = f"Equation ({pref(st)}{st.eq})"
    st.chapter = st.h2 = st.h3 = st.fig = st.tab = st.eq = 0
    st.appendix = None


def pref(st):
    return f"{st.appendix}" if st.appendix else f"{st.chapter}."


def parse_blocks(text):
    blocks, cur = [], []
    for line in text.splitlines():
        if line.strip() == "":
            if cur:
                blocks.append(cur)
                cur = []
        else:
            cur.append(line.rstrip())
    if cur:
        blocks.append(cur)
    return blocks


# ---------------------------------------------------------------- emit
def emit_table(doc, st, caption, label, rows, align, widths, note=None, font=10.5):
    st.tab += 1
    num = f"{pref(st)}{st.tab}"
    bm = st.bookmark("Tab")
    st.tabs.append((num, caption, bm))
    doc.p(runs(f"Table {num} ") + runs(caption), style="TabCaption", bookmark=bm)
    cell_rows = [[runs(c.strip()) for c in r] for r in rows]
    doc.table(cell_rows, header_rows=1, widths=widths, align=align, font_size=font, keep=len(cell_rows) <= 22)
    if note:
        doc.p(runs(note, size=10.5), style="TableNote")
    else:
        doc.p("", after=120)


def col_widths(rows, override=None):
    n = max(len(r) for r in rows)
    if override:
        tot = sum(override)
        return [round(TEXT_WIDTH_TWIPS * w / tot) for w in override]
    lens = [max(len(re.sub(r"[*~^]", "", r[c])) if c < len(r) else 0 for r in rows) for c in range(n)]
    lens = [min(max(l, 4), 40) for l in lens]
    tot = sum(lens)
    return [round(TEXT_WIDTH_TWIPS * l / tot) for l in lens]


def emit_block(doc, st, blk):
    first = blk[0]
    # ---- chapter / appendix
    if first.startswith("# "):
        title = re.sub(r"\s*\{#[^}]+\}", "", first[2:]).strip()
        if title.startswith("APPENDIX "):
            parts = title.split(" ", 2)
            st.appendix = parts[1]
            st.fig = st.tab = st.eq = 0
            bm = st.bookmark("Toc")
            st.toc.append((1, "", title, bm))
            doc.p(run_xml(f"APPENDIX {parts[1]}", bold=True), style="FrontHeading", page_break_before=True,
                  bookmark=bm, after=120)
            doc.p(runs(parts[2].upper(), bold=True), style="FrontHeading")
            return
        if title in ("REFERENCES", "APPENDICES"):
            bm = st.bookmark("Toc")
            st.toc.append((1, "", title, bm))
            doc.p(run_xml(title, bold=True), style="FrontHeading", page_break_before=True, bookmark=bm)
            return
        st.chapter += 1
        st.h2 = st.h3 = st.fig = st.tab = st.eq = 0
        bm = st.bookmark("Toc")
        st.toc.append((1, f"CHAPTER {st.chapter}", title.upper(), bm))
        doc.p(run_xml(f"CHAPTER {st.chapter}", bold=True, size=14) + '<w:r><w:br/></w:r>' +
              run_xml(title.upper(), bold=True, size=12), style="Heading1", bookmark=bm)
        return
    if first.startswith("## "):
        st.h2 += 1
        st.h3 = 0
        text = re.sub(r"\s*\{#[^}]+\}", "", first[3:]).strip()
        num = f"{st.chapter}.{st.h2}" if not st.appendix else f"{st.appendix}{st.h2}"
        bm = st.bookmark("Toc")
        st.toc.append((2, num, text, bm))
        doc.p(run_xml(num + "\t") + runs(text, bold=True), style="Heading2", bookmark=bm,
              tabs=[("left", 709, "none")], ind_left=709, ind_hanging=709)
        return
    if first.startswith("### "):
        st.h3 += 1
        text = re.sub(r"\s*\{#[^}]+\}", "", first[4:]).strip()
        num = f"{st.chapter}.{st.h2}.{st.h3}"
        bm = st.bookmark("Toc")
        st.toc.append((3, num, text, bm))
        doc.p(run_xml(num + "\t") + runs(text), style="Heading3", bookmark=bm,
              tabs=[("left", 851, "none")], ind_left=851, ind_hanging=851)
        return
    if first.startswith("#### "):
        doc.p(runs(first[5:].strip(), italic=True), style="Heading4")
        return
    if first.strip() == "&nbsp;":
        doc.p("")
        return
    if first.strip() == "\\newpage":
        doc.page_break()
        return
    # ---- figure
    m = re.match(r"^!\[(.*)\]\((.*)\)\{#(fig:[\w\-]+)(?:\s+width=([\d.]+))?(?:\s+maxh=([\d.]+))?\}\s*$", first)
    if m:
        cap, path, _, width, maxh = m.groups()
        width = float(width or 15)
        p = (ROOT / path) if not Path(path).is_absolute() else Path(path)
        if not p.exists():
            raise FileNotFoundError(p)
        st.fig += 1
        num = f"{pref(st)}{st.fig}"
        bm = st.bookmark("Fig")
        cap = ref_sub(fact_sub(cap), st)
        st.figs.append((num, cap, bm))
        doc.p(doc.image(str(p), width, float(maxh) if maxh else 20.5), style="FigPara")
        doc.p(runs(f"Fig. {num} ", bold=True) + runs(cap, bold=True), style="FigCaption", bookmark=bm)
        for extra in blk[1:]:      # an optional note line under the caption
            doc.p(runs(ref_sub(fact_sub(extra), st), size=10.5), style="TableNote", jc="center")
        return
    # ---- generated table
    m = re.match(r"^\[\[TABLE:([\w]+)(?:\s+(.*?))?\]\]\s*(?:\{#(tab:[\w\-]+)\})?\s*$", first)
    if m:
        name, arg, label = m.groups()
        spec = T.TABLES[name](arg) if arg else T.TABLES[name]()
        rows = [[ref_sub(fact_sub(c), st) for c in r] for r in spec["rows"]]
        widths = col_widths(rows, spec.get("widths"))
        emit_table(doc, st, ref_sub(fact_sub(spec["caption"]), st), label, rows, spec.get("align"), widths,
                   ref_sub(fact_sub(spec["note"]), st) if spec.get("note") else None, spec.get("font", 10.5))
        return
    # ---- pipe table
    if first.startswith("Table:"):
        cap = re.sub(r"\s*\{#[^}]+\}", "", first[6:]).strip()
        lines = [l for l in blk[1:] if l.startswith("|")]
        note = " ".join(l for l in blk[1:] if not l.startswith("|")) or None
        rows = []
        align = None
        for i, l in enumerate(lines):
            cells = [c.strip() for c in l.strip().strip("|").split("|")]
            if i == 1 and all(re.fullmatch(r":?-{2,}:?", c) for c in cells):
                align = ["center" if c.startswith(":") and c.endswith(":") else "right" if c.endswith(":") else "left"
                         for c in cells]
                continue
            rows.append([ref_sub(fact_sub(c), st) for c in cells])
        widths = None
        mw = re.search(r"\{widths=([\d,\s]+)\}", first)
        if mw:
            widths = [float(x) for x in mw.group(1).split(",")]
            cap = re.sub(r"\s*\{widths=[^}]+\}", "", cap)
        emit_table(doc, st, ref_sub(fact_sub(cap), st), None, rows, align, col_widths(rows, widths),
                   ref_sub(fact_sub(note), st) if note else None)
        return
    # ---- equation
    m = re.match(r"^\$\$(.*)\$\$\s*(?:\{#(eq:[\w\-]+)\})?\s*$", first)
    if m:
        st.eq += 1
        num = f"{pref(st)}{st.eq}"
        lin = fact_sub(m.group(1).strip())
        doc.p(f'<w:r><w:t xml:space="preserve">{escape_xml(lin)}#({num})</w:t></w:r>', style="EqSrc")
        return
    # ---- where list
    if first.strip().lower() == "where:":
        doc.p(run_xml("where:"), keep_next=True, after=40, jc="left", line=276)
        items = [l[1:].strip() for l in blk[1:] if l.startswith(":")]
        for k, it in enumerate(items):
            sym, _, meaning = it.partition("=")
            doc.p(runs(sym.strip()) + run_xml("\t") + runs(ref_sub(fact_sub(meaning.strip()), st)), style="WhereItem",
                  tabs=[("left", 1134, "none")], keep_next=(k < len(items) - 1),
                  after=200 if k == len(items) - 1 else 40)
        return
    # ---- lists
    if re.match(r"^(- |\* |\d+\. )", first):
        items = []
        for l in blk:
            mm = re.match(r"^(- |\* |\d+\. )(.*)$", l)
            if mm:
                items.append([mm.group(1), mm.group(2)])
            else:
                items[-1][1] += " " + l.strip()
        for k, (mark, text) in enumerate(items):
            if mark == "- ":
                lab = chr(ord("a") + k) + "."
            elif mark == "* ":
                lab = "•"
            else:
                lab = mark.strip()
            doc.p(run_xml(lab + "\t") + runs(ref_sub(fact_sub(text), st)), style="ListItem",
                  tabs=[("left", 720, "none")], after=200 if k == len(items) - 1 else 60)
        return
    # ---- reference entry block
    if first.startswith("REF "):
        for l in blk:
            doc.p(runs(l[4:], chem=True), style="RefEntry")
        return
    # ---- paragraph
    text = " ".join(blk)
    doc.p(runs(ref_sub(fact_sub(text), st)))


def escape_xml(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


# ---------------------------------------------------------------- front matter
def title_page(doc, meta):
    c = "TitlePage"
    doc.p(run_xml("UNIVERSITY OF MINES AND TECHNOLOGY, TARKWA"), style=c, after=200)
    doc.p(doc.image(str(THESIS / "assets" / "umat_logo.png"), 2.9), style=c, after=200)
    doc.p(run_xml(meta["faculty"].upper()), style=c, after=0)
    doc.p(run_xml(meta["department"].upper()), style=c, after=360)
    doc.p(run_xml("A THESIS REPORT ENTITLED"), style=c, after=360)
    doc.p(run_xml(meta["title"].upper(), bold=True), style=c, after=360)
    doc.p(run_xml("BY"), style=c, after=0)
    doc.p(run_xml(meta["author"].upper()), style=c, after=360)
    doc.p(run_xml(meta["statement"].upper()), style=c, after=480)
    doc.p(run_xml("THESIS SUPERVISOR"), style=c, after=600)
    doc.p(run_xml("…" * 30), style=c, after=0)
    doc.p(run_xml(meta["supervisor"].upper()), style=c, after=360)
    doc.p(run_xml("TARKWA, GHANA"), style=c, after=0)
    doc.p(run_xml(meta["date"].upper()), style=c, after=0)
    doc.section_break("title")


def front_heading(doc, st, text, toc=True):
    bm = st.bookmark("Toc")
    if toc:
        st.toc.append((0, "", text, bm))
    doc.p(run_xml(text, bold=True), style="FrontHeading", page_break_before=True, bookmark=bm)


def contents(doc, st):
    """Contents, list of figures, list of tables with PAGEREF fields (updated by Word)."""
    W = TEXT_WIDTH_TWIPS
    tabs_right = [("right", W, "none")]
    front_heading(doc, st, "TABLE OF CONTENTS")
    doc.p(run_xml("Content", bold=True) + run_xml("\t") + run_xml("Page", bold=True), style="TocLine",
          tabs=tabs_right, after=160)
    for level, num, text, bm in st.toc_final:
        pg = field_xml(f"PAGEREF {bm} \\h", "0", bold=level in (0, 1))
        if level == 0:
            doc.p(run_xml(text, bold=True) + run_xml("\t") + pg, style="TocLine", tabs=tabs_right)
        elif level == 1:
            label = (num + " " if num else "") + text
            doc.p(run_xml(label, bold=True) + run_xml("\t") + pg, style="TocLine", tabs=tabs_right, before=160,
                  after=80, ind_left=0, ind_hanging=0)
        elif level == 2:
            doc.p(run_xml(num + "\t") + runs(text) + run_xml("\t") + pg, style="TocLine",
                  tabs=[("left", 709, "none"), ("right", W, "none")], ind_left=709, ind_hanging=709)
        else:
            doc.p(run_xml(num + "\t") + runs(text) + run_xml("\t") + pg, style="TocLine",
                  tabs=[("left", 1418, "none"), ("right", W, "none")], ind_left=1418, ind_hanging=851)
    for title, items, head in (("LIST OF FIGURES", st.figs_final, "Fig."), ("LIST OF TABLES", st.tabs_final, "Table")):
        front_heading(doc, st, title)
        doc.p(run_xml(head, bold=True) + run_xml("\t") + run_xml("Title", bold=True) + run_xml("\t") +
              run_xml("Page", bold=True), style="TocLine", tabs=[("left", 1134, "none"), ("right", W, "none")],
              after=160)
        for num, cap, bm in items:
            short = cap.split(". ")[0] if len(cap) > 140 else cap
            doc.p(run_xml(num + "\t") + runs(short) + run_xml("\t") + field_xml(f"PAGEREF {bm} \\h", "0"),
                  style="TocLine", tabs=[("left", 1134, "none"), ("right", W, "none")], ind_left=1134,
                  ind_hanging=1134, after=60)


def two_col_list(doc, st, title, header, rows, w1=2200):
    front_heading(doc, st, title)
    W = TEXT_WIDTH_TWIPS
    cells = [[run_xml(header[0], bold=True), run_xml(header[1], bold=True)]]
    cells += [[runs(a), runs(b)] for a, b in rows]
    doc.table(cells, header_rows=1, widths=[w1, W - w1], font_size=11, shade_header=False)


def main():
    meta = json.loads((SRC / "meta.json").read_text(encoding="utf-8"))
    files = sorted(p for p in SRC.glob("*.md"))
    blocks_by_file = [(p.name, parse_blocks(p.read_text(encoding="utf-8"))) for p in files]
    front = dict(blocks_by_file).get("00_front.md")
    body_files = [(n, b) for n, b in blocks_by_file if n != "00_front.md"]

    # numbering pass for cross references
    st = State()
    number_pass(body_files, st)

    # dry run of the body to collect toc/figs/tabs (needed by the contents pages)
    dry = Docx()
    st_dry = State()
    st_dry.labels = st.labels
    for _, blocks in body_files:
        for b in blocks:
            emit_block(dry, st_dry, b)

    doc = Docx()
    st2 = State()
    st2.labels = st.labels
    title_page(doc, meta)
    # front matter sections from 00_front.md: blocks starting with "@@ HEADING"
    sections, cur = [], None
    for b in front:
        if b[0].startswith("@@ "):
            cur = [b[0][3:].strip(), []]
            sections.append(cur)
        else:
            cur[1].append(b)
    # TOC entries for front matter are collected in order of appearance
    st2.toc_final = []
    order = []
    for name, blocks in sections:
        order.append(name)
    # the contents list needs the bookmarks of the front headings: pre-assign
    pre = {}
    for name in order + ["TABLE OF CONTENTS", "LIST OF FIGURES", "LIST OF TABLES", "LIST OF ABBREVIATIONS",
                         "LIST OF SYMBOLS", "INTERNATIONAL SYSTEM OF UNITS (SI UNITS)"]:
        pre[name] = f"_Front{len(pre):02d}"
    front_toc = []
    for name in ["DECLARATION", "ABSTRACT", "DEDICATION", "ACKNOWLEDGEMENTS", "TABLE OF CONTENTS",
                 "LIST OF FIGURES", "LIST OF TABLES", "LIST OF ABBREVIATIONS", "LIST OF SYMBOLS",
                 "INTERNATIONAL SYSTEM OF UNITS (SI UNITS)"]:
        if name in pre and (name in order or name not in ("DECLARATION", "ABSTRACT", "DEDICATION", "ACKNOWLEDGEMENTS")):
            front_toc.append((0, "", name, pre[name]))
    st2.toc_final = front_toc + st_dry.toc
    st2.figs_final = st_dry.figs
    st2.tabs_final = st_dry.tabs

    def fh(name):
        doc.p(run_xml(name, bold=True), style="FrontHeading", page_break_before=True, bookmark=pre[name])

    for name, blocks in sections:
        if name == "DEDICATION":
            doc.p("", page_break_before=True, bookmark=pre[name])
            for b in blocks:
                doc.p(runs(" ".join(b), italic=True), jc="center")
            continue
        fh(name)
        for b in blocks:
            emit_block(doc, st2, b)
    # contents and lists (use the dry-run bookmarks, which the real body reproduces identically)
    W = TEXT_WIDTH_TWIPS
    fh("TABLE OF CONTENTS")
    doc.p(run_xml("Content", bold=True) + run_xml("\t") + run_xml("Page", bold=True), style="TocLine",
          tabs=[("right", W, "none")], after=160)
    for level, num, text, bm in st2.toc_final:
        pg = field_xml(f"PAGEREF {bm} \\h", "0", bold=level in (0, 1))
        if level == 0:
            doc.p(run_xml(text, bold=True) + run_xml("\t") + pg, style="TocLine", tabs=[("right", W, "none")])
        elif level == 1:
            label = (num + "  " if num else "") + text
            doc.p(run_xml(label, bold=True) + run_xml("\t") + pg, style="TocLine", tabs=[("right", W, "none")],
                  before=200, after=100)
        elif level == 2:
            doc.p(run_xml(num + "\t") + runs(text) + run_xml("\t") + pg, style="TocLine",
                  tabs=[("left", 709, "none"), ("right", W, "none")], ind_left=709, ind_hanging=709)
        else:
            doc.p(run_xml(num + "\t") + runs(text) + run_xml("\t") + pg, style="TocLine",
                  tabs=[("left", 1560, "none"), ("right", W, "none")], ind_left=1560, ind_hanging=851)
    for title, items, head in (("LIST OF FIGURES", st2.figs_final, "Fig."), ("LIST OF TABLES", st2.tabs_final, "Table")):
        fh(title)
        doc.p(run_xml(head, bold=True) + run_xml("\t") + run_xml("Title", bold=True) + run_xml("\t") +
              run_xml("Page", bold=True), style="TocLine", tabs=[("left", 1000, "none"), ("right", W, "none")],
              after=160)
        for num, cap, bm in items:
            short = re.split(r"(?<=[a-z0-9)])\. ", cap)[0]
            doc.p(run_xml(num + "\t") + runs(short) + run_xml("\t") + field_xml(f"PAGEREF {bm} \\h", "0"),
                  style="TocLine", tabs=[("left", 1000, "none"), ("right", W - 10, "none")], ind_left=1000,
                  ind_hanging=1000, after=60)
    # abbreviations, symbols, units
    abbr = T.abbreviations_used(" ".join(" ".join(" ".join(b) for b in bl) for _, bl in body_files))
    fh("LIST OF ABBREVIATIONS")
    rows = [[run_xml("Abbreviation", bold=True), run_xml("Meaning", bold=True)]] + [[runs(a), runs(m)] for a, m in abbr]
    doc.table(rows, header_rows=1, widths=[2300, W - 2300], font_size=11, shade_header=False)
    fh("LIST OF SYMBOLS")
    rows = [[run_xml("Symbol", bold=True), run_xml("Meaning", bold=True), run_xml("Unit", bold=True)]] + \
           [[runs(a), runs(b), runs(c)] for a, b, c in T.SYMBOLS]
    doc.table(rows, header_rows=1, widths=[1700, W - 3100, 1400], font_size=11, shade_header=False)
    fh("INTERNATIONAL SYSTEM OF UNITS (SI UNITS)")
    rows = [[run_xml("Quantity", bold=True), run_xml("Unit", bold=True), run_xml("Symbol", bold=True)]] + \
           [[runs(a), runs(b), runs(c)] for a, b, c in T.SI_UNITS]
    doc.table(rows, header_rows=1, widths=[3600, 3300, W - 6900], font_size=11, shade_header=False)
    doc.section_break("front")
    # body (bookmark counter continues from the dry run's numbering: restart the counter so names match)
    st2.bm = 0
    st2.chapter = 0
    for _, blocks in body_files:
        for b in blocks:
            emit_block(doc, st2, b)
    out = OUT / "thesis_raw.docx"
    doc.save(str(out), final_section="main")
    stats = {"figures": len(st2.figs_final), "tables": len(st2.tabs_final), "toc_entries": len(st2.toc_final),
             "facts_used": len(F.FACTS)}
    (OUT / "build_stats.json").write_text(json.dumps(stats, indent=1), encoding="utf-8")
    F.write_sources(OUT / "facts_used.csv")
    if MISSING:
        print("MISSING cross-references:", sorted(MISSING))
    print("written", out, stats)


if __name__ == "__main__":
    main()
