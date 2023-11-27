WITH variables AS (
    SELECT * FROM `amsterdamumcdb-data.hirid111.variables`
), pharma AS (
    SELECT * FROM `amsterdamumcdb-data.hirid111.pharma`
), ordinals AS (
    SELECT * FROM `amsterdamumcdb-data.hirid111.ordinals`
), observation AS (
    SELECT * FROM `amsterdamumcdb-data.hirid111.observation`
), general AS (
    SELECT * FROM `amsterdamumcdb-data.hirid111.general`
),

RESULT_AGE AS(
    SELECT 'age' as parameter,
            age as parameter_value,
    FROM general
),

MECH_VENT_PATIENTS AS (
    SELECT distinct patientid
    FROM `amsterdamumcdb-data.hirid111.observation`
    WHERE (variableid = 3845 
            AND (value = 2 OR value = 3 OR value = 4 OR value = 5 OR value = 6 OR value = 7 OR value = 8 OR value = 10))
        OR (variableid = 15001552
            AND (value = 1 OR value = 2))
), LOS_OBS AS (
    SELECT distinct patientid, MAX(datetime) as last_datetime
    FROM observation
    GROUP BY patientid
), LOS_PHA AS (
    SELECT distinct patientid, MAX(givenat) as last_datetime
    FROM pharma
    GROUP BY patientid
    UNION ALL SELECT * FROM LOS_OBS
), LOS_COMBINED AS (
    SELECT DISTINCT patientid, MAX(last_datetime) as last_datetime
    FROM LOS_PHA
    GROUP BY patientid
),  LOS_INT AS (
    SELECT g.patientid, g.admissiontime, c.last_datetime, TIMESTAMP_DIFF(c.last_datetime, g.admissiontime, MINUTE)/60/24 AS los
    FROM general g
    JOIN LOS_COMBINED c ON g.patientid = c.patientid
), LOS_DAYS AS (
    SELECT patientid, los+1 AS los -- +1 to prevent skewing with very short admissions
    FROM LOS_INT
    WHERE los > 0
), LOS_HOURS AS (
    SELECT patientid, los*24+1 as los -- +1 to prevent skewing with very short admissions
    FROM LOS_INT
    WHERE los*24*60 > 0
),
RESULT_LOS AS (
    SELECT 'length of stay' as parameter,
            los as parameter_value,
    FROM LOS_DAYS
),
OBS_DATA AS (
    SELECT * FROM observation
    --WHERE 
    --variableid = 4000 OR variableid = 8280 OR variableid = 
    --2010 OR variableid = 20000800 OR variableid = 20000700 OR variableid = 
    --20002600 OR variableid = 24000548 OR variableid = 20000900 OR variableid = 24000836 OR variableid = 
    --200 OR variableid = 300 OR variableid = 310 OR variableid = 5685 OR variableid = 320 OR variableid = 20002200 OR variableid = 
    --10020000 OR variableid = 100 OR variableid = 600 OR variableid = 2200 OR variableid = 8290 OR variableid = 30010009 OR variableid = 
    --24000570 OR variableid = 2600 OR variableid = 2610 OR variableid = 1000 OR variableid = 24000524 OR variableid = 24000732 OR variableid = 
    --24000485 OR variableid = 20000400 OR variableid = 24000519 OR variableid = 24000658 OR variableid = 24000835 OR variableid = 24000866 OR variableid = 
    --20000600 OR variableid = 3845 OR variableid = 15001552 OR variableid = 30005010 OR variableid = 30005110 OR variableid = 30005075 OR variableid = 30005080
),
RESULT_LACTATE AS (
    SELECT 'lactate' as parameter, o.patientid, AVG(l.los), COUNT(*) as count, COUNT(*)/AVG(l.los) as freq_per_timeinterval
    FROM OBS_DATA o
    JOIN LOS_DAYS l ON o.patientid = l.patientid
    WHERE variableid = 24000524 OR variableid = 24000732 OR variableid = 24000485
    GROUP BY o.patientid
),
RESULT_PAO2 AS (
    SELECT 'pao2' as parameter, o.patientid, AVG(l.los), COUNT(*) as count, COUNT(*)/AVG(l.los) as freq_per_timeinterval
    FROM OBS_DATA o
    JOIN LOS_DAYS l ON o.patientid = l.patientid
    WHERE variableid = 20000800
    GROUP BY o.patientid
),
RESULT_SODIUM AS (
    SELECT 'sodium' as parameter, o.patientid, AVG(l.los), COUNT(*) as count, COUNT(*)/AVG(l.los) as freq_per_timeinterval
    FROM OBS_DATA o
    JOIN LOS_DAYS l ON o.patientid = l.patientid
    WHERE variableid = 20000400 OR variableid = 24000519 OR variableid = 24000658
    OR variableid = 24000835 OR variableid = 24000866
    GROUP BY o.patientid
),
RESULT_HB AS (
    SELECT 'hemoglobin' as parameter, o.patientid, AVG(l.los), COUNT(*) as count, COUNT(*)/AVG(l.los) as freq_per_timeinterval
    FROM OBS_DATA o
    JOIN LOS_DAYS l ON o.patientid = l.patientid
    WHERE variableid = 24000548 OR variableid = 20000900 OR variableid = 24000836
    GROUP BY o.patientid
),
RESULT_LEUKO AS (
    SELECT 'leukocytes' as parameter, o.patientid, AVG(l.los), COUNT(*) as count, COUNT(*)/AVG(l.los) as freq_per_timeinterval
    FROM OBS_DATA o
    JOIN LOS_DAYS l ON o.patientid = l.patientid
    WHERE variableid = 20000700
    GROUP BY o.patientid
),
RESULT_CRP AS (
    SELECT 'crp' as parameter, o.patientid, AVG(l.los), COUNT(*) as count, COUNT(*)/AVG(l.los) as freq_per_timeinterval
    FROM OBS_DATA o
    JOIN LOS_DAYS l ON o.patientid = l.patientid
    WHERE variableid = 20002200
    GROUP BY o.patientid
),
RESULT_PCT AS (
    SELECT 'procalcitonin' as parameter, o.patientid, AVG(l.los), COUNT(*) as count, COUNT(*)/AVG(l.los) as freq_per_timeinterval
    FROM OBS_DATA o
    JOIN LOS_DAYS l ON o.patientid = l.patientid
    WHERE variableid = 24000570
    GROUP BY o.patientid
),
RESULT_CREAT AS (
    SELECT 'creatinin' as parameter, o.patientid, AVG(l.los), COUNT(*) as count, COUNT(*)/AVG(l.los) as freq_per_timeinterval
    FROM OBS_DATA o
    JOIN LOS_DAYS l ON o.patientid = l.patientid
    WHERE variableid = 20000600
    GROUP BY o.patientid
),
RESULT_ALAT AS (
    SELECT 'alat' as parameter, o.patientid, AVG(l.los), COUNT(*) as count, COUNT(*)/AVG(l.los) as freq_per_timeinterval
    FROM OBS_DATA o
    JOIN LOS_DAYS l ON o.patientid = l.patientid
    WHERE variableid = 20002600
    GROUP BY o.patientid
),

R_RESP_RATE AS (
    SELECT 'resp_rate' as parameter, o.patientid, AVG(l.los), COUNT(*) as count, COUNT(*)/AVG(l.los) as freq_per_timeinterval
    FROM OBS_DATA o
    JOIN LOS_DAYS l ON o.patientid = l.patientid
    WHERE (variableid = 300 OR variableid = 310
    OR variableid = 5685 OR variableid = 320) AND o.patientid IN (SELECT * FROM MECH_VENT_PATIENTS)
    GROUP BY o.patientid
),
R_SPO2 AS (
    SELECT 'spo2' as parameter, o.patientid, AVG(l.los), COUNT(*) as count, COUNT(*)/AVG(l.los) as freq_per_timeinterval
    FROM OBS_DATA o
    JOIN LOS_HOURS l ON o.patientid = l.patientid -- change from days to hours
    WHERE (variableid = 4000 OR variableid = 8280) AND o.patientid IN (SELECT * FROM MECH_VENT_PATIENTS)
    GROUP BY o.patientid
),
R_FIO2 AS (
    SELECT 'FiO2' as parameter, o.patientid, AVG(l.los), COUNT(*) as count, COUNT(*)/AVG(l.los) as freq_per_timeinterval
    FROM OBS_DATA o
    JOIN LOS_HOURS l ON o.patientid = l.patientid -- change from days to hours
    WHERE (variableid = 2010) AND o.patientid IN (SELECT * FROM MECH_VENT_PATIENTS)
    GROUP BY o.patientid
),
R_VentMode AS (
    SELECT 'ventmode' as parameter, o.patientid, AVG(l.los), COUNT(*) as count, COUNT(*)/AVG(l.los) as freq_per_timeinterval
    FROM OBS_DATA o
    JOIN LOS_DAYS l ON o.patientid = l.patientid
    WHERE (variableid = 3845 OR variableid = 15001552) AND o.patientid IN (SELECT * FROM MECH_VENT_PATIENTS)
    GROUP BY o.patientid
),
R_PEEP AS (
    SELECT 'PEEP' as parameter, o.patientid, AVG(l.los), COUNT(*) as count, COUNT(*)/AVG(l.los) as freq_per_timeinterval
    FROM OBS_DATA o
    JOIN LOS_HOURS l ON o.patientid = l.patientid -- change from days to hours
    WHERE (variableid = 2600 OR variableid = 2610) AND o.patientid IN (SELECT * FROM MECH_VENT_PATIENTS)
    GROUP BY o.patientid
),
R_ETCO2 AS (
    SELECT 'ETCO2' as parameter, o.patientid, AVG(l.los), COUNT(*) as count, COUNT(*)/AVG(l.los) as freq_per_timeinterval
    FROM OBS_DATA o
    JOIN LOS_DAYS l ON o.patientid = l.patientid
    WHERE (variableid = 2200 OR variableid = 8290
    OR variableid = 30010009) AND o.patientid IN (SELECT * FROM MECH_VENT_PATIENTS)
    GROUP BY o.patientid
),
R_HR AS (
    SELECT 'heart_rate' as parameter, o.patientid, AVG(l.los), COUNT(*) as count, COUNT(*)/AVG(l.los) as freq_per_timeinterval
    FROM OBS_DATA o
    JOIN LOS_HOURS l ON o.patientid = l.patientid -- change from days to hours
    WHERE variableid = 200
    GROUP BY o.patientid
),
R_SYS_BP AS (
    SELECT 'systolic_bp' as parameter, o.patientid, AVG(l.los), COUNT(*) as count, COUNT(*)/AVG(l.los) as freq_per_timeinterval
    FROM OBS_DATA o
    JOIN LOS_HOURS l ON o.patientid = l.patientid -- change from days to hours
    WHERE variableid = 100 OR variableid = 600
    GROUP BY o.patientid
),
R_CO AS (
    SELECT 'cardiac_output' as parameter, o.patientid, AVG(l.los), COUNT(*) as count, COUNT(*)/AVG(l.los) as freq_per_timeinterval
    FROM OBS_DATA o
    JOIN LOS_HOURS l ON o.patientid = l.patientid -- change from days to hours
    WHERE variableid = 1000
    GROUP BY o.patientid
),
R_FB AS (
    SELECT 'fluid_out_registration' as parameter, o.patientid, AVG(l.los), COUNT(*) as count, COUNT(*)/AVG(l.los) as freq_per_timeinterval
    FROM OBS_DATA o
    JOIN LOS_HOURS l ON o.patientid = l.patientid -- change from days to hours
    WHERE
        variableid = 10020000 -- Hourly urine volume
--        OR variableid = 30005010 -- Fluid In - cumulative over 24h, reset at 12:00pm - all fluids going into the patient e.g. infusions, drugs
       OR variableid = 30005110 -- Fluid Out - cumulative over 24h, reset at 12:00pm - all fluids leaving the patient e.g. urin, drain, evaporation (calculated)
--        OR variableid = 30005075 -- Infusion of saline solution; cumulative over 24h, reset at 12:00pm
--        OR variableid = 30005080 -- Intravenous fluid colloid administration; cumulative over 24h, reset at 12:00pm
    GROUP BY o.patientid
),
R_MED AS (
    SELECT 'medication' as parameter, o.patientid, AVG(l.los), COUNT(*) as count, COUNT(*)/AVG(l.los) as freq_per_timeinterval
    FROM pharma o
    JOIN LOS_HOURS l ON o.patientid = l.patientid -- change from days to hours
    GROUP BY o.patientid
),


COMBINED AS (
    SELECT * FROM RESULT_LOS
    UNION ALL SELECT * FROM RESULT_AGE
    UNION ALL SELECT parameter, freq_per_timeinterval FROM RESULT_LACTATE
    UNION ALL SELECT parameter, freq_per_timeinterval FROM RESULT_ALAT 
    UNION ALL SELECT parameter, freq_per_timeinterval FROM RESULT_CREAT 
    UNION ALL SELECT parameter, freq_per_timeinterval FROM RESULT_CRP 
    UNION ALL SELECT parameter, freq_per_timeinterval FROM RESULT_HB 
    UNION ALL SELECT parameter, freq_per_timeinterval FROM RESULT_PAO2 
    UNION ALL SELECT parameter, freq_per_timeinterval FROM RESULT_PCT 
    UNION ALL SELECT parameter, freq_per_timeinterval FROM RESULT_LEUKO 
    UNION ALL SELECT parameter, freq_per_timeinterval FROM RESULT_SODIUM
    UNION ALL SELECT parameter, freq_per_timeinterval FROM R_RESP_RATE 
    UNION ALL SELECT parameter, freq_per_timeinterval FROM R_SPO2 
    UNION ALL SELECT parameter, freq_per_timeinterval FROM R_FIO2 
    UNION ALL SELECT parameter, freq_per_timeinterval FROM R_VentMode 
    UNION ALL SELECT parameter, freq_per_timeinterval FROM R_PEEP 
    UNION ALL SELECT parameter, freq_per_timeinterval FROM R_ETCO2 
    UNION ALL SELECT parameter, freq_per_timeinterval FROM R_HR 
    UNION ALL SELECT parameter, freq_per_timeinterval FROM R_SYS_BP
    UNION ALL SELECT parameter, freq_per_timeinterval FROM R_CO 
    UNION ALL SELECT parameter, freq_per_timeinterval FROM R_FB
    UNION ALL SELECT parameter, freq_per_timeinterval FROM R_MED

)
SELECT  parameter,
        AVG(parameter_value) AS avg,
        STDDEV_POP(parameter_value) AS std,
        APPROX_QUANTILES(parameter_value, 100)[OFFSET(100)] AS perc_100,
        APPROX_QUANTILES(parameter_value, 100)[OFFSET(75)] AS perc_75,
        APPROX_QUANTILES(parameter_value, 100)[OFFSET(50)] AS perc_50,
        APPROX_QUANTILES(parameter_value, 100)[OFFSET(25)] AS perc_25,
        APPROX_QUANTILES(parameter_value, 100)[OFFSET(0)] AS perc_0
        FROM COMBINED
        GROUP BY parameter



