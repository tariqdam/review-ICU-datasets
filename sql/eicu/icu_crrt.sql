SELECT 
    COUNT(DISTINCT patientunitstayid) as hemodialysis
    FROM `physionet-data.eicu_crd.treatment` 
WHERE (treatmentstring LIKE '%hemodialysis%') OR (treatmentstring LIKE '%C V V H%') OR (treatmentstring LIKE '%C V V H D%') OR (treatmentstring LIKE '%ultrafiltration%')
OR (treatmentstring LIKE '%C A V H D%') OR (treatmentstring LIKE '%SLED%')