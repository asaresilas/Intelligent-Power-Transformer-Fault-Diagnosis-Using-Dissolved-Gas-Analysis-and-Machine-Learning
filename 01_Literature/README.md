# 01 — Literature

**Purpose.** Build the evidence base for Chapter 2 and guarantee that every citation in the thesis and paper is real and says what we claim it says.

**Inputs.** Journal/conference papers, CIGRE brochures, systematic reviews; the 11 references already cited in Chapter 1 (to be re-verified).

**Outputs**
- `reference_register.csv` — one row per source: key, full citation, DOI/URL, date opened, verified (Y/N), claim it supports, thesis section.
- `review_matrix.csv` — per reviewed study: dataset, label origin, gases used, classes, models, validation scheme, leakage risk, reported accuracy, limitation.
- `papers/` — PDFs named `AuthorYear_shorttitle.pdf`.
- `gap_statement.md` — the research gap, written only from the review matrix.

**Procedure**
1. Search (IEEE Xplore, ScienceDirect, MDPI, Scopus/Google Scholar); log search strings and dates.
2. Open the DOI; confirm authors, year, title, journal, volume, pages against the publisher page; then add to the register.
3. Read and fill the review matrix; quote page numbers for any figure taken from a paper.
4. Novelty claims in `PROJECT_PLAN.md` §6 are checked against the matrix before they are written into the thesis.

**Acceptance criteria.** Zero register rows with `verified = N`; every in-text citation has a register row; every register row is cited.

**Feeds thesis.** Chapter 2; references list; Chapter 1 gap statement.
