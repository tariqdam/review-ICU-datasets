WITH treatment AS (
SELECT 
    COUNT(DISTINCT treatmentstring) AS ecmo
    FROM `physionet-data.eicu_crd.treatment` 
WHERE (LOWER(treatmentstring) LIKE '%ecmo%') OR (LOWER(treatmentstring) LIKE '%membrane%')
),
O2 AS (
    SELECT count(distinct patientunitstayid) AS ecmo FROM `physionet-data.eicu_crd_derived.pivoted_o2` WHERE o2_device LIKE '%ECMO%'
    UNION ALL SELECT SUM(ecmo) FROM treatment
)
SELECT SUM(ecmo) AS ecmo FROM O2