SELECT 
	COUNT(DISTINCT patientunitstayid) AS vasopressors
	FROM `physionet-data.eicu_crd.infusiondrug`
    WHERE (UPPER(drugname) like '%DOBU%') OR (UPPER(drugname) like '%EPINEPHRIN%') OR (UPPER(drugname) LIKE '%ADRENALIN%') OR (UPPER(drugname) LIKE '%PHENYLEPHRIN%') OR (UPPER(drugname) LIKE '%VASOPRESSIN%')