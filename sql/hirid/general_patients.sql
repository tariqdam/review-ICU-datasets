SELECT count(patientid) AS admissions, count(distinct patientid) as patients,
    count(patientid)/count(distinct(patientid)) as icu_proportion,
    COUNT(CASE WHEN discharge_status = 'alive' THEN 1 ELSE NULL END) as count_alive,
    COUNT(CASE WHEN discharge_status = 'dead' THEN 1 ELSE NULL END) as count_deceased,
    COUNT(CASE WHEN discharge_status IS NULL THEN 1 ELSE NULL END) as count_unkown,
    COUNT(CASE WHEN discharge_status = 'dead' THEN 1 ELSE NULL END)/COUNT(*) as icu_mortality,
    COUNT(CASE WHEN sex = 'M' THEN 1 ELSE NULL END) AS count_male,
    COUNT(CASE WHEN sex = 'F' THEN 1 ELSE NULL END) AS count_female
    FROM `amsterdamumcdb-data.hirid111.general`