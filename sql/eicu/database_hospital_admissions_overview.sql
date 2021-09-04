SELECT
    COUNT(DISTINCT(pat.uniquepid)) AS patient_count, 
    COUNT(DISTINCT(pat.patientunitstayid)) AS icu_admission_count,
    --COUNT(DISTINCT(pat.patientunitstayid)) / COUNT(DISTINCT(uniquepid)) AS icu_patient_proportion,
    COUNT(DISTINCT(CASE WHEN pat.patientunitstayid IS NOT NULL THEN pat.uniquepid END)) / COUNT(DISTINCT(uniquepid)) AS icu_patient_proportion,
    COUNT(DISTINCT(pat.patienthealthsystemstayid)) AS hosp_admission_count,
    COUNT(DISTINCT(pat.patientunitstayid)) / COUNT(DISTINCT(patienthealthsystemstayid)) AS icu_admission_proportion,
    COUNT(DISTINCT CASE WHEN SAFE_CAST(pat.age AS NUMERIC) < 18 THEN pat.patientunitstayid END) AS minor_icu_count,
    (COUNT(DISTINCT(pat.patientunitstayid)) - 
        COUNT(DISTINCT CASE WHEN SAFE_CAST(pat.age AS NUMERIC) < 18 THEN pat.patientunitstayid END)) / 
        COUNT(DISTINCT(pat.patientunitstayid)) AS adult_icu_proportion,
    APPROX_QUANTILES(CASE
        WHEN SAFE_CAST(pat.age AS NUMERIC) IS NULL THEN 89 ELSE 
            CASE WHEN SAFE_CAST(pat.age AS NUMERIC) > 18 THEN SAFE_CAST(pat.age AS NUMERIC) END
        END, 100)[OFFSET(0)] AS percentile_0,
    APPROX_QUANTILES(CASE
        WHEN SAFE_CAST(pat.age AS NUMERIC) IS NULL THEN 89 ELSE 
            CASE WHEN SAFE_CAST(pat.age AS NUMERIC) > 18 THEN SAFE_CAST(pat.age AS NUMERIC) END
        END, 100)[OFFSET(25)] AS percentile_25,
    APPROX_QUANTILES(CASE
        WHEN SAFE_CAST(pat.age AS NUMERIC) IS NULL THEN 89 ELSE 
            CASE WHEN SAFE_CAST(pat.age AS NUMERIC) > 18 THEN SAFE_CAST(pat.age AS NUMERIC) END
        END, 100)[OFFSET(50)] AS percentile_50,
    APPROX_QUANTILES(CASE
        WHEN SAFE_CAST(pat.age AS NUMERIC) IS NULL THEN 89 ELSE 
            CASE WHEN SAFE_CAST(pat.age AS NUMERIC) > 18 THEN SAFE_CAST(pat.age AS NUMERIC) END
        END, 100)[OFFSET(75)] AS percentile_75,
    APPROX_QUANTILES(CASE
        WHEN SAFE_CAST(pat.age AS NUMERIC) IS NULL THEN 89 ELSE 
            CASE WHEN SAFE_CAST(pat.age AS NUMERIC) > 18 THEN SAFE_CAST(pat.age AS NUMERIC) END
        END, 100)[OFFSET(100)] AS percentile_100,
    MIN(hospitaldischargeyear) as start_year,
    MAX(hospitaldischargeyear) as end_year

FROM `physionet-data.eicu_crd.patient` pat
WHERE unitdischargeoffset  > 15;