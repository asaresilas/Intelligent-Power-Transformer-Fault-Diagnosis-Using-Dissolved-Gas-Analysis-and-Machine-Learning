# Study 2 - search for a fresh confirmation data set (roadmap Step 31F)

Searched: 12 October 2026, by Claude Code, using web search and the data sets' own landing pages only (no files downloaded).
Purpose (Study 2 protocol, S2-Q4; decision D28): find a legitimately licensed set of DGA cases whose fault was confirmed by
inspection, that has not been used in this project (Dissanayake training/unseen files, IEC TC 10, Li 2019), on which the
exploratory Study 2 result (the reject option) could be confirmed. Rules: legitimate sources only; licence stated; no pirated or
unlicensed copies; overlap with the data already used must be checked before any use.

## Result

**No candidate meets all requirements today.** None combines (a) a stated open licence, (b) inspection-confirmed labels with a
documented method, (c) enough records for a confirmation test, and (d) a checkable absence of overlap with the data already used.

## Candidates found

| # | Data set | Licence / access | Size | How labels were set | Overlap risk | Assessment |
|---|---|---|---|---|---|---|
| 1 | Shutenko, O. and Kulyk, O. (2023) "DGA results for 25 transformers", Mendeley Data, v1, doi:10.17632/x22y4s9fks.1 (Ukraine; NTU "KhPI" with laboratories and energy companies) | CC BY 4.0 (stated on page) | 25 transformers, five gases | "identified fault type" - method not stated | unknown until the file is checked | Licence acceptable; labelling method must be confirmed with the authors; too small for a confirmation test on its own (supplementary only) |
| 2 | Montero Jimenez, J. J. and Gomez-Ramirez, G. A. (2026) "Power transformer data for fault diagnosis", Mendeley Data, v2, doi:10.17632/98f4z3f8tx.2 (Tecnologico de Costa Rica) | CC BY 4.0 (stated on page) | not stated | not described; files not listed on the page | unknown | Needs a look at the files before any judgement |
| 3 | Adu-Gyamfi, K. (2026) DGA-based transformer fault diagnosis using Random Forest, engrXiv preprint, doi:10.31224/8150 (KNUST, Ghana) | paper CC BY 4.0; data availability not stated | 589 "field-verified" records, six IEC 60599 classes | "field-verified" - method not stated; source not named | unknown (multi-source data may include IEC TC 10) | Most promising lead for Ghana; contact the author for source, verification method, licence and overlap |
| 4 | Li, E. "Dissolved gas data in transformer oil - Fault Diagnosis of Power Transformers with Membership Degree", IEEE DataPort, doi:10.21227/h8g0-8z59 | subscription required | not stated | not documented (question on the page unanswered) | unknown | Not suitable: access and label origin unclear |
| 5 | Liu, H. / Abdo, A. "Dynamic assessment and prediction of equipment status in 220kV substations ...", IEEE DataPort, doi:10.21227/jve3-nh57 | subscription required | 177 samples "collected from literatures" | not documented | high (literature cases often repeat IEC TC 10) | Not suitable |
| 6 | Arias Velasquez, R. M. (2024) "A comprehensive analysis for wind turbine transformer and its limits in the dissolved gas evaluation", Heliyon 10(20) e39449, doi:10.1016/j.heliyon.2024.e39449 | CC BY 4.0 | about 4 810 wind-park samples as summary statistics only | no per-case inspected table | - | Not suitable (no per-case data) |
| 7 | CIGRE Technical Brochure 771 (2019) "Advances in DGA interpretation", JWG D1/A2.47 | brochure free to non-members after three years (publisher page); underlying data not released | the brochure reportedly draws on about 330 000 DGA results (industry summary - TO VERIFY in the brochure) | - | - | Not a data set; useful as a reference |

## Recommended route to a real confirmation set

1. **Local inspection records (strongest option).** Ask Ghanaian utilities (for example GRIDCo, ECG, VRA) through the supervisor, Prof. J. Annan, for DGA results of transformers whose fault was later confirmed by inspection or repair records, under a data-sharing agreement and with university ethics approval. A draft request letter already exists (`00_Project_Admin/Dataset_Request_Letter_Prof_Annan.docx`).
2. **Contact the KNUST author (candidate 3)** about the source, verification method, licence and overlap of the 589 records.
3. **Contact the Ukrainian authors (candidate 1)** about how the fault types were identified; if by inspection, use the 25 records as a small supplementary check only.

Any new data must pass the project's checks before use: licence recorded in the register, SHA-256, overlap check against the 827 records already used (exact and near-duplicate), label mapping, and a written plan fixed before the model is applied.

## Sources (accessed 12 October 2026)
- https://data.mendeley.com/datasets/x22y4s9fks/1
- https://data.mendeley.com/datasets/98f4z3f8tx/2
- https://engrxiv.org/preprint/view/8150
- https://ieee-dataport.org/documents/dissolved-gas-data-transformer-oil-fault-diagnosis-power-transformers-membership-degree
- https://ieee-dataport.org/node/2025
- https://pmc.ncbi.nlm.nih.gov/articles/PMC11532846/
- https://www.e-cigre.org/publication/771-advances-in-dga-interpretation
