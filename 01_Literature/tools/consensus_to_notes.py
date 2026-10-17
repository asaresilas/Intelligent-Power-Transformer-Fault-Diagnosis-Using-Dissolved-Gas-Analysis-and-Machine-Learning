"""Turns a saved Consensus research-thread JSON into a readable literature note (Markdown) and a CSV of papers.

Usage: python consensus_to_notes.py <thread.json> <out_stem>
Writes <out_stem>.md (synthesis + every cited paper with its verbatim snippets) and <out_stem>_papers.csv.
The snippets are the evidence used when a statement in the thesis is attributed to a paper.
"""
import csv
import json
import sys

src, stem = sys.argv[1], sys.argv[2]
d = json.load(open(src, encoding="utf-8"))
rows = []
md = [f"# Consensus thread {d['thread_id']}", "", f"URL: {d['url']}", ""]
for it in d["interactions"]:
    md += ["## Brief", "", it["input_message"], "", "## Synthesis (Consensus agent)", "", it.get("response", ""), "",
           "## Cited papers with verbatim snippets", ""]
    for c in it.get("citations", []):
        authors = "; ".join(c.get("authors") or [])
        md.append(f"### [{c['n']}] {c.get('title')}")
        md.append(f"- Authors: {authors}")
        md.append(f"- Year: {c.get('year')} | Journal: {c.get('journal')} | DOI: {c.get('doi')}")
        md.append(f"- Consensus: {c.get('url')}")
        for s in c.get("snippets", []):
            md.append(f"  - [{s.get('marker')}] ({s.get('section')}) \"{s.get('quote')}\"")
        md.append("")
        rows.append({"thread": d["thread_id"], "n": c["n"], "authors": authors, "year": c.get("year"),
                     "title": c.get("title"), "journal": c.get("journal"), "doi": c.get("doi"),
                     "consensus_url": c.get("url"), "n_snippets": len(c.get("snippets", []))})
open(stem + ".md", "w", encoding="utf-8").write("\n".join(md))
with open(stem + "_papers.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
    w.writeheader()
    w.writerows(rows)
print(len(rows), "papers")
