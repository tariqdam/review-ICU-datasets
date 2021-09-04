WITH patients AS (
    SELECT DISTINCT(pat.patientunitstayid) AS icu_admissions,
    FROM `physionet-data.eicu_crd.patient` pat
    WHERE unitdischargeoffset  > 15
),
non_operative AS (
    SELECT COUNT(DISTINCT(admit.patientunitstayid)) AS non_operative
    FROM `physionet-data.eicu_crd.admissiondx` admit
    RIGHT JOIN patients pat ON pat.icu_admissions = admit.patientunitstayid
    WHERE admit.admitdxpath LIKE '%Non-operative%'
),
operative AS (
    SELECT COUNT(DISTINCT(admit.patientunitstayid)) AS operative
    FROM `physionet-data.eicu_crd.admissiondx` admit
    RIGHT JOIN patients pat ON pat.icu_admissions = admit.patientunitstayid
    WHERE admit.admitdxpath LIKE '%Operative%'
),
elective AS (
    SELECT COUNT(DISTINCT(admit.patientunitstayid)) AS elective
    FROM `physionet-data.eicu_crd.admissiondx` admit
    RIGHT JOIN patients pat ON pat.icu_admissions = admit.patientunitstayid
    WHERE admit.admitdxpath LIKE '%admission diagnosis|Elective|Yes%'
),
non_elective AS (
    SELECT COUNT(DISTINCT(admit.patientunitstayid)) AS non_elective
    FROM `physionet-data.eicu_crd.admissiondx` admit
    RIGHT JOIN patients pat ON pat.icu_admissions = admit.patientunitstayid
    WHERE admit.admitdxpath LIKE '%admission diagnosis|Elective|No%'
),
pat_count AS (
    SELECT COUNT(pat.icu_admissions) AS pat_count
    FROM patients pat
),
unknown_operative AS (
    SELECT p.pat_count - n.non_operative - o.operative as unknown_operative
    FROM pat_count p, non_operative n, operative o
),
unknown_elective AS (
    SELECT p.pat_count - n.non_elective - e.elective as unknown_elective
    FROM pat_count p, non_elective n, elective e
)
SELECT  'unique_admisisons' as param, pat_count
    FROM pat_count
    UNION ALL SELECT 'non_operative' as param, non_operative FROM non_operative
    UNION ALL SELECT 'operative' as param, operative FROM operative
    UNION ALL SELECT 'elective' as param, elective FROM elective
    UNION ALL SELECT 'non_elective' as param, non_elective FROM non_elective
    UNION ALL
        SELECT 'unknown_operative' as param, unknown_operative
        FROM unknown_operative
    UNION ALL 
        SELECT 'unknown_elective' as param, unknown_elective 
        FROM unknown_elective
