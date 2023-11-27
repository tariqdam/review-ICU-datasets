SELECT COUNT(DISTINCT patientid) AS crrt_count
FROM `amsterdamumcdb-data.hirid111.observation`
WHERE variableid = 10002508 AND value = 1 -- Haemofiltration/CRRT