# 12 — Thesis

**Purpose.** The MPhil thesis in the UMaT format (`1654175806890_UMaT Thesis Guide.pdf`). `FINAL.pdf` is a sample UMaT thesis by another candidate, used only for layout - never copy its text.

**Current draft:** `Thesis_Draft_v3.1.docx` (17 Oct 2026, 9 chapters, 138 pages; decision D41; earlier drafts v1, v2, v2.1, v3 are kept locally only). The two PDFs named above are local reference material and are not part of the repository copy.

**How it is built**
1. Edit the text in `source/` (`00_front.md` front matter, `01_ch1.md` … `09_ch9.md`, `11_appendices.md`; `meta.json` = title page). `10_refs.md` is generated - do not edit. `source_v1/` and `source_backup/` hold earlier text.
2. `06_Python_ML\.venv\Scripts\python.exe -I 12_Thesis\builder\make_references.py` (reference list + citation check)
3. `06_Python_ML\.venv\Scripts\python.exe -I 12_Thesis\builder\build_thesis.py` (writes `build/thesis_raw.docx`; stops on an unknown fact or cross-reference; set THESIS_DRAFT=1 to allow [??])
4. `powershell -ExecutionPolicy Bypass -File 12_Thesis\builder\finish_thesis.ps1 -raw <raw> -out <final>` (Word equations and page numbers)

**Source syntax:** `# Chapter`, `## / ###` numbered headings, `![caption](path){#fig:id width=15}`, `[[TABLE:name]] {#tab:id}`, pipe tables with `Table: caption {#tab:id}`, ` UnicodeMath  {#eq:id}` + `where:` / `: symbol = meaning`, lists `- ` (a., b.) / `* ` / `1. `, `@fig:id` cross-references, `{{fact}}` values (builder/facts.py), `*italic*`, `**bold**`, `~sub~`, `^sup^`.

**Rules.** Every number in Chapter 4/5 comes from a result file (facts.py, tables.py); every reference is verified (01_Literature/crossref_verified.csv or the register) and cited; no TO VERIFY in the text — unverifiable items are stated as limitations.