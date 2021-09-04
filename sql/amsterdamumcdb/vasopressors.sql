SELECT lab.admissionid, lab.item, lab.value, lab.unit, lab.measuredat 
FROM `amsterdamumcdb-data.ams102.numericitems` lab
WHERE itemid = 7229
OR itemid= 6818
OR itemid= 6992