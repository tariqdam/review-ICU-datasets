SELECT adm.admission_type, adm.hadm_id, adm.deathtime, icu.hadm_id, icu.first_careunit,
FROM physionet-data.mimiciv_hosp.admissions AS adm
inner JOIN physionet-data.mimiciv_icu.icustays AS icu ON adm.hadm_id = icu.hadm_id

-- SELECT COUNT(distinct adm.hadm_id)
-- FROM physionet-data.mimiciv_hosp.admissions AS adm
-- inner JOIN physionet-data.mimiciv_icu.icustays AS icu ON adm.hadm_id = icu.hadm_id
-- inner JOIN physionet-data.mimiciv_derived.icustay_detail AS der ON adm.hadm_id = der.hadm_id