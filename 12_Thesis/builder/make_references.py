"""Builds the reference list (12_Thesis/source/06_refs.md) in the UMaT Harvard style and checks citations.

Entries come from 01_Literature/crossref_verified.csv (metadata of the DOI registration agency) or from the
MANUAL list below (standards, web pages, data sets and works without a DOI, each checked against the source or the
project register). The program:
  1. formats every cited entry: Surname, I. I., ... and Surname, I. (Year), "Title", Journal, Vol. x, No. y, pp. a - b.
  2. checks that every reference is cited in the chapters and that every (Name, Year) citation has an entry;
  3. writes 12_Thesis/build/citation_check.csv. Unmatched citations or unused entries stop the build.
"""
import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "12_Thesis" / "source"
OUT = ROOT / "12_Thesis" / "build"
CR = list(csv.DictReader(open(ROOT / "01_Literature" / "crossref_verified.csv", encoding="utf-8")))
CR = {r["key"]: r for r in CR}

# crossref keys used in the thesis, with any correction of the registry metadata (reason given)
USE = {
    "Rao2021": {}, "Adekunle2025": {}, "AlSakini2024": {}, "ZhangY2022": {}, "Das2023": {}, "Prasojo2023": {},
    "Hechifa2023": {}, "Suwarno2024": {}, "DladlaThango2025b": {"suffix": "b"}, "Abdelwahab2025": {},
    "Tanjim2026": {}, "Nkwambe2026": {}, "Dogan2026": {}, "Taha2021": {}, "WangL2021": {}, "LiJB2026": {},
    "Kashiwagi2025": {}, "Ali2023": {}, "DuvalPaulhiac2026": {}, "Bustamante2019": {}, "Wajid2023": {}, "Su2024": {},
    "Nanfak2021": {}, "RangelBessa2023": {}, "Manoj2023": {}, "Selim2025": {}, "Ward2021": {}, "MartinTenbohlen2026": {},
    "Jin2024": {}, "Susa2004": {}, "Aslam2021": {}, "ZhangL2023": {}, "Yao2024": {}, "Cui2025": {}, "Owusu2026": {},
    "DladlaThango2025a": {"suffix": "a"}, "Chen2025": {}, "Cheng2018": {}, "Ekojono2022": {}, "Tenbohlen2017": {},
    "Martin2017": {}, "Murugan2019": {}, "WangT2023": {}, "Ghoneim2016": {}, "Martin2014": {}, "WangX2024": {},
    "Duval2002": {}, "DuvaldePablo2001": {"authors": "Duval, M.; dePablo, A."},   # registry record misspells dePablo
    "Rogers1978": {}, "Kapoor2023": {}, "Breiman2001": {}, "ChenGuestrin2016": {"title": "XGBoost: A Scalable Tree Boosting System"},
    "Lundberg2020": {}, "VarmaSimon2006": {}, "NadeauBengio2003": {}, "Friedman1937": {}, "Cochran1950": {"page": "256-266"},
    "McNemar1947": {}, "Wilson1927": {}, "Cohen1960": {}, "Gorodkin2004": {},
    "Chow1970": {"authors": "Chow, C. K."}, "Mitchell2019": {}, "Strobl2008": {}, "LiuNocedal1989": {}, "Chawla2002": {},
    "Rajora2024": {}, "Manisha2022": {}, "Thurner2018": {}, "Firth1993": {"authors": "Firth, David"}, "KruskalWallis1952": {}, "Spearman1904": {"page": "72-101"}, "Fielding2022": {"authors": "Fielding, R.; Nottingham, M.; Reschke, J.", "container": "RFC 9110, STD 97, RFC Editor"},
}
# Cochran 1950 pages 256-266: register M28 (Crossref gives only the first page).

MANUAL = [
    # key, in-text name, year, formatted entry (UMaT Harvard), verification note
    ("IEC2007", "IEC", "2007", "IEC (2007), *Mineral oil-impregnated electrical equipment in service – Guide to the interpretation of dissolved and free gases analysis*, IEC 60599:1999+A1:2007, Edition 2.1, International Electrotechnical Commission, Geneva, Switzerland.", "register ST1/ST2"),
    ("IEC2018", "IEC", "2018", "IEC (2018), *Power transformers – Part 7: Loading guide for mineral-oil-immersed power transformers*, IEC 60076-7:2018, Edition 2.0, International Electrotechnical Commission, Geneva, Switzerland.", "register ST6"),
    ("IEEE2009", "IEEE", "2009", "IEEE (2009), *IEEE Guide for the Interpretation of Gases Generated in Oil-Immersed Transformers*, IEEE Std C57.104-2008, Institute of Electrical and Electronics Engineers, New York, USA.", "register ST5"),
    ("Pedregosa2011", "Pedregosa *et al.*", "2011", "Pedregosa, F., Varoquaux, G., Gramfort, A., Michel, V., Thirion, B., Grisel, O., Blondel, M., Prettenhofer, P., Weiss, R., Dubourg, V., Vanderplas, J., Passos, A., Cournapeau, D., Brucher, M., Perrot, M. and Duchesnay, E. (2011), \"Scikit-learn: Machine Learning in Python\", *Journal of Machine Learning Research*, Vol. 12, pp. 2825 – 2830.", "register M3"),
    ("LundbergLee2017", "Lundberg and Lee", "2017", "Lundberg, S. M. and Lee, S.-I. (2017), \"A Unified Approach to Interpreting Model Predictions\", *Advances in Neural Information Processing Systems 30 (NIPS 2017)*, Long Beach, USA, pp. 4765 – 4774.", "register M16 (pages confirmed on DBLP)"),
    ("Demsar2006", "Demšar", "2006", "Demšar, J. (2006), \"Statistical Comparisons of Classifiers over Multiple Data Sets\", *Journal of Machine Learning Research*, Vol. 7, pp. 1 – 30.", "register M26"),
    ("Holm1979", "Holm", "1979", "Holm, S. (1979), \"A Simple Sequentially Rejective Multiple Test Procedure\", *Scandinavian Journal of Statistics*, Vol. 6, No. 2, pp. 65 – 70.", "register M30"),
    ("Platt1999", "Platt", "1999", "Platt, J. C. (1999), \"Probabilistic Outputs for Support Vector Machines and Comparisons to Regularized Likelihood Methods\", In *Advances in Large Margin Classifiers*, Smola, A., Bartlett, P., Schölkopf, B. and Schuurmans, D. (eds.), MIT Press, Cambridge, USA, pp. 61 – 74.", "register M11"),
    ("Efron1993", "Efron and Tibshirani", "1993", "Efron, B. and Tibshirani, R. J. (1993), *An Introduction to the Bootstrap*, Chapman and Hall, New York, USA. DOI: 10.1007/978-1-4899-4541-9.", "register M20; Crossref book record"),
    ("NIST2015", "NIST", "2015", "NIST (2015), *Secure Hash Standard (SHS)*, FIPS PUB 180-4, National Institute of Standards and Technology, Gaithersburg, USA.", "register M1"),
    ("Moser2025", "Moser", "2025", "Moser, A. (2025), \"The Duval Triangle for Transformer Fault Diagnosis\", *HV Assets*, published 20 May 2025, updated 20 July 2025. Accessed: October 10, 2026.", "register P4 (secondary source)"),
    ("Dissanayake2026", "Dissanayake", "2026", "Dissanayake, T. (2026), \"DGA dataset\", *IEEE DataPort*, DOI: 10.21227/27vy-h479.", "register DS2-DS4"),
    ("Li2019", "Li", "2019", "Li, E. (2019), \"Dissolved gas data in transformer oil – Fault Diagnosis of Power Transformers with Membership Degree\", *IEEE DataPort*, DOI: 10.21227/h8g0-8z59.", "register DS5"),
    ("AduGyamfi2026", "Adu-Gyamfi", "2026", "Adu-Gyamfi, K. (2026), \"Dissolved Gas Analysis-Based Power Transformer Fault Diagnosis Using Random Forest: A Comparative Evaluation Against K-Nearest Neighbors, Support Vector Machine, and Artificial Neural Network Classifiers\", *engrXiv preprint*.", "register C3"),
    ("Anon2015", "Anon.", "2015", "Anon. (2015), \"Goal 7: Ensure access to affordable, reliable, sustainable and modern energy for all\", *United Nations, Department of Economic and Social Affairs – Sustainable Development*, https://sdgs.un.org/goals/goal7. Accessed: October 13, 2026.", "UN SDG page"),
    ("Anon2026", "Anon.", "2026", "Anon. (2026), \"GRIDCo technical challenge, transformer faults plunge Volta, Oti, Tema regions into darkness\", *Graphic Online*, 23 April 2026, https://www.graphic.com.gh/news/general-news/gridco-technical-challenge-transformer-faults-plunge-volta-oti-tema-regions-into-darkness.html. Accessed: October 13, 2026.", "fetched 13 Oct 2026"),
    ("Dotse2024", "Dotse", "2024", "Dotse, D. W. (2024), \"ECG's attribution of outages to overloaded transformers not true – PURC\", *Graphic Online*, 16 April 2024, https://graphic.com.gh/news/general-news/ecgs-attribution-of-outages-to-overloaded-transformers-not-true-purc.html. Accessed: October 13, 2026.", "fetched 13 Oct 2026"),
]


def initials(given):
    out = []
    for part in given.replace(".", ". ").split():
        sub = [s for s in part.split("-") if s]
        out.append("-".join(s[0].upper() + "." for s in sub))
    return " ".join(out)


def authors_list(s):
    res = []
    for a in [x.strip() for x in s.split(";") if x.strip()]:
        if "," in a:
            fam, giv = [x.strip() for x in a.split(",", 1)]
            res.append((fam, initials(giv)))
        else:
            res.append((a, ""))
    return res


def fmt_authors(au):
    names = [f"{f}, {i}" if i else f for f, i in au]
    if len(names) == 1:
        return names[0]
    return ", ".join(names[:-1]) + " and " + names[-1]


def intext(au):
    fam = [f for f, _ in au]
    if len(fam) == 1:
        return fam[0]
    if len(fam) == 2:
        return f"{fam[0]} and {fam[1]}"
    if len(fam) == 3:
        return f"{fam[0]}, {fam[1]} and {fam[2]}"
    return f"{fam[0]} *et al.*"


def fmt_entry(r, o):
    au = authors_list(o.get("authors", r["authors"]))
    year = o.get("year", r["year"]) + o.get("suffix", "")
    title = o.get("title", r["title"]).replace("&amp;", "&")
    cont = o.get("container", r["container"]).replace("&amp;", "&")
    page = o.get("page", r["page"])
    parts = [f"{fmt_authors(au)} ({year}), \"{title}\", *{cont}*"]
    if r["volume"]:
        parts.append(f"Vol. {r['volume']}")
    if r["issue"]:
        parts.append(f"No. {r['issue']}")
    if page and "-" in page:
        a, b = page.split("-", 1)
        parts.append(f"pp. {a} – {b}")
    elif r["article_number"] or page:
        parts.append(f"Article {r['article_number'] or page}")
    return ", ".join(parts) + f". DOI: {r['doi']}.", intext(au), year


def main():
    text = " ".join(p.read_text(encoding="utf-8") for p in sorted(SRC.glob("0[1-9]_*.md")))
    text += " " + (SRC / "00_front.md").read_text(encoding="utf-8")
    text += " " + (SRC / "11_appendices.md").read_text(encoding="utf-8")
    entries = []
    for k, o in USE.items():
        e, it, y = fmt_entry(CR[k], o)
        entries.append((k, it, y, e))
    for k, it, y, e, _ in MANUAL:
        entries.append((k, it, y, e))
    rows, unused = [], []
    for k, it, y, e in entries:
        pat = re.escape(it) + r"(?:,\s*|\s*\()" + re.escape(y) + r"(?![0-9a-z])"
        n = len(re.findall(pat, text))
        rows.append({"key": k, "in_text": f"{it}, {y}", "times_cited": n})
        if n == 0:
            unused.append(f"{it}, {y}")
    # citations in the text that match no entry
    known = {(it, y) for _, it, y, _ in entries}
    cites = set()
    for m in re.finditer(r"([A-Z][A-Za-zÀ-žğış\-']+(?: and [A-Z][A-Za-zÀ-žğış\-']+| \*et al\.\*|, [A-Z][A-Za-zÀ-žğış\-']+ and [A-Z][A-Za-zÀ-žğış\-']+)?)(?:,\s*|\s*\()((?:19|20)\d\d[a-z]?)(?![0-9])", text):
        cites.add((m.group(1), m.group(2)))
    unmatched = sorted(c for c in cites if c not in known and not any(c[0].endswith(k[0]) and c[1] == k[1] for k in known))
    OUT.mkdir(exist_ok=True)
    with open(OUT / "citation_check.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["key", "in_text", "times_cited"])
        w.writeheader()
        w.writerows(rows)
    def sort_key(e):
        return (re.sub(r"[^a-z]", "", e[3].lower().replace("ğ", "g").replace("š", "s"))[:40], e[2])
    lines = ["# REFERENCES", ""]
    for _, _, _, e in sorted(entries, key=sort_key):
        if any(e == x[3] for x in entries if f"{x[1]}, {x[2]}" in unused):
            continue
        lines += ["REF " + e, ""]
    (SRC / "10_refs.md").write_text("\n".join(lines), encoding="utf-8")
    print(f"{len(entries) - len(unused)} references written; unused entries: {unused}")
    print("citations without an entry:", unmatched)
    if "--strict" in sys.argv and (unused or unmatched):
        sys.exit(1)


if __name__ == "__main__":
    main()
