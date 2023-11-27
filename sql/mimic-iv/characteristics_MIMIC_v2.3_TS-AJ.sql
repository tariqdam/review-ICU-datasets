-- Version 2.3

-- Date Oct 29, 2023

--CREATE OR REPLACE TABLE `protean-chassis-368116.my_MIMIC.dummy` AS

-- v2.3: fix los by adding +1

WITH

ICU_unique_patients AS (
    SELECT 'ICU_unique_patients' as parameter,
    COUNT (DISTINCT subject_id) as value
    FROM `physionet-data.mimiciv_icu.icustays`
),

-- ICU_unique_admissions AS( -- todo use stay_id from icu table
--   SELECT 'ICU_unique_admissions' as parameter,
--
-- ),

overall_unique_patients AS (
    SELECT 'overall_unique_patients' as parameter,
            COUNT (DISTINCT subject_id) as value
    FROM `physionet-data.mimiciv_hosp.admissions`
),

unique_admissions AS (
    SELECT 'unique_admissions' as parameter,
            COUNT (DISTINCT hadm_id) as value
    FROM `physionet-data.mimiciv_hosp.admissions`
),


ICU_Admissions_Proportions AS (
      SELECT 
        'male gender' as parameter_malegender,
        COUNT(CASE WHEN gender="M" THEN 1 END) AS value_gender,
        '28d mortality' as parameter_28dm,
        COUNT(CASE WHEN (TIMESTAMP_DIFF(dod, icu_outtime, DAY) <= 28 ) THEN 1 END) AS value_28dm,
        'in_hospital mortality' as parameter_inhospm,
        -- potential error: 26 patients -> discharged (home, SNF, hospice) and died afterwards, but all within 24h
        COUNT(CASE WHEN (TIMESTAMP_DIFF(dod, dischtime, DAY) = 0 ) THEN 1 END) AS value_inhospm,
        '1-year mortality' as parameter_1ym,
        COUNT(CASE WHEN (TIMESTAMP_DIFF(dod, dischtime, DAY) > 0 ) THEN 1 END) AS value_1ym,
        'ICU_mortality' as parameter_icu_mort,
        COUNT(CASE WHEN dod BETWEEN icu_intime AND icu_outtime THEN 1 END) AS value_icu_mort,
        'race white' as parameter_race_white,
        COUNT(CASE WHEN REGEXP_CONTAINS(race, r'^(WHITE|PORT)') THEN 1 END) AS value_race_white,
        'race african-american' as parameter_race_aa,
        COUNT(CASE WHEN REGEXP_CONTAINS(race, r'^(BLACK)') THEN 1 END) AS value_race_aa,
        'race other-unkown' as parameter_race_other,
        COUNT(CASE WHEN REGEXP_CONTAINS(race, r'^(BLACK|WHITE|PORT)') THEN NULL ELSE 1 END) AS value_race_other,
      -- potential error: 
      -- race can change between admissions (if pts not able to respond -> other)

      FROM `physionet-data.mimiciv_derived.icustay_detail` al
      WHERE admission_age >= 18
      -- potential error: age > 18 or age >= 18?
      -- switched from subject_id to stay_id as common ground unit
),


Comorbidities AS (
    SELECT 'comorbidities recorded' AS parameter,
    COUNT(DISTINCT hos.hadm_id) AS value
    FROM `physionet-data.mimiciv_hosp.diagnoses_icd` AS hos
    INNER JOIN `physionet-data.mimiciv_icu.icustays` AS icu
    ON hos.hadm_id = icu.hadm_id
),

Severity AS (
    SELECT 
    'severity SOFA recorded' AS parameter_sofa,
    'severity OASIS recorded' AS parameter_oasis,
    'severity APACHE III recorded' AS parameter_apsiii,
    COUNT(DISTINCT sofa.stay_id) AS value_sofa,
    COUNT(DISTINCT oasis.stay_id) AS value_oasis,
    COUNT(DISTINCT aps.stay_id) AS value_apsiii,
    -- note: all, apsiii, SOFA and OASIS have no missings (imputing best case)
    
    'surgery admission' as parameter_surgery,
    COUNT(CASE WHEN oasis.electivesurgery = 1 THEN 1 END) as value_surgery,
    
    FROM `physionet-data.mimiciv_derived.first_day_sofa` AS sofa
    INNER JOIN `physionet-data.mimiciv_derived.oasis` AS oasis
    ON sofa.stay_id = oasis.stay_id
    INNER JOIN `physionet-data.mimiciv_derived.apsiii` AS aps
    ON sofa.stay_id = aps.stay_id
),

Admission_Reason AS (
    SELECT 
    'elective admission' as parameter_elective,
    COUNT(CASE WHEN admission_type="ELECTIVE" THEN 1 END) as value_elective,
    'non-elective admission' as parameter_nonelective,
    COUNT(CASE WHEN admission_type!="ELECTIVE" THEN 1 END) as value_nonelective,
    -- note: elective surgery from OASIS as very reliable
    FROM `physionet-data.mimiciv_hosp.admissions` AS adm
    INNER JOIN `physionet-data.mimiciv_icu.icustays` AS icu
    ON adm.hadm_id = icu.hadm_id
),

CRRT_Usage AS (
    SELECT 'crrt_usage' AS parameter,
            COUNT(DISTINCT stay_id) AS value
    FROM `physionet-data.mimiciv_derived.rrt`
    WHERE dialysis_active = 1
    AND dialysis_type LIKE "C%"
    -- potential error: now considering only continuous forms of RRT, before all (IHD, peritoneal)
),

ECMO_Usage AS (
    SELECT 'ecmo_usage' AS parameter,
            COUNT(DISTINCT stay_id) AS value
    FROM `physionet-data.mimiciv_icu.chartevents` AS chart

    INNER JOIN (
        SELECT itemid, label
        FROM `physionet-data.mimiciv_icu.d_items`
        WHERE label LIKE "%ECMO%"
    -- potential error: before "ECMO" ignored many labels with ECMO, now more cases
    ) AS item
    ON item.itemid = chart.itemid
),

Vasopressor_Usage AS (
    SELECT 'vasopressor_use_icustay' AS parameter,
            COUNT(DISTINCT stay_id) AS value
    FROM `physionet-data.mimiciv_derived.vasoactive_agent` AS vaso
    -- potential error: 
    -- includes dopamine, epinephrine, norepinephrine, phenylephrine, vasopressin, dobutamine, milrinone
    -- not included as rarly used isoprenaline & ATII, terlipressine not available in US
),

Mechanical_Ventilation_Usage AS (
    SELECT     
    'invasive vent' as parameter_inv_vent,
    COUNT(CASE WHEN ventilation_status IN ('InvasiveVent', 'Tracheostomy') THEN 1 END) as value_inv_vent,
    'non-invasive vent' as parameter_noninv_vent,
    COUNT(CASE WHEN ventilation_status IN ('InvasiveVent', 'Tracheostomy') THEN NULL ELSE 1 END) as value_noninv_vent,

    FROM `physionet-data.mimiciv_derived.ventilation` AS vent
),

-- chest_xrays AS (
--     SELECT  'chest xray' AS parameter,
--             COUNT(DISTINCT study_id) AS value
--     FROM `physionet-data.mimic_cxr.study_list` AS cxr
--
--     RIGHT JOIN `physionet-data.mimiciv_derived.icustay_detail` AS icu
--     ON cxr.subject_id = icu.subject_id
--     WHERE icu.subject_id IS NOT NULL
--         AND cxr.study_id IS NOT NULL
--     -- potential error: only includes chest x-rays
-- ),

-- echos AS (
--     SELECT  'echo' AS parameter,
--             COUNT(DISTINCT study_id) AS value
--     FROM `lcp-consortium.mimic_echo.echo-record-list` AS tte
--     -- potential error: change table location after lifting of embargo Jan 17, 2024
--     -- only includes anchor_years 2017-2019
--     -- The echos in v0.1 are only a subset of all of the available echos in this date range (extracted at random)
--     -- We pulled all echos for a given patient but didn’t pull for all of the patients.
--     -- The echos can be associated with an ICU, ED, or outpatient visit. Therefore right join with icustay_detail
--
--     RIGHT JOIN `physionet-data.mimiciv_derived.icustay_detail` AS icu
--     ON tte.subject_id = icu.subject_id
--     WHERE icu.subject_id IS NOT NULL
--         AND tte.study_id IS NOT NULL
-- ),

-- Vital signs
resp AS (
    SELECT resp.stay_id,
            "resp_rate_hr" AS parameter,
            SAFE_DIVIDE(COUNT(resp_rate), AVG(los_icu*24)) AS value, 
            FROM `physionet-data.mimiciv_derived.vitalsign` AS resp
            LEFT JOIN (
                SELECT icu.stay_id, icu.los_icu
                FROM `physionet-data.mimiciv_derived.icustay_detail` AS icu
            ) AS icu
            ON resp.stay_id = icu.stay_id
            GROUP BY stay_id
),
    
heart AS (
    SELECT heart.stay_id,
           "heart_rate_hr" AS parameter,
           SAFE_DIVIDE(COUNT(heart_rate), AVG(los_icu*24+1)) AS value
    FROM `physionet-data.mimiciv_derived.vitalsign` AS heart
    LEFT JOIN (
        SELECT icu.stay_id, icu.los_icu
        FROM `physionet-data.mimiciv_derived.icustay_detail` AS icu
    ) AS icu
    ON heart.stay_id = icu.stay_id
    GROUP BY stay_id
),

spo AS (
    SELECT spo.stay_id,
           "spo2_hr" AS parameter,
           SAFE_DIVIDE(COUNT(spo2), AVG(los_icu*24+1)) AS value
    FROM `physionet-data.mimiciv_derived.vitalsign` AS spo
    LEFT JOIN (
        SELECT icu.stay_id, icu.los_icu
        FROM `physionet-data.mimiciv_derived.icustay_detail` AS icu
    ) AS icu
    ON spo.stay_id = icu.stay_id
    GROUP BY stay_id
),

sbp AS (
    SELECT sbp.stay_id,
           "sbp_hr" AS parameter,
           SAFE_DIVIDE(COUNT(sbp), AVG(los_icu*24+1)) AS value
    FROM `physionet-data.mimiciv_derived.vitalsign` AS sbp
    LEFT JOIN (
        SELECT icu.stay_id, icu.los_icu
        FROM `physionet-data.mimiciv_derived.icustay_detail` AS icu
    ) AS icu
    ON sbp.stay_id = icu.stay_id
    GROUP BY stay_id
),

-- Ventilator Setting
peep AS (
    SELECT vent.stay_id,
           "peep_hr" AS parameter,
           SAFE_DIVIDE(COUNT(vent.peep), AVG(los_icu*24+1)) AS value
    FROM `physionet-data.mimiciv_derived.ventilator_setting` AS vent
    LEFT JOIN (
        SELECT icu.stay_id, icu.los_icu
        FROM `physionet-data.mimiciv_derived.icustay_detail` AS icu
    ) AS icu
    ON vent.stay_id = icu.stay_id
    GROUP BY stay_id
),

-- Chart Events
etco AS (
    SELECT chart.stay_id,
           "etco2_hr" AS parameter,
           SAFE_DIVIDE(
            COUNT(CASE WHEN itemid IN (228640,228641) THEN chart.valuenum ELSE NULL END),
            AVG(los_icu*24)) AS value
    FROM `physionet-data.mimiciv_icu.chartevents` AS chart
    LEFT JOIN (
        SELECT icu.stay_id, icu.los_icu
        FROM `physionet-data.mimiciv_derived.icustay_detail` AS icu
    ) AS icu
    ON chart.stay_id = icu.stay_id
    GROUP BY stay_id
),

cardiac AS (
    SELECT chart.stay_id,
           "cardiac_output_hr" AS parameter,
           SAFE_DIVIDE(
            COUNT(CASE WHEN itemid IN (228176, 228178, 228189, 228369, 229897, 224842, 227543, 226858) 
            THEN chart.valuenum ELSE NULL END),
            AVG(los_icu*24+1)) AS value
            -- potential error: also accounts for tandem heart (228189) and impella (229897)
    FROM `physionet-data.mimiciv_icu.chartevents` AS chart
    LEFT JOIN (
        SELECT icu.stay_id, icu.los_icu
        FROM `physionet-data.mimiciv_derived.icustay_detail` AS icu
    ) AS icu
    ON chart.stay_id = icu.stay_id
    GROUP BY stay_id
),

-- Blood Gas (bg)
fio2 AS (
    SELECT icu.stay_id,
           "fio2_hr" AS parameter,
           SAFE_DIVIDE(COUNT(bg.fio2+chart.fio2), AVG(los_icu*24+1)) AS value
        FROM `physionet-data.mimiciv_derived.icustay_detail` AS icu
    RIGHT JOIN (
        SELECT bg.hadm_id, bg.fio2
        FROM `physionet-data.mimiciv_derived.bg` AS bg
    ) AS bg
    ON bg.hadm_id = icu.hadm_id
    -- get data from chartevents as well
    RIGHT JOIN (
        SELECT stay_id, 
        CASE WHEN itemid IN (229280, 229841, 229238, 229239, 226754, 227009, 227010) THEN 1 ELSE NULL END AS fio2
        FROM `physionet-data.mimiciv_icu.chartevents` AS chart
        WHERE itemid IN (229280, 229841, 229238, 229239, 226754, 227009, 227010)
        -- FiO2 from Chartevents
    ) AS chart
    ON icu.stay_id = chart.stay_id
    WHERE icu.stay_id IS NOT NULL
    -- ensuring no data from outside ICU is included
    GROUP BY stay_id
),

po2 AS (
    SELECT icu.stay_id,
            "po2_d" AS parameter,
           SAFE_DIVIDE(COUNT(bg.po2), AVG(los_icu+1)) AS value
    FROM `physionet-data.mimiciv_derived.bg` AS bg
    LEFT JOIN (
        SELECT icu.stay_id, icu.hadm_id, icu.los_icu
        FROM `physionet-data.mimiciv_derived.icustay_detail` AS icu
    ) AS icu
    ON bg.hadm_id = icu.hadm_id
    WHERE icu.stay_id IS NOT NULL
    -- ensuring no data from outside ICU is included
    GROUP BY stay_id
),

lact AS (
    SELECT icu.stay_id,
            "lactate_d" AS parameter,
           SAFE_DIVIDE(COUNT(bg.lactate), AVG(los_icu+1)) AS value
    FROM `physionet-data.mimiciv_derived.bg` AS bg
    LEFT JOIN (
        SELECT icu.stay_id, icu.hadm_id, icu.los_icu
        FROM `physionet-data.mimiciv_derived.icustay_detail` AS icu
    ) AS icu
    ON bg.hadm_id = icu.hadm_id
    WHERE icu.stay_id IS NOT NULL
    -- ensuring no data from outside ICU is included
    GROUP BY stay_id
),

-- Labevents (lab)
hemog AS (
    SELECT icu.stay_id,
           "hemoglobin_d" AS parameter,
           SAFE_DIVIDE(
            COUNT(CASE WHEN itemid IN (50811, 50855, 51640, 51222, 52129, 52157) 
            THEN 1 ELSE NULL END),
            AVG(los_icu+1)) AS value
    FROM `physionet-data.mimiciv_hosp.labevents` AS lab
    RIGHT JOIN (
        SELECT icu.stay_id, icu.hadm_id, icu.los_icu
        FROM `physionet-data.mimiciv_derived.icustay_detail` AS icu
    ) AS icu
    ON lab.hadm_id = icu.hadm_id
    WHERE valuenum IS NOT NULL AND valuenum >0
    -- Right instead of left Join otherwise data from outpatients is included
    GROUP BY stay_id
),

leuk AS (
    SELECT icu.stay_id,
           "leukocytes_d" AS parameter,
           SAFE_DIVIDE(
            COUNT(CASE WHEN itemid IN (51300) 
            THEN 1 ELSE NULL END),
            AVG(los_icu+1)) AS value
    FROM `physionet-data.mimiciv_hosp.labevents` AS lab
    RIGHT JOIN (
        SELECT icu.stay_id, icu.hadm_id, icu.los_icu
        FROM `physionet-data.mimiciv_derived.icustay_detail` AS icu
    ) AS icu
    ON lab.hadm_id = icu.hadm_id
    WHERE valuenum IS NOT NULL AND valuenum >0
    -- Right instead of left Join otherwise data from outpatients is included
    GROUP BY stay_id
),

-- crp AS (
--     SELECT icu.stay_id,
--            "crp_d" AS parameter,
--            SAFE_DIVIDE(
--             COUNT(CASE WHEN itemid IN (51652, 50889)
--             THEN 1 ELSE NULL END),
--             AVG(los_icu+1)) AS value
--     FROM `physionet-data.mimiciv_hosp.labevents` AS lab
--     RIGHT JOIN (
--         SELECT icu.stay_id, icu.hadm_id, icu.los_icu
--         FROM `physionet-data.mimiciv_derived.icustay_detail` AS icu
--     ) AS icu
--     ON lab.hadm_id = icu.hadm_id
--     WHERE valuenum IS NOT NULL AND valuenum >0
--     -- Right instead of left Join otherwise data from outpatients is included
--     GROUP BY stay_id
-- ),

-- CRP different way of calculating: using derived table in MIMIC-IV
crp AS (
  SELECT
      icu.stay_id,
      "crp_d" AS parameter,
      SAFE_DIVIDE(
          COUNT(inf.crp), AVG(icu.los_icu+1)
          ) AS value
  FROM `physionet-data.mimiciv_derived.inflammation` AS inf
    RIGHT JOIN (
        SELECT icu.stay_id, icu.hadm_id, icu.los_icu
        FROM `physionet-data.mimiciv_derived.icustay_detail` AS icu
  ) AS icu
  ON inf.hadm_id = icu.hadm_id
  WHERE inf.crp IS NOT NULL
    -- Right instead of left Join otherwise data from outpatients is included
  GROUP BY stay_id
),


crea AS (
    SELECT icu.stay_id,
           "creatinine_d" AS parameter,
           SAFE_DIVIDE(
            COUNT(CASE WHEN itemid IN (52024,50912,52546) 
            THEN 1 ELSE NULL END),
            AVG(los_icu+1)) AS value
    FROM `physionet-data.mimiciv_hosp.labevents` AS lab
    RIGHT JOIN (
        SELECT icu.stay_id, icu.hadm_id, icu.los_icu
        FROM `physionet-data.mimiciv_derived.icustay_detail` AS icu
    ) AS icu
    ON lab.hadm_id = icu.hadm_id
    WHERE valuenum IS NOT NULL AND valuenum >0
    -- Right instead of left Join otherwise data from outpatients is included
    GROUP BY stay_id
),

alat AS (
    SELECT icu.stay_id,
           "alat_d" AS parameter,
           SAFE_DIVIDE(
            COUNT(CASE WHEN itemid IN (50861,53084) 
            THEN 1 ELSE NULL END),
            AVG(los_icu+1)) AS value
    FROM `physionet-data.mimiciv_hosp.labevents` AS lab
    RIGHT JOIN (
        SELECT icu.stay_id, icu.hadm_id, icu.los_icu
        FROM `physionet-data.mimiciv_derived.icustay_detail` AS icu
    ) AS icu
    ON lab.hadm_id = icu.hadm_id
    WHERE valuenum IS NOT NULL AND valuenum >0
    -- Right instead of left Join otherwise data from outpatients is included
    GROUP BY stay_id
),

sodium AS (
    SELECT icu.stay_id,
           "sodium_d" AS parameter,
           SAFE_DIVIDE(
            COUNT(CASE WHEN itemid IN (50983,52623,50824,52455) 
            THEN 1 ELSE NULL END),
            AVG(los_icu+1)) AS value
    FROM `physionet-data.mimiciv_hosp.labevents` AS lab
    RIGHT JOIN (
        SELECT icu.stay_id, icu.hadm_id, icu.los_icu
        FROM `physionet-data.mimiciv_derived.icustay_detail` AS icu
    ) AS icu
    ON lab.hadm_id = icu.hadm_id
    WHERE valuenum IS NOT NULL AND valuenum >0
    -- Right instead of left Join otherwise data from outpatients is included
    GROUP BY stay_id
),

-- Urine Output (uo)
urine AS (
    SELECT uo.stay_id,
           "urineoutput_hr" AS parameter,
           SAFE_DIVIDE(COUNT(uo.urineoutput), AVG(los_icu*24+1)) AS value
    FROM `physionet-data.mimiciv_derived.urine_output` AS uo
    LEFT JOIN (
        SELECT icu.stay_id, icu.los_icu
        FROM `physionet-data.mimiciv_derived.icustay_detail` AS icu
    ) AS icu
    ON uo.stay_id = icu.stay_id
    GROUP BY stay_id
),

-- Input Events (ie)
inputev AS (
    SELECT ie.stay_id,
           "input_hr" AS parameter,
           SAFE_DIVIDE(COUNT(ie.amount), AVG(los_icu*24)) AS value
    FROM `physionet-data.mimiciv_icu.inputevents` AS ie
    LEFT JOIN (
        SELECT icu.stay_id, icu.los_icu
        FROM `physionet-data.mimiciv_derived.icustay_detail` AS icu
    ) AS icu
    ON ie.stay_id = icu.stay_id
    WHERE ie.amount >= 1
    AND (ie.amountuom = 'ml' OR ie.amountuom = 'grams')
    GROUP BY stay_id
),

-- Prescriptions (pres)
prescription AS (
    SELECT icu.stay_id,
           "drug_hr" AS parameter,
           SAFE_DIVIDE(COUNT(pres.drug), AVG(los_icu*24+1)) AS value
            -- potential error: removed concat with starttime, superfluous, same no. of rows
    FROM `physionet-data.mimiciv_hosp.prescriptions` AS pres
    RIGHT JOIN (
        SELECT icu.stay_id, icu.hadm_id, icu.los_icu
        FROM `physionet-data.mimiciv_derived.icustay_detail` AS icu
    ) AS icu
    ON pres.hadm_id = icu.hadm_id
    WHERE pres.hadm_id IS NOT NULL -- otherwise data from outside ICU is included
    GROUP BY stay_id
),

combined AS (
    SELECT parameter, value FROM ICU_unique_patients
    UNION ALL
    SELECT parameter, value FROM overall_unique_patients
    UNION ALL
    SELECT parameter, value FROM unique_admissions
    UNION ALL
    SELECT parameter_malegender AS parameter, value_gender AS value FROM ICU_Admissions_Proportions
    UNION ALL
    SELECT parameter_28dm AS parameter, value_28dm AS value FROM ICU_Admissions_Proportions
    UNION ALL
    SELECT parameter_inhospm AS parameter, value_inhospm AS value FROM ICU_Admissions_Proportions
    UNION ALL
    SELECT parameter_1ym AS parameter, value_1ym AS value FROM ICU_Admissions_Proportions
    UNION ALL
    SELECT parameter_icu_mort AS parameter, value_icu_mort AS value FROM ICU_Admissions_Proportions
    UNION ALL
    SELECT parameter_race_white AS parameter, value_race_white AS value FROM ICU_Admissions_Proportions
    UNION ALL
    SELECT parameter_race_aa AS parameter, value_race_aa AS value FROM ICU_Admissions_Proportions
    UNION ALL
    SELECT parameter_race_other AS parameter, value_race_other AS value FROM ICU_Admissions_Proportions
    UNION ALL
    SELECT parameter, value FROM Comorbidities
    UNION ALL
    SELECT parameter_sofa AS parameter, value_sofa AS value FROM Severity
    UNION ALL
    SELECT parameter_oasis AS parameter, value_oasis AS value FROM Severity
    UNION ALL
    SELECT parameter_apsiii AS parameter, value_apsiii AS value FROM Severity
    UNION ALL
    SELECT parameter_surgery AS parameter, value_surgery AS value FROM Severity
    UNION ALL
    SELECT parameter_elective AS parameter, value_elective AS value FROM Admission_Reason
    UNION ALL
    SELECT parameter_nonelective AS parameter, value_nonelective AS value FROM Admission_Reason
    UNION ALL
    SELECT parameter, value FROM CRRT_Usage
    UNION ALL
    SELECT parameter, value FROM Vasopressor_Usage
    UNION ALL
    SELECT parameter_inv_vent AS parameter, value_inv_vent AS value FROM Mechanical_Ventilation_Usage
    UNION ALL
    SELECT parameter_noninv_vent AS parameter, value_noninv_vent AS value FROM Mechanical_Ventilation_Usage
    UNION ALL
--     SELECT parameter, value FROM chest_xrays
--     UNION ALL
    SELECT parameter, value FROM resp
    UNION ALL
    SELECT parameter, value FROM heart
    UNION ALL
    SELECT parameter, value FROM spo
    UNION ALL
    SELECT parameter, value FROM sbp
    UNION ALL
    SELECT parameter, value FROM peep
    UNION ALL
    SELECT parameter, value FROM etco
    UNION ALL
    SELECT parameter, value FROM cardiac
    UNION ALL
    SELECT parameter, value FROM fio2
    UNION ALL
    SELECT parameter, value FROM po2
    UNION ALL
    SELECT parameter, value FROM lact
    UNION ALL
    SELECT parameter, value FROM leuk
    UNION ALL
    SELECT parameter, value FROM crp
    UNION ALL
    SELECT parameter, value FROM crea
    UNION ALL
    SELECT parameter, value FROM alat
    UNION ALL
    SELECT parameter, value FROM sodium
    UNION ALL
    SELECT parameter, value FROM prescription
    UNION ALL
    SELECT parameter, value FROM urine
    UNION ALL
    SELECT parameter, value FROM hemog
)

-- resulting end view: parameter name, median of frequency, standard deviation of frequency;
SELECT parameter,
       AVG(value) AS value_mean,
       APPROX_QUANTILES(value, 100)[OFFSET(50)] AS value_median,
       APPROX_QUANTILES(value, 100)[OFFSET(25)] AS value_lIQR,
       APPROX_QUANTILES(value, 100)[OFFSET(75)] AS value_uIQR,
       STDDEV_POP(value) AS value_standardeviation
FROM COMBINED
GROUP BY parameter
ORDER BY parameter DESC;