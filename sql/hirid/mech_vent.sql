SELECT count(distinct patientid) as mech_vent
    FROM `amsterdamumcdb-data.hirid111.observation`
    WHERE (variableid = 3845 
            AND (value = 2 OR value = 3 OR value = 4 OR value = 5 OR value = 6 OR value = 7 OR value = 8 OR value = 10))
        OR (variableid = 15001552
            AND (value = 1 OR value = 2))