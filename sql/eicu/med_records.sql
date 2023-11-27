WITH

patient_select AS(
    SELECT DISTINCT patientunitstayid, SAFE_CAST(unitdischargeoffset AS FLOAT64) AS unitdischargeoffset
    FROM `physionet-data.eicu_crd.patient`
    WHERE unitdischargeoffset > 15 --exclude administrative admission
),

MED_DATA AS (
    SELECT i.patientunitstayid, SAFE_CAST(drugstartoffset AS FLOAT64) drugstartoffset,
           p.unitdischargeoffset
    FROM `physionet-data.eicu_crd.medication` i
             JOIN patient_select p ON i.patientunitstayid = p.patientunitstayid
    WHERE i.drugstartoffset > 0 -- after unit admission
      AND i.drugstartoffset < p.unitdischargeoffset -- within unit stay
),

INF_DATA AS (
    SELECT i.patientunitstayid, SAFE_CAST(infusionoffset AS FLOAT64) infusionoffset,
           p.unitdischargeoffset
    FROM `physionet-data.eicu_crd.infusiondrug` i
             JOIN patient_select p ON i.patientunitstayid = p.patientunitstayid
    WHERE i.infusionoffset > 0 -- after unit admission
      AND i.infusionoffset < p.unitdischargeoffset -- within unit stay
),

MED_MED AS (
    SELECT DISTINCT n.patientunitstayid, COUNT(*) as count, AVG(n.unitdischargeoffset) as los
    FROM MED_DATA n
    GROUP BY n.patientunitstayid
),

MED_INF AS (
    SELECT DISTINCT n.patientunitstayid, COUNT(*) as count, AVG(n.unitdischargeoffset) as los
    FROM INF_DATA n
    GROUP BY n.patientunitstayid
),

MED_COMBINED AS (
    SELECT DISTINCT patientunitstayid, count, los
    FROM MED_MED
    UNION ALL SELECT DISTINCT patientunitstayid, count, los, FROM MED_INF
),

INT_MED AS (
    SELECT DISTINCT patientunitstayid, SUM(count) as count, AVG(los) as los, SUM(count)/AVG(los/60+1) as frequency_per_hour, -- +1 to prevent skewing from very short admissions
    FROM MED_COMBINED
    GROUP BY 1
),

RESULT_MED AS(
    SELECT
        'medication' AS parameter,
        AVG(frequency_per_hour) AS avg_per_hour,
        STDDEV_POP(frequency_per_hour) AS std_per_hour,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(100)] AS perc_100,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(75)] AS perc_75,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(50)] AS perc_50,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(25)] AS perc_25,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(0)] AS perc_0,
    FROM INT_MED)

SELECT * FROM RESULT_MED