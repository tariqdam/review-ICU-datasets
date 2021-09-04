WITH patient_select AS(
    SELECT DISTINCT patientunitstayid, SAFE_CAST(unitdischargeoffset AS FLOAT64) AS unitdischargeoffset
    FROM `physionet-data.eicu_crd.patient`
    WHERE unitdischargeoffset > 15 --exclude administrative admission
),
LAB_DATA AS(
    SELECT DISTINCT r.patientunitstayid,
        SAFE_CAST(r.labresultoffset AS FLOAT64) AS labresultoffset,
        r.labName,
        p.unitdischargeoffset
    FROM `physionet-data.eicu_crd.lab` r
    JOIN patient_select p ON r.patientunitstayid = p.patientunitstayid
    WHERE r.labresultoffset > 0 -- after unit admission
    AND r.labresultoffset < p.unitdischargeoffset -- within unit stay
    AND (r.labName = 'lactate' OR 
         r.labName = 'paO2' OR 
         r.labName = 'sodium' OR 
         r.labName = 'Hgb' OR 
         r.labName = 'creatinine' OR 
         r.labName = 'ALT (SGPT)' OR 
         r.labName = 'CRP' OR 
         r.labName = 'WBC x 1000')
),
LAB_LACTATE AS (
    SELECT DISTINCT patientunitstayid, count(*)/(AVG(unitdischargeoffset)/60) as frequency_per_hour
    FROM LAB_DATA 
    WHERE labName = 'lactate'
    GROUP BY patientunitstayid
),
RESULT_LACTATE AS(
    SELECT
        'lactate' AS parameter,
        AVG(frequency_per_hour) AS avg_per_hour,
        STDDEV_POP(frequency_per_hour) AS std_per_hour,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(100)] AS perc_100,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(75)] AS perc_75,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(50)] AS perc_50,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(25)] AS perc_25,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(0)] AS perc_0,  
FROM LAB_LACTATE),
LAB_paO2 AS (
    SELECT DISTINCT patientunitstayid, count(*)/(AVG(unitdischargeoffset)/60) as frequency_per_hour
    FROM LAB_DATA 
    WHERE labName = 'paO2'
    GROUP BY patientunitstayid
),
RESULT_paO2 AS(
    SELECT
        'paO2' AS parameter,
        AVG(frequency_per_hour) AS avg_per_hour,
        STDDEV_POP(frequency_per_hour) AS std_per_hour,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(100)] AS perc_100,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(75)] AS perc_75,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(50)] AS perc_50,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(25)] AS perc_25,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(0)] AS perc_0,  
FROM LAB_paO2),
LAB_sodium AS (
    SELECT DISTINCT patientunitstayid, count(*)/(AVG(unitdischargeoffset)/60) as frequency_per_hour
    FROM LAB_DATA 
    WHERE labName = 'sodium'
    GROUP BY patientunitstayid
),
RESULT_sodium AS(
    SELECT
        'sodium' AS parameter,
        AVG(frequency_per_hour) AS avg_per_hour,
        STDDEV_POP(frequency_per_hour) AS std_per_hour,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(100)] AS perc_100,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(75)] AS perc_75,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(50)] AS perc_50,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(25)] AS perc_25,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(0)] AS perc_0,  
FROM LAB_sodium),
LAB_Hgb AS (
    SELECT DISTINCT patientunitstayid, count(*)/(AVG(unitdischargeoffset)/60) as frequency_per_hour
    FROM LAB_DATA 
    WHERE labName = 'Hgb'
    GROUP BY patientunitstayid
),
RESULT_Hgb AS(
    SELECT
        'hemoglobin' AS parameter,
        AVG(frequency_per_hour) AS avg_per_hour,
        STDDEV_POP(frequency_per_hour) AS std_per_hour,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(100)] AS perc_100,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(75)] AS perc_75,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(50)] AS perc_50,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(25)] AS perc_25,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(0)] AS perc_0,  
FROM LAB_Hgb),
LAB_creatinine AS (
    SELECT DISTINCT patientunitstayid, count(*)/(AVG(unitdischargeoffset)/60) as frequency_per_hour
    FROM LAB_DATA 
    WHERE labName = 'creatinine'
    GROUP BY patientunitstayid
),
RESULT_creatinine AS(
    SELECT
        'creatinine' AS parameter,
        AVG(frequency_per_hour) AS avg_per_hour,
        STDDEV_POP(frequency_per_hour) AS std_per_hour,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(100)] AS perc_100,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(75)] AS perc_75,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(50)] AS perc_50,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(25)] AS perc_25,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(0)] AS perc_0,  
FROM LAB_creatinine),
LAB_ALT AS (
    SELECT DISTINCT patientunitstayid, count(*)/(AVG(unitdischargeoffset)/60) as frequency_per_hour
    FROM LAB_DATA 
    WHERE labName = 'ALT (SGPT)'
    GROUP BY patientunitstayid
),
RESULT_ALT AS(
    SELECT
        'ALAT' AS parameter,
        AVG(frequency_per_hour) AS avg_per_hour,
        STDDEV_POP(frequency_per_hour) AS std_per_hour,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(100)] AS perc_100,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(75)] AS perc_75,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(50)] AS perc_50,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(25)] AS perc_25,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(0)] AS perc_0,  
FROM LAB_ALT),
LAB_CRP AS (
    SELECT DISTINCT patientunitstayid, count(*)/(AVG(unitdischargeoffset)/60) as frequency_per_hour
    FROM LAB_DATA 
    WHERE labName = 'CRP'
    GROUP BY patientunitstayid
),
RESULT_CRP AS(
    SELECT
        'CRP' AS parameter,
        AVG(frequency_per_hour) AS avg_per_hour,
        STDDEV_POP(frequency_per_hour) AS std_per_hour,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(100)] AS perc_100,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(75)] AS perc_75,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(50)] AS perc_50,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(25)] AS perc_25,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(0)] AS perc_0,  
FROM LAB_CRP),
LAB_WBC AS (
    SELECT DISTINCT patientunitstayid, count(*)/(AVG(unitdischargeoffset)/60) as frequency_per_hour
    FROM LAB_DATA 
    WHERE labName = 'WBC x 1000'
    GROUP BY patientunitstayid
),
RESULT_WBC AS(
    SELECT
        'leukocytes' AS parameter,
        AVG(frequency_per_hour) AS avg_per_hour,
        STDDEV_POP(frequency_per_hour) AS std_per_hour,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(100)] AS perc_100,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(75)] AS perc_75,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(50)] AS perc_50,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(25)] AS perc_25,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(0)] AS perc_0,  
FROM LAB_WBC)
SELECT * FROM RESULT_ALT 
UNION ALL SELECT * FROM RESULT_creatinine 
UNION ALL SELECT * FROM RESULT_CRP  
UNION ALL SELECT * FROM RESULT_Hgb  
UNION ALL SELECT * FROM RESULT_LACTATE  
UNION ALL SELECT * FROM RESULT_paO2  
UNION ALL SELECT * FROM RESULT_sodium  
UNION ALL SELECT * FROM RESULT_WBC  
