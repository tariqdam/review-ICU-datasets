WITH patient AS
    (SELECT
        DISTINCT(CASE
        WHEN SAFE_CAST(age AS NUMERIC) IS NULL THEN patientunitstayid ELSE 
            CASE WHEN SAFE_CAST(age AS NUMERIC) > 18 THEN patientunitstayid ELSE NULL END END) AS adult_unitid,
        hospitaldischargestatus,
        unitdischargestatus,
        unitDischargeOffset
        FROM `physionet-data.eicu_crd.patient`
		WHERE unitdischargeoffset <> 0)
SELECT
    COUNT(CASE WHEN hospitaldischargestatus = 'Expired' THEN 1 ELSE NULL END) hosp_expired_count,
    COUNT(CASE WHEN hospitaldischargestatus = 'Alive' THEN 1 ELSE NULL END) hosp_alive_count,
    COUNT(CASE WHEN hospitaldischargestatus = 'Alive' OR hospitaldischargestatus = 'Expired' THEN NULL ELSE 1 END) hosp_missing_count,
    COUNT(CASE WHEN hospitaldischargestatus = 'Expired' THEN 1 ELSE NULL END) / (COUNT(CASE WHEN hospitaldischargestatus = 'Expired' THEN 1 ELSE NULL END) + COUNT(CASE WHEN hospitaldischargestatus = 'Alive' THEN 1 ELSE NULL END)) hosp_mortality,
    COUNT(CASE WHEN unitdischargestatus = 'Expired' THEN 1 ELSE NULL END) unit_expired_count,
    COUNT(CASE WHEN unitdischargestatus = 'Alive' THEN 1 ELSE NULL END) unit_alive_count,
    COUNT(CASE WHEN unitdischargestatus = 'Alive' OR unitdischargestatus = 'Expired' THEN NULL ELSE 1 END) unit_missing_count,
    COUNT(CASE WHEN unitdischargestatus = 'Expired' THEN 1 ELSE NULL END) / (COUNT(CASE WHEN unitdischargestatus = 'Expired' THEN 1 ELSE NULL END) + COUNT(CASE WHEN unitdischargestatus = 'Alive' THEN 1 ELSE NULL END)) icu_mortality,
    MIN(unitDischargeOffset)/60/24 as min_los,
    MAX(unitDischargeOffset)/60/24 as max_los,
    AVG(unitDischargeOffset)/60/24 as avg_los,
    APPROX_QUANTILES(unitDischargeOffset, 100)[OFFSET(25)]/60/24 AS iqr_25_los,
    APPROX_QUANTILES(unitDischargeOffset, 100)[OFFSET(50)]/60/24 AS iqr_50_los,
    APPROX_QUANTILES(unitDischargeOffset, 100)[OFFSET(75)]/60/24 AS iqr_75_los,
    SUM(unitDischargeOffset) as total_los_minutes_combined
    FROM patient