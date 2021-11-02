SELECT
    DISTINCT ethnicity, COUNT(ethnicity)
    FROM `physionet-data.eicu_crd.patient`
    WHERE patientunitstayid in (SELECT DISTINCT(patientunitstayid)
        FROM `physionet-data.eicu_crd.patient`
        WHERE unitdischargeoffset  > 15)
    GROUP BY 1
