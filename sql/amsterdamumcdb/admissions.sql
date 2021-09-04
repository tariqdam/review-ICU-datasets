WITH ONE AS (
    SELECT  patientid,
            admissionid,
            agegroup,
            admittedat,
            dischargedat,
            dateofdeath,
            specialty,
            urgency
    FROM `amsterdamumcdb-data.ams102.admissions`),
AGE AS (
    SELECT DISTINCT agegroup, COUNT(*)
    FROM `amsterdamumcdb-data.ams102.admissions`
    GROUP BY 1 
)
SELECT
    * FROM ONE
    --COUNT (DISTINCT admissionid) AS unique_icu_admissions,
    --COUNT (DISTINCT patientid) AS unique_icu_patients,
    --COUNT (DISTINCT admissionid) / COUNT (DISTINCT patientid) AS icu_admissions_proportions,
    --COUNT (dateofdeath)
--FROM `amsterdamumcdb-data.ams102.admissions`
