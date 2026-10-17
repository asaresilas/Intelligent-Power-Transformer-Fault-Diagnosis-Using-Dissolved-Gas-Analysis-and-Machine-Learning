@@ DECLARATION

I declare that this thesis is my own work. It is being submitted for the degree of Master of Philosophy in Electrical and Electronic Engineering in the University of Mines and Technology (UMaT), Tarkwa. It has not been submitted for any degree or examination in any other University.

&nbsp;

&nbsp;

……………………………………………………

(Signature of Candidate)

……… day of ……………………………, 2026

@@ ABSTRACT

Dissolved Gas Analysis (DGA) is the main early warning of incipient faults in oil-immersed power transformers, but its conventional interpretation methods often disagree or give no diagnosis. This thesis developed and evaluated an integrated MATLAB/Simulink–Python framework that produces machine-learning (ML) and conventional diagnoses from the same measured record and compares them statistically. A provenance-audited table of {{n_master}} published records with five gases was assembled. The Rogers ratio, IEC 60599 ratio and Duval Triangle 1 methods were implemented in MATLAB and independently in Python with identical answers. Five classifiers were compared by nested cross-validation, and a Random Forest on 18 engineered features was selected (macro-F1 {{cv_F4_random_forest}}) and tested once on three held-out sets. On the internal test set the model outperformed every conventional method (strict accuracy {{int_ml_strict}} against {{int_rog_strict}}–{{int_duv_strict}}). On the inspection-confirmed IEC TC 10 benchmark it was significantly more accurate than the Rogers method but not significantly different from IEC 60599 or the Duval Triangle ({{iec_ml_strict}} against {{iec_duv_strict}} for Duval), so the research hypothesis was not supported on the main benchmark. Disagreement between ML and the conventional methods was not concentrated near their decision boundaries. Without methane, four gases kept the loss of macro-F1 within 0.05, a panel no conventional method can interpret. A Simscape thermal model of a 40 MVA transformer met its 0.1 K verification tolerance, and a FastAPI service with a MATLAB dashboard reproduced the offline diagnoses for all {{n_heldout}} held-out records, with a 95th-percentile response time of {{int_p95}} ms. ML is therefore a useful complement to, not a replacement for, conventional DGA interpretation.

@@ DEDICATION

This work is dedicated to my family, for their love, patience and support.

@@ ACKNOWLEDGEMENTS

I am grateful to the Almighty God for the strength, health and guidance to complete this work.

My sincere thanks go to my supervisor, Prof. John Annan of the Department of Electrical and Electronic Engineering, University of Mines and Technology (UMaT), Tarkwa, for his guidance, encouragement and constructive criticism throughout the research.

I thank the authors who made their data publicly available, in particular M. Duval and A. dePablo for the IEC TC 10 database, T. Dissanayake and E. Li for the data sets published on IEEE DataPort, and the developers of the open-source software used in this work.

I also thank the lecturers and staff of the Department of Electrical and Electronic Engineering, my colleagues, and my family for their support during the study.
