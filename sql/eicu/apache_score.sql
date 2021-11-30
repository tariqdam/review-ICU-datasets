WITH patients AS
    (SELECT
        DISTINCT(CASE
        WHEN SAFE_CAST(age AS NUMERIC) IS NULL THEN patientunitstayid ELSE 
            CASE WHEN SAFE_CAST(age AS NUMERIC) > 18 THEN patientunitstayid ELSE NULL END END) AS icu_admissions,
        hospitaldischargestatus,
        unitdischargestatus,
        unitDischargeOffset,
        FROM `physionet-data.eicu_crd.patient`
		WHERE unitdischargeoffset > 15),
    apache AS (
        SELECT a.patientunitstayid, a.apacheversion, a.apachescore
        FROM `physionet-data.eicu_crd.apachepatientresult` a
        RIGHT JOIN patients on patients.icu_admissions = a.patientunitstayid
    )
SELECT
   DISTINCT(a.apacheversion),
   COUNT(a.patientunitstayid),
   AVG(a.apachescore),
   APPROX_QUANTILES(a.apachescore, 100)[OFFSET(25)] AS iqr_25_ap,
   APPROX_QUANTILES(a.apachescore, 100)[OFFSET(50)] AS iqr_50_ap,
   APPROX_QUANTILES(a.apachescore, 100)[OFFSET(75)] AS iqr_75_ap
   FROM apache a
   GROUP BY 1
