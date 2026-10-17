"""Verifies candidate references against Crossref (the DOI registration agency's public API).

Input : 01_Literature/candidate_references.csv  (key, doi, query, note)
         - with a DOI: the record of that DOI is fetched;
         - without a DOI: the bibliographic query is searched and the best hit is returned for a human check.
Output: 01_Literature/crossref_verified.csv (one row per key with authors, year, title, container, volume,
        issue, pages/article number, DOI, publisher, type, match status) and crossref_raw/<key>.json.
Only the DOI or the query text is sent; nothing else leaves the computer.
"""
import csv
import json
import time
import urllib.parse
import urllib.request
from pathlib import Path

LIT = Path(__file__).resolve().parents[1]
RAW = LIT / "crossref_raw"
RAW.mkdir(exist_ok=True)
UA = {"User-Agent": "MPhil-thesis-reference-check/1.0 (UMaT; python urllib)"}


def get(url, tries=4):
    for k in range(tries):
        try:
            req = urllib.request.Request(url, headers=UA)
            with urllib.request.urlopen(req, timeout=40) as r:
                return json.loads(r.read().decode("utf-8"))
        except urllib.error.HTTPError:
            raise
        except Exception:  # noqa: BLE001 - network hiccup: wait and retry
            if k == tries - 1:
                raise
            time.sleep(3 * (k + 1))


def norm(rec, key, status):
    au = rec.get("author", [])
    authors = "; ".join(f"{a.get('family', a.get('name', ''))}, {a.get('given', '')}".strip(", ") for a in au)
    dp = (rec.get("published-print") or rec.get("published-online") or rec.get("issued") or {}).get("date-parts", [[None]])
    year = dp[0][0] if dp and dp[0] else None
    return {"key": key, "status": status, "authors": authors, "year": year,
            "title": " ".join(rec.get("title", [""])), "container": " ".join(rec.get("container-title", [""])),
            "volume": rec.get("volume", ""), "issue": rec.get("issue", ""), "page": rec.get("page", ""),
            "article_number": rec.get("article-number", ""), "doi": rec.get("DOI", ""),
            "publisher": rec.get("publisher", ""), "type": rec.get("type", "")}


def main():
    rows = list(csv.DictReader(open(LIT / "candidate_references.csv", encoding="utf-8")))
    done = {}
    prev = LIT / "crossref_verified.csv"
    if prev.exists():  # keep earlier successful look-ups; only retry missing or failed keys
        for o in csv.DictReader(open(prev, encoding="utf-8")):
            if o["status"].startswith(("DOI", "query", "NOT FOUND")):
                done[o["key"]] = o
    out = []
    for r in rows:
        key, doi, q = r["key"], r["doi"].strip(), r["query"].strip()
        if key in done and (done[key]["doi"].lower() == doi.lower() or not doi):
            out.append(done[key])
            continue
        try:
            if doi:
                d = get("https://api.crossref.org/works/" + urllib.parse.quote(doi))
                rec = d["message"]
                status = "DOI resolved"
            else:
                d = get("https://api.crossref.org/works?rows=1&query.bibliographic=" + urllib.parse.quote(q))
                items = d["message"]["items"]
                if not items:
                    out.append({"key": key, "status": "NOT FOUND"})
                    continue
                rec = items[0]
                status = "query hit - check"
            (RAW / f"{key}.json").write_text(json.dumps(rec, indent=1), encoding="utf-8")
            out.append(norm(rec, key, status))
        except Exception as e:  # noqa: BLE001 - report and continue
            out.append({"key": key, "status": f"ERROR {type(e).__name__}: {e}"})
        time.sleep(0.4)
    cols = ["key", "status", "authors", "year", "title", "container", "volume", "issue", "page", "article_number",
            "doi", "publisher", "type"]
    with open(LIT / "crossref_verified.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=cols)
        w.writeheader()
        for o in out:
            w.writerow({c: o.get(c, "") for c in cols})
    print(len(out), "checked;", sum(1 for o in out if o.get("status", "").startswith(("DOI", "query"))), "found")


if __name__ == "__main__":
    main()
