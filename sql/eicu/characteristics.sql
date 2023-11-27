WITH
-- create helping tables
patient_select AS(
    SELECT DISTINCT patientunitstayid, SAFE_CAST(unitdischargeoffset AS FLOAT64) AS unitdischargeoffset
    FROM `physionet-data.eicu_crd.patient`
    WHERE unitdischargeoffset > 15 --exclude administrative admission
    ),

age AS (
    SELECT
        --COUNT(DISTINCT(pat.uniquepid)) AS patient_count,
        --COUNT(DISTINCT(pat.patientunitstayid)) AS icu_admission_count,
        --COUNT(DISTINCT(pat.patientunitstayid)) / COUNT(DISTINCT(uniquepid)) AS icu_patient_proportion,
        --COUNT(DISTINCT(CASE WHEN pat.patientunitstayid IS NOT NULL THEN pat.uniquepid END)) / COUNT(DISTINCT(uniquepid)) AS icu_patient_proportion,
        --COUNT(DISTINCT(pat.patienthealthsystemstayid)) AS hosp_admission_count,
        --COUNT(DISTINCT(pat.patientunitstayid)) / COUNT(DISTINCT(patienthealthsystemstayid)) AS icu_admission_proportion,
        --COUNT(DISTINCT CASE WHEN SAFE_CAST(pat.age AS NUMERIC) < 18 THEN pat.patientunitstayid END) AS minor_icu_count,
        --(COUNT(DISTINCT(pat.patientunitstayid)) -
        --COUNT(DISTINCT CASE WHEN SAFE_CAST(pat.age AS NUMERIC) < 18 THEN pat.patientunitstayid END)) /
        --COUNT(DISTINCT(pat.patientunitstayid)) AS adult_icu_proportion,
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
    WHERE unitdischargeoffset  > 15
),

length_of_stay_days AS
    (SELECT DISTINCT
        'length_of_stay_days' AS parameter,
        (CASE
        WHEN SAFE_CAST(age AS NUMERIC) IS NULL THEN patientunitstayid ELSE
            CASE WHEN SAFE_CAST(age AS NUMERIC) > 18 THEN patientunitstayid ELSE NULL END END) AS adult_unitid,
        unitDischargeOffset/60/24 AS value
        FROM `physionet-data.eicu_crd.patient`
            WHERE unitdischargeoffset <> 0),

lab_data AS (
    SELECT DISTINCT r.patientunitstayid,
    SAFE_CAST(r.labresultoffset AS FLOAT64) AS labresultoffset,
    r.labName,
    p.unitdischargeoffset
    FROM `physionet-data.eicu_crd.lab` r
        INNER JOIN patient_select p ON r.patientunitstayid = p.patientunitstayid
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

resp_data AS (
    SELECT DISTINCT
        r.patientunitstayid,
        SAFE_CAST(r.respchartoffset AS FLOAT64) AS respchartoffset,
        r.respchartvaluelabel,
        p.unitdischargeoffset
    FROM `physionet-data.eicu_crd.respiratorycharting` r
             JOIN patient_select p ON r.patientunitstayid = p.patientunitstayid
    WHERE r.respchartoffset > 0 -- after unit admission
        AND r.respchartoffset < p.unitdischargeoffset -- within unit stay
),

nurse_data AS (
    SELECT DISTINCT n.patientunitstayid, SAFE_CAST(n.nursingchartoffset AS FLOAT64) AS nursingchartoffset, n.nursingchartcelltypevallabel,
                    nursingchartcelltypevalname, p.unitdischargeoffset
    FROM `physionet-data.eicu_crd.nursecharting` n
             JOIN patient_select p ON n.patientunitstayid = p.patientunitstayid
    WHERE n.nursingchartoffset > 0 -- after unit admission
        AND n.nursingchartoffset < p.unitdischargeoffset -- within unit stay
),

vital_data AS (
    SELECT v.patientunitstayid, SAFE_CAST(observationoffset AS FLOAT64) AS observationoffset,
           p.unitdischargeoffset, heartrate, respiration, etco2, systemicsystolic
    FROM `physionet-data.eicu_crd.vitalperiodic` v
             JOIN patient_select p ON v.patientunitstayid = p.patientunitstayid
    WHERE v.observationoffset > 0 -- after unit admission
      AND v.observationoffset < p.unitdischargeoffset -- within unit stay
),

vital_a_data AS(
    SELECT a.patientunitstayid, SAFE_CAST(observationoffset AS FLOAT64) AS observationoffset,
           p.unitdischargeoffset, nonInvasiveSystolic, cardiacOutput
    FROM `physionet-data.eicu_crd.vitalaperiodic` a
             JOIN patient_select p ON a.patientunitstayid = p.patientunitstayid
    WHERE a.observationoffset > 0 -- after unit admission
      AND a.observationoffset < p.unitdischargeoffset -- within unit stay
),

-- query characteristics
unique_admissions AS (
    SELECT
        'unique_admissions' AS parameter,
        COUNT(DISTINCT(patientunitstayid)) AS value,
    FROM `physionet-data.eicu_crd.patient`
    WHERE unitdischargeoffset  > 15
),

unique_patients AS (
  SELECT
      'unique_patients' AS parameter,
      COUNT(DISTINCT(uniquepid)) AS value,
  FROM `physionet-data.eicu_crd.patient`
  WHERE unitdischargeoffset  > 15
),

pat_count AS (
    SELECT COUNT(pat.patientunitstayid) AS pat_count
    FROM patient_select pat
),

reason_for_admission_elective AS (
    SELECT
        'reason_for_admission_elective' AS parameter,
        COUNT(DISTINCT(admit.patientunitstayid)) AS value
    FROM `physionet-data.eicu_crd.admissiondx` admit
             RIGHT JOIN patient_select pat ON pat.patientunitstayid = admit.patientunitstayid
    WHERE admit.admitdxpath LIKE '%admission diagnosis|Elective|Yes%'
),

reason_for_admission_non_elective AS(
    SELECT
        'reason_for_admission_non_elective' AS parameter,
        COUNT(DISTINCT(admit.patientunitstayid)) AS value
    FROM `physionet-data.eicu_crd.admissiondx` admit
             RIGHT JOIN patient_select pat ON pat.patientunitstayid = admit.patientunitstayid
    WHERE admit.admitdxpath LIKE '%admission diagnosis|Elective|No%'
),

unknown_elective AS (
    SELECT
        'unknown_elective' AS parameter,
        p.pat_count - n.value - e.value as value
    FROM pat_count p, reason_for_admission_non_elective n, reason_for_admission_elective e
),

reason_for_admission_non_operative AS (
    SELECT
        'reason_for_admission_non_operative' AS parameter,
        COUNT(DISTINCT(admit.patientunitstayid)) AS value
    FROM `physionet-data.eicu_crd.admissiondx` admit
        RIGHT JOIN patient_select pat ON pat.patientunitstayid = admit.patientunitstayid
    WHERE admit.admitdxpath LIKE '%Non-operative%'
),

reason_for_admission_operative AS (
    SELECT
        'reason_for_admission_operative' AS parameter,
        COUNT(DISTINCT(admit.patientunitstayid)) AS value
    FROM `physionet-data.eicu_crd.admissiondx` admit
        RIGHT JOIN patient_select pat ON pat.patientunitstayid = admit.patientunitstayid
    WHERE admit.admitdxpath LIKE '%Operative%'
),

unknown_operative AS (
    SELECT
        'unknown_operative' AS parameter,
        p.pat_count - n.value - o.value as value
    FROM pat_count p, reason_for_admission_non_operative n, reason_for_admission_operative o
),

gender AS (
    SELECT
        'gender' AS parameter,
        COUNT(CASE WHEN gender='Male' THEN 1 END) AS value, -- does not specify unknow, other or females
    FROM `physionet-data.eicu_crd.patient`
    WHERE unitdischargeoffset  > 15 -- todo find out why this line of code exists
),

alat AS (
    SELECT DISTINCT
        'ALAT_per_day' AS parameter,
        patientunitstayid, COUNT(*)/(AVG(unitdischargeoffset)/(60*24)+1) AS value -- frequency_per_day, add+1 for correction of skewing
        FROM lab_data
        WHERE labNAME = 'ALT (SGPT)'
        GROUP BY patientunitstayid
),

cardiac_output_helper AS(
    SELECT a.patientunitstayid, SAFE_CAST(observationoffset AS FLOAT64) AS observationoffset,
           p.unitdischargeoffset, nonInvasiveSystolic, cardiacOutput
    FROM `physionet-data.eicu_crd.vitalaperiodic` a
             JOIN patient_select p ON a.patientunitstayid = p.patientunitstayid
    WHERE a.observationoffset > 0 -- after unit admission
      AND a.observationoffset < p.unitdischargeoffset -- within unit stay
),

cardiac_output_helper2 AS (
    SELECT DISTINCT
        n.patientunitstayid, COUNT(*) as count, AVG(n.unitdischargeoffset) as los--, COUNT(*)/AVG(n.unitdischargeoffset)/60 as value --frequency_per_hour
    FROM cardiac_output_helper n
    WHERE n.cardiacOutput IS NOT NULL
    GROUP BY n.patientunitstayid
),

cardiac_output AS (
    SELECT
        'cardiac_output' AS parameter,
        patientunitstayid, SUM(count)/AVG(los/60+1) as value --frequency_per_hour
    FROM cardiac_output_helper2
    GROUP BY patientunitstayid
),

comorbidity AS (
    SELECT
        'comorbidity' AS parameter,
        COUNT(DISTINCT patientunitstayid) as value
    FROM `physionet-data.eicu_crd.pasthistory`
),

creatinine AS (
    SELECT DISTINCT
        'creatinine_per_day' AS parameter,
        patientunitstayid, COUNT(*)/(AVG(unitdischargeoffset)/(60*24)+1) AS value -- frequency_per_day
    FROM lab_data
    WHERE labNAME = 'creatinine'
    GROUP BY patientunitstayid
),

crp AS (
    SELECT DISTINCT
        'CRP_per_day' AS parameter,
        patientunitstayid, COUNT(*)/(AVG(unitdischargeoffset)/(60*24)+1) AS value --frequency_per_day
    FROM lab_data
    WHERE labNAME = 'CRP'
    GROUP BY patientunitstayid
),

crrt_usage AS (
    SELECT
        'crrt_usage' AS parameter,
        COUNT(DISTINCT patientunitstayid) as value
    FROM `physionet-data.eicu_crd.treatment`
    WHERE (treatmentstring LIKE '%hemodialysis%') OR (treatmentstring LIKE '%C V V H%') OR (treatmentstring LIKE '%C V V H D%') OR (treatmentstring LIKE '%ultrafiltration%') OR (treatmentstring LIKE '%C A V H D%') OR (treatmentstring LIKE '%SLED%')
),

etCO2_vent AS (
    SELECT DISTINCT r.patientunitstayid, COUNT(*) as count, AVG(r.unitdischargeoffset) as los,
    FROM resp_data r
    WHERE (respchartvaluelabel = 'EtCO2' OR respchartvaluelabel = 'ETCO2' OR respchartvaluelabel = 'Adult Con Pt/Vent ETCO2' OR respchartvaluelabel = 'Adult Con Pt/Vent ETCO2_')
    GROUP BY r.patientunitstayid
),

etCO2_nurse AS (
    SELECT DISTINCT n.patientunitstayid, COUNT(*) as count, AVG(n.unitdischargeoffset) as los
    FROM nurse_data n
    WHERE n.nursingchartcelltypevallabel = 'End Tidal CO2'
    GROUP BY n.patientunitstayid
),

etCO2_vital AS (
    SELECT DISTINCT n.patientunitstayid, COUNT(*) as count, AVG(n.unitdischargeoffset) as los
    FROM vital_data n
    WHERE n.etco2 IS NOT NULL
    GROUP BY n.patientunitstayid
),

etCO2_combined AS (
    SELECT DISTINCT patientunitstayid, count, los
    FROM etCO2_vent
    UNION ALL SELECT DISTINCT patientunitstayid, count, los FROM etCO2_nurse
    UNION ALL SELECT DISTINCT patientunitstayid, count, los FROM etCO2_vital
),

etCO2 AS (
    SELECT DISTINCT 'etCO2' AS parameter, patientunitstayid, SUM(count)/AVG(los/60+1) as value --frequency_per_hour,
    FROM etCO2_combined
    GROUP BY patientunitstayid
),

fio2 AS (
    SELECT DISTINCT 'FiO2' AS parameter, r.patientunitstayid, COUNT(*) as count, AVG(r.unitdischargeoffset) as los, COUNT(*)/AVG(r.unitdischargeoffset/60+1) as value --frequency_per_hour
    FROM resp_data r
    WHERE (respchartvaluelabel = 'FIO2 (%)' OR respchartvaluelabel = 'FiO2')
    GROUP BY r.patientunitstayid
),

fluids_helper AS(
    SELECT f.patientunitstayid, SAFE_CAST(intakeoutputoffset AS FLOAT64) AS intakeoutputoffset,
           p.unitdischargeoffset,
    FROM `physionet-data.eicu_crd.intakeoutput` f
             JOIN patient_select p ON f.patientunitstayid = p.patientunitstayid
    WHERE f.intakeoutputoffset > 0 -- after unit admission
      AND f.intakeoutputoffset < p.unitdischargeoffset -- within unit stay
),

fluids_helper2 AS (
    SELECT DISTINCT n.patientunitstayid, COUNT(*) as count, AVG(n.unitdischargeoffset) as los
    FROM fluids_helper n
    GROUP BY n.patientunitstayid
),

fluids AS (
    SELECT DISTINCT 'fluids' AS parameter, patientunitstayid, SUM(count) as count, AVG(los) as los, SUM(count)/AVG(los/60+1) as value --frequency_per_hour,
    FROM fluids_helper2
    GROUP BY patientunitstayid
),

heart_rate_nurse AS (
    SELECT DISTINCT n.patientunitstayid, COUNT(*) as count, AVG(n.unitdischargeoffset) as los
    FROM nurse_data n
    WHERE n.nursingchartcelltypevallabel = 'Heart Rate'
    GROUP BY n.patientunitstayid
),

heart_rate_vital AS (
    SELECT DISTINCT n.patientunitstayid, COUNT(*) as count, AVG(n.unitdischargeoffset) as los
    FROM vital_data n
    WHERE n.heartrate IS NOT NULL
    GROUP BY n.patientunitstayid
),

heart_rate_combined AS (
    SELECT DISTINCT patientunitstayid, count, los
    FROM heart_rate_nurse
    UNION ALL SELECT DISTINCT patientunitstayid, count, los FROM heart_rate_vital
),

heart_rate AS (
    SELECT DISTINCT 'heart_rate' AS parameter, patientunitstayid, SUM(count) as count, AVG(los) as los, SUM(count)/AVG(los/60+1) as value --frequency_per_hour
    FROM heart_rate_combined
    GROUP BY patientunitstayid
),

hemoglobin AS (
    SELECT DISTINCT 'hemoglobin_per_day' AS parameter, patientunitstayid, COUNT(*)/(AVG(unitdischargeoffset)/(60*24)+1) AS value --frequency_per_day
    FROM lab_data
    WHERE labName = 'Hgb'
    GROUP BY patientunitstayid
),

lactate AS (
    SELECT DISTINCT 'lactate_per_day' AS parameter, patientunitstayid, COUNT(*)/(AVG(unitdischargeoffset)/(60*24)+1) as value --frequency_per_day
    FROM lab_data
    WHERE labName = 'lactate'
    GROUP BY patientunitstayid
),

leucocytes AS (
    SELECT DISTINCT 'leucocytes' AS parameter, patientunitstayid, COUNT(*)/(AVG(unitdischargeoffset)/60+1) as value --frequency_per_hour
    FROM lab_data
    WHERE labName = 'WBC x 1000'
    GROUP BY patientunitstayid
),

mech_vent_usage AS (
    SELECT
        'mech_vent_usage' AS parameter,
        COUNT(DISTINCT patientunitstayid) AS value
    FROM `physionet-data.eicu_crd.treatment`
    WHERE LOWER(treatmentstring) LIKE '%mechanical ventilation%'
),

o2_sat_peripheral AS (
    SELECT DISTINCT 'o2_sat_peripheral' AS parameter, n.patientunitstayid, COUNT(*)/(AVG(n.unitdischargeoffset)/60+1) as value --frequency_per_hour
    FROM nurse_data n
    WHERE (n.nursingChartCellTypeValLabel = 'O2 Saturation' OR n.nursingChartCellTypeValLabel = 'SpO2')
    GROUP BY n.patientunitstayid
),

peep AS (
    SELECT DISTINCT 'peep' AS parameter, r.patientunitstayid, COUNT(*)/AVG(r.unitdischargeoffset/60+1) as value --frequency_per_hour
    FROM resp_data r
    WHERE (respchartvaluelabel = 'PEEP/CPAP' OR respchartvaluelabel = 'PEEP')
    GROUP BY r.patientunitstayid
),

paO2 AS (
    SELECT DISTINCT 'paO2_per_day' AS parameter, patientunitstayid, count(*)/(AVG(unitdischargeoffset)/(60*24)+1) as value --frequency_per_day
    FROM lab_data
    WHERE labName = 'paO2'
    GROUP BY patientunitstayid
),

resp_rate_vent AS (
    SELECT DISTINCT r.patientunitstayid, COUNT(*) as count, AVG(r.unitdischargeoffset) as los
    FROM resp_data r
    WHERE (respchartvaluelabel = 'Resp Rate Total')
    GROUP BY r.patientunitstayid
),

resp_rate_nurse AS (
    SELECT DISTINCT n.patientunitstayid, COUNT(*) as count, AVG(n.unitdischargeoffset) as los
    FROM nurse_data n
    WHERE n.nursingchartcelltypevallabel = 'Respiratory Rate'
    GROUP BY n.patientunitstayid
),

resp_rate_vital AS (
    SELECT DISTINCT r.patientunitstayid, COUNT(*) as count, AVG(r.unitdischargeoffset) as los,
    FROM vital_data r
    WHERE r.respiration IS NOT NULL
    GROUP BY r.patientunitstayid
),

resp_rate_combined AS (
    SELECT DISTINCT patientunitstayid, count, los
    FROM resp_rate_vent
    UNION ALL SELECT DISTINCT patientunitstayid, count, los FROM resp_rate_nurse
    UNION ALL SELECT DISTINCT patientunitstayid, count, los FROM resp_rate_vital
),

resp_rate AS (
    SELECT DISTINCT 'resp_rate' AS parameter, patientunitstayid, SUM(count) as count, AVG(los) as los, SUM(count)/AVG(los/60+1) as value --frequency_per_hour,
    FROM resp_rate_combined
    GROUP BY patientunitstayid
),

sodium AS (
    SELECT DISTINCT 'sodium_per_day' AS parameter, patientunitstayid, count(*)/(AVG(unitdischargeoffset)/(60*24)+1) as value --frequency_per_hour
    FROM lab_data
    WHERE labName = 'sodium'
    GROUP BY patientunitstayid
),

sys_bp_nurse AS (
    SELECT DISTINCT n.patientunitstayid, COUNT(*) as count, AVG(n.unitdischargeoffset) as los
    FROM nurse_data n
    WHERE nursingchartcelltypevalname = 'Invasive BP Systolic' OR nursingchartcelltypevalname = 'Non-Invasive BP Systolic'
    GROUP BY n.patientunitstayid
),

sys_bp_vital AS (
    SELECT DISTINCT n.patientunitstayid, COUNT(*) as count, AVG(n.unitdischargeoffset) as los
    FROM vital_data n
    WHERE n.systemicsystolic IS NOT NULL
    GROUP BY n.patientunitstayid
),

sys_bp_vital_a AS (
    SELECT DISTINCT n.patientunitstayid, COUNT(*) as count, AVG(n.unitdischargeoffset) as los
    FROM vital_a_data n
    WHERE n.nonInvasiveSystolic IS NOT NULL
    GROUP BY n.patientunitstayid
),

sys_bp_combined AS (
    SELECT DISTINCT patientunitstayid, count, los
    FROM sys_bp_nurse
    UNION ALL SELECT DISTINCT patientunitstayid, count, los FROM sys_bp_vital
    UNION ALL SELECT DISTINCT patientunitstayid, count, los, FROM sys_bp_vital_a
),

sys_bp AS (
    SELECT DISTINCT 'sys_bp' AS parameter, patientunitstayid, SUM(count) as count, AVG(los) as los, SUM(count)/AVG(los/60+1) as value --frequency_per_hour
    FROM sys_bp_combined
    GROUP BY patientunitstayid
),

patients AS (
    SELECT
        DISTINCT(CASE
            WHEN SAFE_CAST(age AS NUMERIC) IS NULL THEN patientunitstayid ELSE
            CASE WHEN SAFE_CAST(age AS NUMERIC) > 18 THEN patientunitstayid ELSE NULL END END) AS icu_admissions,
        hospitaldischargestatus,
        unitdischargestatus,
        unitDischargeOffset,
    FROM `physionet-data.eicu_crd.patient`
    WHERE unitdischargeoffset > 15
),

elective AS (
    SELECT DISTINCT(admit.patientunitstayid) AS elective
    FROM `physionet-data.eicu_crd.admissiondx` admit
        RIGHT JOIN patients pat ON pat.icu_admissions = admit.patientunitstayid
    WHERE admit.admitdxpath LIKE '%admission diagnosis|Elective|Yes%'
),

non_elective AS (
    SELECT DISTINCT(admit.patientunitstayid) AS non_elective
    FROM `physionet-data.eicu_crd.admissiondx` admit
             RIGHT JOIN patients pat ON pat.icu_admissions = admit.patientunitstayid
    WHERE admit.admitdxpath LIKE '%admission diagnosis|Elective|No%'
),

icu_mortality_overall AS (
    SELECT 'mortality_overall' AS parameter,
    COUNT(CASE WHEN unitdischargestatus = 'Expired' THEN 1 ELSE NULL END) AS value
    FROM patients
),

icu_mortality_elective AS (
    SELECT
        'mortality_elective' as parameter,
        COUNT(CASE WHEN unitdischargestatus = 'Expired' THEN 1 ELSE NULL END) / (COUNT(CASE WHEN unitdischargestatus = 'Expired' THEN 1 ELSE NULL END) + COUNT(CASE WHEN unitdischargestatus = 'Alive' THEN 1 ELSE NULL END)) AS value
    FROM patients
        INNER JOIN elective ON patients.icu_admissions = elective.elective
),

icu_mortality_non_elective AS (
    SELECT
        'mortality_non_elective' as parameter,
        COUNT(CASE WHEN unitdischargestatus = 'Expired' THEN 1 ELSE NULL END) / (COUNT(CASE WHEN unitdischargestatus = 'Expired' THEN 1 ELSE NULL END) + COUNT(CASE WHEN unitdischargestatus = 'Alive' THEN 1 ELSE NULL END)) AS value
    FROM patients
        INNER JOIN non_elective ON patients.icu_admissions = non_elective.non_elective
),

vasopressor_usage AS(
    SELECT
        'vasopressor_usage' AS parameter,
        COUNT(DISTINCT patientunitstayid) AS value
    FROM `physionet-data.eicu_crd.infusiondrug`
    WHERE (UPPER(drugname) like '%DOBU%') OR (UPPER(drugname) like '%EPINEPHRIN%') OR (UPPER(drugname) LIKE '%ADRENALIN%') OR (UPPER(drugname) LIKE '%PHENYLEPHRIN%') OR (UPPER(drugname) LIKE '%VASOPRESSIN%')
),

COMBINED AS(
    SELECT parameter, value FROM unique_admissions
    UNION ALL
    SELECT parameter, value FROM unique_patients
    UNION ALL
    SELECT parameter, value FROM reason_for_admission_non_operative
    UNION ALL
    SELECT parameter, value FROM reason_for_admission_operative
    UNION ALL
    SELECT parameter, value FROM unknown_operative
    UNION ALL
    SELECT parameter, value FROM reason_for_admission_elective
    UNION ALL
    SELECT parameter, value FROM reason_for_admission_non_elective
    UNION ALL
    SELECT parameter, value FROM unknown_elective
    UNION ALL
    SELECT parameter, value FROM gender
    UNION ALL
    SELECT parameter, value FROM alat
    UNION ALL
    SELECT parameter, value FROM cardiac_output
    UNION ALL
    SELECT parameter, value FROM creatinine
    UNION ALL
    SELECT parameter, value FROM crp
    UNION ALL
    SELECT parameter, value FROM etCO2
    UNION ALL
    SELECT parameter, value FROM fio2
    UNION ALL
    SELECT parameter, value FROM fluids
    UNION ALL
    SELECT parameter, value FROM heart_rate
    UNION ALL
    SELECT parameter, value FROM hemoglobin
    UNION ALL
    SELECT parameter, value FROM lactate
    UNION ALL
    SELECT parameter, value FROM leucocytes
    UNION ALL
    SELECT parameter, value FROM o2_sat_peripheral
    UNION ALL
    SELECT parameter, value FROM peep
    UNION ALL
    SELECT parameter, value FROM paO2
    UNION ALL
    SELECT parameter, value FROM resp_rate
    UNION ALL
    SELECT parameter, value FROM sodium
    UNION ALL
    SELECT parameter, value FROM sys_bp
    UNION ALL
    SELECT parameter, value FROM icu_mortality_overall
    UNION ALL
    SELECT parameter, value FROM icu_mortality_elective
    UNION ALL
    SELECT parameter, value FROM icu_mortality_non_elective
    UNION ALL
    SELECT parameter, value FROM unknown_elective
    UNION ALL
    SELECT parameter, value FROM vasopressor_usage
    UNION ALL
    SELECT parameter, value FROM mech_vent_usage
    UNION ALL
    SELECT parameter, value FROM crrt_usage
    UNION ALL
    SELECT parameter, value FROM comorbidity
    UNION ALL
    SELECT 'age_25percentile' AS parameter, percentile_25 AS value FROM age
    UNION ALL
    SELECT 'age_50percentile' AS parameter, percentile_50 AS value FROM age
    UNION ALL
    SELECT 'age_75percentile' AS parameter, percentile_75 AS value FROM age
    UNION ALL
    SELECT parameter, value FROM length_of_stay_days
)

-- resulting end view: parameter name, median of frequency, standard deviation of frequency;
SELECT parameter,
       AVG(value) AS value_mean,
       APPROX_QUANTILES(value, 100)[OFFSET(50)] AS value_median,
       STDDEV_POP(value) AS value_standardeviation
FROM COMBINED
GROUP BY parameter;