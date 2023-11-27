SELECT
    adm.admission_type,
    adm.hadm_id,
--     adm.deathtime, replaced with dod from mimiciv_derived
    icu.first_careunit,
    der.dod,
    der.icu_intime,
    der.icu_outtime,
    CASE WHEN der.dod BETWEEN der.icu_intime AND der.icu_outtime THEN 1 ELSE 0 END AS icu_mortality
FROM physionet-data.mimiciv_hosp.admissions AS adm
inner JOIN physionet-data.mimiciv_icu.icustays AS icu ON adm.hadm_id = icu.hadm_id
-- FROM physionet-data.mimiciv_icu.icustays AS icu
inner JOIN physionet-data.mimiciv_derived.icustay_detail AS der ON icu.stay_id = der.stay_id