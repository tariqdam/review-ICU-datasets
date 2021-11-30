WITH patients AS
    (SELECT
        DISTINCT(CASE
        WHEN SAFE_CAST(age AS NUMERIC) IS NULL THEN patientunitstayid ELSE 
            CASE WHEN SAFE_CAST(age AS NUMERIC) > 18 THEN patientunitstayid ELSE NULL END END) AS icu_admissions,
        hospitaldischargestatus,
        unitdischargestatus,
        unitDischargeOffset,
        FROM `physionet-data.eicu_crd.patient`
		WHERE unitdischargeoffset > 15)
,elective AS (
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
elective_mort AS (
    SELECT
    'elective' as type,
    COUNT(CASE WHEN unitdischargestatus = 'Expired' THEN 1 ELSE NULL END) unit_expired_count,
    COUNT(CASE WHEN unitdischargestatus = 'Alive' THEN 1 ELSE NULL END) unit_alive_count,
    COUNT(CASE WHEN unitdischargestatus = 'Alive' OR unitdischargestatus = 'Expired' THEN NULL ELSE 1 END) unit_missing_count,
    COUNT(CASE WHEN unitdischargestatus = 'Expired' THEN 1 ELSE NULL END) / (COUNT(CASE WHEN unitdischargestatus = 'Expired' THEN 1 ELSE NULL END) + COUNT(CASE WHEN unitdischargestatus = 'Alive' THEN 1 ELSE NULL END)) icu_mortality,
    FROM patients
    INNER JOIN elective ON patients.icu_admissions = elective.elective
),
non_elective_mort AS (
    SELECT
    'non_elective' as type,
    COUNT(CASE WHEN unitdischargestatus = 'Expired' THEN 1 ELSE NULL END) unit_expired_count,
    COUNT(CASE WHEN unitdischargestatus = 'Alive' THEN 1 ELSE NULL END) unit_alive_count,
    COUNT(CASE WHEN unitdischargestatus = 'Alive' OR unitdischargestatus = 'Expired' THEN NULL ELSE 1 END) unit_missing_count,
    COUNT(CASE WHEN unitdischargestatus = 'Expired' THEN 1 ELSE NULL END) / (COUNT(CASE WHEN unitdischargestatus = 'Expired' THEN 1 ELSE NULL END) + COUNT(CASE WHEN unitdischargestatus = 'Alive' THEN 1 ELSE NULL END)) icu_mortality,
    FROM patients
    INNER JOIN non_elective ON patients.icu_admissions = non_elective.non_elective
)
    SELECT *
    FROM elective_mort
    UNION ALL SELECT * FROM non_elective_mort
