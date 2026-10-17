# Step 31E report - Study 2 decision rules

```
{
 "status": "EXPLORATORY - IEC TC 10 and Li 2019 were already seen in Steps 22-31",
 "primary": {
  "rule1_pooling_helps": {
   "per_source": {
    "DISTEST": false,
    "IECTC10": false,
    "LI2019": false
   },
   "count": 0,
   "needed": 2,
   "met": false
  },
  "rule2_hybrid_helps": {
   "per_source": {
    "DISTRAIN": false,
    "DISTEST": false,
    "IECTC10": false,
    "LI2019": false
   },
   "count": 0,
   "needed": 2,
   "met": false
  },
  "rule3_reject_option_competitive": {
   "strict_reading_lower_limit_ge_0": {
    "per_source": {
     "DISTEST": true,
     "IECTC10": false,
     "LI2019": true
    },
    "count": 2,
    "met": true
   },
   "lenient_reading_point_ge_0": {
    "per_source": {
     "DISTEST": true,
     "IECTC10": true,
     "LI2019": true
    },
    "count": 3,
    "met": true
   },
   "readings_agree": true
  },
  "note_hybrid_significantly_worse_on": [
   "DISTRAIN"
  ]
 },
 "equal_source_weight": {
  "rule1_pooling_helps": {
   "per_source": {
    "DISTEST": false,
    "IECTC10": true,
    "LI2019": false
   },
   "count": 1,
   "needed": 2,
   "met": false
  },
  "rule2_hybrid_helps": {
   "per_source": {
    "DISTRAIN": false,
    "DISTEST": false,
    "IECTC10": false,
    "LI2019": true
   },
   "count": 1,
   "needed": 2,
   "met": false
  },
  "rule3_reject_option_competitive": {
   "strict_reading_lower_limit_ge_0": {
    "per_source": {
     "DISTEST": true,
     "IECTC10": true,
     "LI2019": true
    },
    "count": 3,
    "met": true
   },
   "lenient_reading_point_ge_0": {
    "per_source": {
     "DISTEST": true,
     "IECTC10": true,
     "LI2019": true
    },
    "count": 3,
    "met": true
   },
   "readings_agree": true
  },
  "note_hybrid_significantly_worse_on": []
 },
 "iec_all": {
  "rule1_pooling_helps": {
   "per_source": {
    "DISTEST": false,
    "IECTC10": true,
    "LI2019": true
   },
   "count": 2,
   "needed": 2,
   "met": true
  },
  "rule2_hybrid_helps": {
   "per_source": {
    "DISTRAIN": true,
    "DISTEST": false,
    "IECTC10": false,
    "LI2019": false
   },
   "count": 1,
   "needed": 2,
   "met": false
  },
  "rule3_reject_option_competitive": {
   "strict_reading_lower_limit_ge_0": {
    "per_source": {
     "DISTEST": true,
     "IECTC10": true,
     "LI2019": true
    },
    "count": 3,
    "met": true
   },
   "lenient_reading_point_ge_0": {
    "per_source": {
     "DISTEST": true,
     "IECTC10": true,
     "LI2019": true
    },
    "count": 3,
    "met": true
   },
   "readings_agree": true
  },
  "note_hybrid_significantly_worse_on": []
 }
}
```
