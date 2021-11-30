WITH patients AS (
    SELECT patientid, admissiontime
    FROM `amsterdamumcdb-data.hirid111.general`
), apache_score AS (
    SELECT patientid, datetime, status, stringvalue, value FROM `amsterdamumcdb-data.hirid111.observation` WHERE variableid = 30000140
), filtered AS (
    SELECT DISTINCT(apache_score.patientid), min(apache_score.datetime), apache_score.value
    FROM apache_score
    LEFT JOIN patients on patients.patientid = apache_score.patientid
    WHERE patients.admissiontime > TIMESTAMP_SUB(apache_score.datetime, INTERVAL 24 HOUR)
    GROUP BY 1, 3
)
   SELECT
        COUNT(DISTINCT(patientid)) as pat_num,
        COUNT(patientid) as tot_num,
        AVG(value) as avg_tot_num,
        APPROX_QUANTILES(value, 100)[OFFSET(25)] AS iqr_25_ap2,
        APPROX_QUANTILES(value, 100)[OFFSET(50)] AS iqr_50_ap2,
        APPROX_QUANTILES(value, 100)[OFFSET(75)] AS iqr_75_ap2
    FROM filtered
