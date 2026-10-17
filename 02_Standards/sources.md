# Step 12 — Sources of the standards tables (accessed 10 October 2026)

All sources were obtained legitimately: official free previews published by the standards distributor iTeh
(standards.iteh.ai) or open-access papers (Creative Commons). No full standard was copied, and none is stored in
this folder; only the limits needed for the implementation are transcribed.

## Primary sources (official previews of the standard itself)

| Ref | Document | What it gave us | Where to get it |
|---|---|---|---|
| P1 | IEC 60599:1999+A1:2007 (Edition 2.1, consolidated), official preview, 14 pages | Table 2 "DGA interpretation table" (p.11) with notes and footnotes; Table 3 "Simplified scheme" (p.12); fault definitions 5.2 | https://cdn.standards.iteh.ai/samples/4337/c70dd99304d048488f7e85c43d330fa8/IEC-60599-1999.pdf |
| P2 | IEC 60599:1999/AMD1:2007, official preview, 6 pages | Table A.2 "Ranges of 90 % typical gas concentration values observed in power transformers" (AMD1 p.3) and the Annex A WARNING | iTeh preview of IEC 60599:1999/AMD1:2007 |
| P3 | IEC 60599:2015 (Edition 3.0) REDLINE, official preview, 14 pages | Foreword list of significant technical changes vs 2007: 5.5, 6.1, 7, 8, 9, 10, A.2.6, A.3, A.7 revised; 4.3 added; Fig. 1 revised; Fig. B.4 added. Clause 5.4 (ratio table) and A.2.4 (Table A.2) are NOT in the list. Contents: Table 1 p.15, Table A.2 p.27, Fig. B.3 p.39 "Duval's triangle 1" | https://cdn.standards.iteh.ai/samples/21171/e1abf3a067164526a7c3e82c03654ee7/IEC-60599-2015.pdf |
| P4 | IEC 60599:2022 (Edition 4.0), IEC webstore page and official preview (read earlier in this step) | Current edition; changes vs 2015 only in A.3 and A.5 (as recorded in the session summary); Table 1 p.14, Table A.2 p.26, Fig. B.3 p.37 | webstore.iec.ch (CHF 260 for the full text) |

## Secondary sources (open access, used for agreement checks and where no primary source was available)

| Ref | Source | Licence | Used for |
|---|---|---|---|
| S1 | Rangel Bessa, A., Farias Fardin, J., Marques Ciarelli, P., Frizera Encarnação, L. (2023) "Conventional Dissolved Gases Analysis in Power Transformers: Review", Energies 16:7219, doi:10.3390/en16217219 | CC BY | Table 6 agrees with P1 Table 2; Table 4 = Rogers version A |
| S2 | Aciu, A.-M., Nicola, C.-I., Nicola, M., Nițu, M.-C. (2021) "Complementary Analysis for DGA Based on Duval Methods and Furan Compounds Using Artificial Neural Networks", Energies 14:588, doi:10.3390/en14030588 | CC BY | Table 4 agrees with P1 Table 2; Table 3 = Rogers version B; Tables 12, 14, 16 = Duval Triangle 1 worked examples |
| S3 | Moser, A. (2025, updated 20 July 2025) "The Duval Triangle for Transformer Fault Diagnosis", HV Assets, Table 1; cites IEEE Std C57.104-2019 clause 6.2.3 | web article (not peer reviewed) | Duval Triangle 1 zone limits |
| S4 | Manisha, Kaur, K., Sharma, N.K., Singh, J., Bhalla, D. (2022) "Performance Assessment of IEEE/IEC Method and Duval Triangle technique for Transformer Incipient Fault Diagnosis", IOP Conf. Ser.: Mater. Sci. Eng. 1228:012027, doi:10.1088/1757-899X/1228/1/012027 | CC BY 3.0 | Figure 2 boundary labels (98, 20, 4, 13, 23, 40, 50, 29, 15) agree with S3; Tables 4 and 6 = 35 worked Duval examples on IEC TC 10 data |
| S5 | Duval, M., dePablo, A. (2001) IEEE Electrical Insulation Magazine 17(2):31–41 (the user's own copy, already used in Step 5) | publisher copyright | Annex 2: IEC 60599:1999 typical-value ranges (context only; superseded by P2) |

## Added 11 October 2026

| Ref | Document | What it gave us | Status |
|---|---|---|---|
| P5 (register ST5) | IEEE Std C57.104-2008, IEEE Guide for the Interpretation of Gases Generated in Oil-Immersed Transformers (published 2 Feb 2009) | Table 6 Rogers ratios (p.16) -> rogers_ratio_table.csv; Table 1 Condition 1 limits (p.10) -> ieee_condition1_limits.csv; Figure 2 worked example (p.7) -> worked_examples.csv | Copy supplied by the researcher; stamped as sold to another organisation ("Not for Resale"); not stored in the project. TO VERIFY against a licensed copy before submission |

The standard showed that both secondary Rogers tables contain an error (Rangel Bessa 2023: arcing C2H2/C2H4; Aciu 2021:
C2H4/C2H6 of the two lower-temperature thermal cases). They are kept, marked superseded, in `rogers_secondary_versions.csv`.

## Still needed (primary)

1. IEC 60599:2022 full text — to confirm that Table 1, Table A.2 and Figure B.3 are unchanged (purchase CHF 260 from IEC, or through the UMaT library / supervisor).
2. IEEE Std C57.104-2019 — clause 6.2.3 (Duval Triangle 1 zones) and, if present, the Rogers table; or IEEE Std C57.104-2008 for the Rogers ratio table (IEEE Xplore through the UMaT library).
