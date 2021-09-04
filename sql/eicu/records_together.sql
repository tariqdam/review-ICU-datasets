WITH patient_select AS(
    SELECT DISTINCT patientunitstayid, SAFE_CAST(unitdischargeoffset AS FLOAT64) AS unitdischargeoffset
    FROM `physionet-data.eicu_crd.patient`
    WHERE unitdischargeoffset > 15 --exclude administrative admission
),
RESP_DATA AS(
    SELECT DISTINCT r.patientunitstayid, SAFE_CAST(r.respchartoffset AS FLOAT64) AS respchartoffset, r.respchartvaluelabel, p.unitdischargeoffset
    FROM `physionet-data.eicu_crd.respiratorycharting` r
    JOIN patient_select p ON r.patientunitstayid = p.patientunitstayid
    WHERE r.respchartoffset > 0 -- after unit admission
    AND r.respchartoffset < p.unitdischargeoffset -- within unit stay
),
NURSE_DATA AS(
    SELECT DISTINCT n.patientunitstayid, SAFE_CAST(n.nursingchartoffset AS FLOAT64) AS nursingchartoffset, n.nursingchartcelltypevallabel,
    nursingchartcelltypevalname, p.unitdischargeoffset
    FROM `physionet-data.eicu_crd.nursecharting` n
    JOIN patient_select p ON n.patientunitstayid = p.patientunitstayid
    WHERE n.nursingchartoffset > 0 -- after unit admission
    AND n.nursingchartoffset < p.unitdischargeoffset -- within unit stay
),
VITAL_DATA AS(
    SELECT v.patientunitstayid, SAFE_CAST(observationoffset AS FLOAT64) AS observationoffset,
        p.unitdischargeoffset, heartrate, respiration, etco2, systemicsystolic
    FROM `physionet-data.eicu_crd.vitalperiodic` v
    JOIN patient_select p ON v.patientunitstayid = p.patientunitstayid
    WHERE v.observationoffset > 0 -- after unit admission
    AND v.observationoffset < p.unitdischargeoffset -- within unit stay
),
VITAL_A_DATA AS(
    SELECT a.patientunitstayid, SAFE_CAST(observationoffset AS FLOAT64) AS observationoffset,
        p.unitdischargeoffset, nonInvasiveSystolic, cardiacOutput
    FROM `physionet-data.eicu_crd.vitalaperiodic` a
    JOIN patient_select p ON a.patientunitstayid = p.patientunitstayid
    WHERE a.observationoffset > 0 -- after unit admission
    AND a.observationoffset < p.unitdischargeoffset -- within unit stay
),
INF_DATA AS (
    SELECT i.patientunitstayid, SAFE_CAST(infusionoffset AS FLOAT64) infusionoffset,
        p.unitdischargeoffset
    FROM `physionet-data.eicu_crd.infusiondrug` i
    JOIN patient_select p ON i.patientunitstayid = p.patientunitstayid
    WHERE i.infusionoffset > 0 -- after unit admission
    AND i.infusionoffset < p.unitdischargeoffset -- within unit stay
),
MED_DATA AS (
    SELECT i.patientunitstayid, SAFE_CAST(drugstartoffset AS FLOAT64) drugstartoffset,
        p.unitdischargeoffset
    FROM `physionet-data.eicu_crd.medication` i
    JOIN patient_select p ON i.patientunitstayid = p.patientunitstayid
    WHERE i.drugstartoffset > 0 -- after unit admission
    AND i.drugstartoffset < p.unitdischargeoffset -- within unit stay
),
FLUID_DATA AS(
    SELECT f.patientunitstayid, SAFE_CAST(intakeoutputoffset AS FLOAT64) AS intakeoutputoffset,
        p.unitdischargeoffset,
    FROM `physionet-data.eicu_crd.intakeoutput` f
    JOIN patient_select p ON f.patientunitstayid = p.patientunitstayid
    WHERE f.intakeoutputoffset > 0 -- after unit admission
    AND f.intakeoutputoffset < p.unitdischargeoffset -- within unit stay
),
RESP_RATE_VENT AS (
    SELECT DISTINCT r.patientunitstayid, COUNT(*) as count, AVG(r.unitdischargeoffset) as los,
    FROM RESP_DATA r
    WHERE (respchartvaluelabel = 'Resp Rate Total')
    GROUP BY r.patientunitstayid),
RESP_RATE_NURSE AS (
    SELECT DISTINCT n.patientunitstayid, COUNT(*) as count, AVG(n.unitdischargeoffset) as los
    FROM NURSE_DATA n
    WHERE n.nursingchartcelltypevallabel = 'Respiratory Rate'
    GROUP BY n.patientunitstayid
),
RESP_RATE_VITAL AS (
    SELECT DISTINCT r.patientunitstayid, COUNT(*) as count, AVG(r.unitdischargeoffset) as los,
    FROM VITAL_DATA r
    WHERE r.respiration IS NOT NULL
    GROUP BY r.patientunitstayid
),
RESP_RATE_COMBINED AS (
    SELECT DISTINCT patientunitstayid, count, los
    FROM RESP_RATE_VENT
    UNION ALL SELECT DISTINCT patientunitstayid, count, los FROM RESP_RATE_NURSE
    UNION ALL SELECT DISTINCT patientunitstayid, count, los FROM RESP_RATE_VITAL
),
INT_RESP_RATE AS (
    SELECT DISTINCT patientunitstayid, SUM(count) as count, AVG(los) as los, SUM(count)/AVG(los/60) as frequency_per_hour,
    FROM RESP_RATE_COMBINED 
    GROUP BY 1
),
RESULT_RESP_RATE AS(
    SELECT
        'respiratory rate' AS parameter,
        AVG(r.frequency_per_hour) AS avg_per_hour,
        STDDEV_POP(r.frequency_per_hour) AS std_per_hour,
        APPROX_QUANTILES(r.frequency_per_hour, 100)[OFFSET(100)] AS perc_100,
        APPROX_QUANTILES(r.frequency_per_hour, 100)[OFFSET(75)] AS perc_75,
        APPROX_QUANTILES(r.frequency_per_hour, 100)[OFFSET(50)] AS perc_50,
        APPROX_QUANTILES(r.frequency_per_hour, 100)[OFFSET(25)] AS perc_25,
        APPROX_QUANTILES(r.frequency_per_hour, 100)[OFFSET(0)] AS perc_0,  
FROM INT_RESP_RATE r),
INT_SAT_PERIPHERAL AS 
(
    SELECT DISTINCT n.patientunitstayid, COUNT(*) as count, AVG(n.unitdischargeoffset) as los, COUNT(*)/AVG(n.unitdischargeoffset/60) as frequency_per_hour
    FROM NURSE_DATA n
    WHERE (n.nursingChartCellTypeValLabel = 'O2 Saturation' OR n.nursingChartCellTypeValLabel = 'SpO2')
    GROUP BY n.patientunitstayid
),
RESULT_SAT_PERIPHERAL AS (
    SELECT 
        'peripheral saturation' AS parameter,
        AVG(frequency_per_hour) AS avg_per_hour,
        STDDEV_POP(frequency_per_hour) AS std_per_hour,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(100)] AS perc_100,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(75)] AS perc_75,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(50)] AS perc_50,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(25)] AS perc_25,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(0)] AS perc_0,
    FROM INT_SAT_PERIPHERAL 
), INT_PEEP AS 
(
    SELECT DISTINCT r.patientunitstayid, COUNT(*) as count, AVG(r.unitdischargeoffset) as los, COUNT(*)/AVG(r.unitdischargeoffset/60) as frequency_per_hour
    FROM RESP_DATA r
    WHERE (respchartvaluelabel = 'PEEP/CPAP' OR respchartvaluelabel = 'PEEP')
    GROUP BY r.patientunitstayid),
RESULT_PEEP AS(
    SELECT 
        'PEEP' AS parameter,
        AVG(frequency_per_hour) AS avg_per_hour,
        STDDEV_POP(frequency_per_hour) AS std_per_hour,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(100)] AS perc_100,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(75)] AS perc_75,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(50)] AS perc_50,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(25)] AS perc_25,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(0)] AS perc_0,
    FROM INT_PEEP),
INT_FIO2 AS 
(
    SELECT DISTINCT r.patientunitstayid, COUNT(*) as count, AVG(r.unitdischargeoffset) as los, COUNT(*)/AVG(r.unitdischargeoffset/60) as frequency_per_hour
    FROM RESP_DATA r
    WHERE (respchartvaluelabel = 'FIO2 (%)' OR respchartvaluelabel = 'FiO2')
    GROUP BY r.patientunitstayid
), RESULT_FIO2 AS
(
    SELECT 
        'FIO2' AS parameter,
        AVG(frequency_per_hour) AS avg_per_hour,
        STDDEV_POP(frequency_per_hour) AS std_per_hour,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(100)] AS perc_100,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(75)] AS perc_75,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(50)] AS perc_50,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(25)] AS perc_25,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(0)] AS perc_0,
    FROM INT_FIO2
),
INT_VENT_MODE AS 
(
    SELECT DISTINCT r.patientunitstayid, COUNT(*) as count, AVG(r.unitdischargeoffset) as los, COUNT(*)/AVG(r.unitdischargeoffset/60) as frequency_per_hour
    FROM RESP_DATA r
    WHERE (respchartvaluelabel = 'Non-invasive Ventilation Mode' OR respchartvaluelabel = 'Ventilator Support Mode' OR respchartvaluelabel = 'Mechanical Ventilator Mode')
    GROUP BY r.patientunitstayid),
RESULT_VENT_MODE AS (
    SELECT 
        'vent_mode' AS parameter,
        AVG(frequency_per_hour) AS avg_per_hour,
        STDDEV_POP(frequency_per_hour) AS std_per_hour,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(100)] AS perc_100,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(75)] AS perc_75,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(50)] AS perc_50,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(25)] AS perc_25,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(0)] AS perc_0,
    FROM INT_VENT_MODE
),
ETCO2_VENT AS
(
    SELECT DISTINCT r.patientunitstayid, COUNT(*) as count, AVG(r.unitdischargeoffset) as los,
    FROM RESP_DATA r
    WHERE (respchartvaluelabel = 'EtCO2' OR respchartvaluelabel = 'ETCO2' OR respchartvaluelabel = 'Adult Con Pt/Vent ETCO2' OR respchartvaluelabel = 'Adult Con Pt/Vent ETCO2_')
    GROUP BY r.patientunitstayid),
ETCO2_NURSE AS (
    SELECT DISTINCT n.patientunitstayid, COUNT(*) as count, AVG(n.unitdischargeoffset) as los
    FROM NURSE_DATA n
    WHERE n.nursingchartcelltypevallabel = 'End Tidal CO2'
    GROUP BY n.patientunitstayid
),
ETCO2_VITAL AS (
    SELECT DISTINCT n.patientunitstayid, COUNT(*) as count, AVG(n.unitdischargeoffset) as los
    FROM VITAL_DATA n
    WHERE n.etco2 IS NOT NULL
    GROUP BY n.patientunitstayid
),
ETCO2_COMBINED AS (
    SELECT DISTINCT patientunitstayid, count, los
    FROM ETCO2_VENT
    UNION ALL SELECT DISTINCT patientunitstayid, count, los FROM ETCO2_NURSE
    UNION ALL SELECT DISTINCT patientunitstayid, count, los FROM ETCO2_VITAL
),
INT_ETCO2 AS (
    SELECT DISTINCT patientunitstayid, SUM(count) as count, AVG(los) as los, SUM(count)/AVG(los/60) as frequency_per_hour,
    FROM ETCO2_COMBINED 
    GROUP BY 1
),
RESULT_ETCO2 AS(
    SELECT
        'ETCO2' AS parameter,
        AVG(frequency_per_hour) AS avg_per_hour,
        STDDEV_POP(frequency_per_hour) AS std_per_hour,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(100)] AS perc_100,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(75)] AS perc_75,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(50)] AS perc_50,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(25)] AS perc_25,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(0)] AS perc_0,  
FROM INT_ETCO2),
HR_NURSE AS (
    SELECT DISTINCT n.patientunitstayid, COUNT(*) as count, AVG(n.unitdischargeoffset) as los
    FROM NURSE_DATA n
    WHERE n.nursingchartcelltypevallabel = 'Heart Rate'
    GROUP BY n.patientunitstayid
),
HR_VITAL AS (
    SELECT DISTINCT n.patientunitstayid, COUNT(*) as count, AVG(n.unitdischargeoffset) as los
    FROM VITAL_DATA n
    WHERE n.heartrate IS NOT NULL
    GROUP BY n.patientunitstayid
),
HR_COMBINED AS (
    SELECT DISTINCT patientunitstayid, count, los
    FROM HR_NURSE
    UNION ALL SELECT DISTINCT patientunitstayid, count, los FROM HR_VITAL
),
INT_HR AS (
    SELECT DISTINCT patientunitstayid, SUM(count) as count, AVG(los) as los, SUM(count)/AVG(los/60) as frequency_per_hour,
    FROM HR_COMBINED 
    GROUP BY 1
),
RESULT_HR AS(
    SELECT
        'heartrate' AS parameter,
        AVG(frequency_per_hour) AS avg_per_hour,
        STDDEV_POP(frequency_per_hour) AS std_per_hour,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(100)] AS perc_100,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(75)] AS perc_75,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(50)] AS perc_50,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(25)] AS perc_25,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(0)] AS perc_0,  
FROM INT_HR),
BP_NURSE AS (
    SELECT DISTINCT n.patientunitstayid, COUNT(*) as count, AVG(n.unitdischargeoffset) as los
    FROM NURSE_DATA n
    WHERE nursingchartcelltypevalname = 'Invasive BP Systolic' OR nursingchartcelltypevalname = 'Non-Invasive BP Systolic'
    GROUP BY n.patientunitstayid
),
BP_VITAL AS (
    SELECT DISTINCT n.patientunitstayid, COUNT(*) as count, AVG(n.unitdischargeoffset) as los
    FROM VITAL_DATA n
    WHERE n.systemicsystolic IS NOT NULL
    GROUP BY n.patientunitstayid
),
BP_VITAL_A AS (
    SELECT DISTINCT n.patientunitstayid, COUNT(*) as count, AVG(n.unitdischargeoffset) as los
    FROM VITAL_A_DATA n
    WHERE n.nonInvasiveSystolic IS NOT NULL
    GROUP BY n.patientunitstayid
),
BP_COMBINED AS (
    SELECT DISTINCT patientunitstayid, count, los
    FROM BP_NURSE
    UNION ALL SELECT DISTINCT patientunitstayid, count, los FROM BP_VITAL
    UNION ALL SELECT DISTINCT patientunitstayid, count, los, FROM BP_VITAL_A
),
INT_BP AS (
    SELECT DISTINCT patientunitstayid, SUM(count) as count, AVG(los) as los, SUM(count)/AVG(los/60) as frequency_per_hour,
    FROM BP_COMBINED 
    GROUP BY 1
),
RESULT_BP AS(
    SELECT
        'bloodpressure_systolic' AS parameter,
        AVG(frequency_per_hour) AS avg_per_hour,
        STDDEV_POP(frequency_per_hour) AS std_per_hour,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(100)] AS perc_100,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(75)] AS perc_75,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(50)] AS perc_50,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(25)] AS perc_25,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(0)] AS perc_0,  
FROM INT_BP),
CO_VITAL_A AS (
    SELECT DISTINCT n.patientunitstayid, COUNT(*) as count, AVG(n.unitdischargeoffset) as los
    FROM VITAL_A_DATA n
    WHERE n.cardiacOutput IS NOT NULL
    GROUP BY n.patientunitstayid
),
INT_CO AS (
    SELECT DISTINCT patientunitstayid, SUM(count) as count, AVG(los) as los, SUM(count)/AVG(los/60) as frequency_per_hour,
    FROM CO_VITAL_A 
    GROUP BY 1
),
RESULT_CO AS(
    SELECT
        'cardiac_output' AS parameter,
        AVG(frequency_per_hour) AS avg_per_hour,
        STDDEV_POP(frequency_per_hour) AS std_per_hour,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(100)] AS perc_100,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(75)] AS perc_75,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(50)] AS perc_50,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(25)] AS perc_25,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(0)] AS perc_0,  
FROM INT_CO),
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
    SELECT DISTINCT patientunitstayid, SUM(count) as count, AVG(los) as los, SUM(count)/AVG(los/60) as frequency_per_hour,
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
FROM INT_MED),
FLUIDS AS (
    SELECT DISTINCT n.patientunitstayid, COUNT(*) as count, AVG(n.unitdischargeoffset) as los
    FROM FLUID_DATA n
    GROUP BY n.patientunitstayid
),
INT_FLUIDS AS (
    SELECT DISTINCT patientunitstayid, SUM(count) as count, AVG(los) as los, SUM(count)/AVG(los/60) as frequency_per_hour,
    FROM FLUIDS 
    GROUP BY 1
),
RESULT_FLUIDS AS(
    SELECT
        'fluids' AS parameter,
        AVG(frequency_per_hour) AS avg_per_hour,
        STDDEV_POP(frequency_per_hour) AS std_per_hour,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(100)] AS perc_100,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(75)] AS perc_75,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(50)] AS perc_50,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(25)] AS perc_25,
        APPROX_QUANTILES(frequency_per_hour, 100)[OFFSET(0)] AS perc_0,  
FROM INT_FLUIDS)

SELECT * FROM RESULT_RESP_RATE 
UNION ALL SELECT * FROM RESULT_PEEP
UNION ALL SELECT * FROM RESULT_SAT_PERIPHERAL
UNION ALL SELECT * FROM RESULT_FIO2
UNION ALL SELECT * FROM RESULT_VENT_MODE
UNION ALL SELECT * FROM RESULT_ETCO2
UNION ALL SELECT * FROM RESULT_HR
UNION ALL SELECT * FROM RESULT_BP
UNION ALL SELECT * FROM RESULT_CO
UNION ALL SELECT * FROM RESULT_MED
UNION ALL SELECT * FROM RESULT_FLUIDS

