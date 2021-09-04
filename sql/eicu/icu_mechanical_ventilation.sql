SELECT 
	COUNT(DISTINCT patientunitstayid) AS mechanical_ventilation
	FROM `physionet-data.eicu_crd.treatment`
	WHERE LOWER(treatmentstring) LIKE '%mechanical ventilation%'