WITH

length_of_stay AS (
    SELECT
        CaseID,
        TimeOfStay / 86400 + 1 AS length_of_stay_days, -- +1 to prevent skewing
        TimeOfStay / 3600 + 1 AS length_of_stay_hours -- +1 to prevent skewing
    FROM `amsterdamumcdb-data.sicdb105.cases`
),

alat AS(
    SELECT
        'alat_per_24h' AS parameter,
        lab.CaseID,
        COUNT(*) / AVG(los.length_of_stay_days) AS value
    FROM `amsterdamumcdb-data.sicdb105.laboratory` AS lab
        LEFT JOIN length_of_stay AS los
            ON lab.CaseID = los.CaseID
    WHERE lab.laboratoryID IN (
        617 -- GPT (ALT / ALAT) ZL
    )
    GROUP BY lab.CaseID
),

creatinine AS (
    SELECT
        'creatinine_per_24h' AS parameter,
        lab.CaseID,
        COUNT(*) / AVG(los.length_of_stay_days) AS value -- frequency of lab measurement per 24h per case
    FROM `amsterdamumcdb-data.sicdb105.laboratory` AS lab
        LEFT JOIN length_of_stay AS los
            ON lab.CaseID = los.CaseID
    WHERE lab.LaboratoryID IN (
        367, -- Kreatinin (ZL)
        368, -- Kreatinin enzymatisch (ZL)
        369 -- Kreatinin (HPM) (ZL)
    )
    GROUP BY lab.CaseID
),

crp AS (
    SELECT
        'crp_per_24h' AS parameter,
        lab.CaseID,
        COUNT(*) / AVG(los.length_of_stay_days) AS value
    FROM `amsterdamumcdb-data.sicdb105.laboratory` AS lab
             LEFT JOIN length_of_stay AS los
                       ON lab.CaseID = los.CaseID
    WHERE lab.LaboratoryID IN (
        341 -- C-reaktives Protein (ZL)
        )
    GROUP BY lab.CaseID
),

fio2 AS (
    SELECT
        'fio2_per_hour' AS parameter,
        data.CaseID,
        COUNT(*) / AVG(los.length_of_stay_hours) AS value
    FROM `amsterdamumcdb-data.sicdb105.data_float_h` AS data
             LEFT JOIN length_of_stay AS los
                       ON data.CaseID = los.CaseID
    WHERE data.DataID IN (
        2283 -- FIO2
        )
    GROUP BY data.CaseID
),

heart_rate AS (
  SELECT
      'heart_rate_per_hour' AS parameter,
      data.CaseID,
      COUNT(*) / AVG(los.length_of_stay_hours) AS value
  FROM `amsterdamumcdb-data.sicdb105.data_float_h` AS data
    LEFT JOIN length_of_stay AS los
     ON data.CaseID = los.CaseID
  WHERE data.DataID IN (
      707 -- HeartRateECG
      )
  GROUP BY data.CaseID
),

hemoglobin AS (
    SELECT
        'hemoglobin_per_24h' AS parameter,
        lab.CaseID,
        COUNT(*) / AVG(los.length_of_stay_days) AS value
    FROM `amsterdamumcdb-data.sicdb105.laboratory` AS lab
             LEFT JOIN length_of_stay AS los
                       ON lab.CaseID = los.CaseID
    WHERE lab.LaboratoryID IN (
        658 -- Hämoglobin (BGA)
        )
    GROUP BY lab.CaseID
),

lactate AS (
    SELECT
        'lactate_per_24h' AS parameter,
        lab.CaseID,
        COUNT(*) / AVG(los.length_of_stay_days) AS value
    FROM `amsterdamumcdb-data.sicdb105.laboratory` AS lab
        LEFT JOIN length_of_stay AS los
            ON lab.CaseID = los.CaseID
    WHERE lab.LaboratoryID IN (
        465, -- Lactat (ZL)
        657 -- Lactat (BGA)
        )
    GROUP BY lab.CaseID
),

mortality_icu AS (
    SELECT
        'mortality_icu' AS parameter,
        COUNT(*) AS value
    FROM `amsterdamumcdb-data.sicdb105.cases`
    WHERE
        OffsetOfDeath < TimeOfStay
),

mortality_28_days AS (
  SELECT
      'mortality_28_days' AS parameter,
      COUNT(*) AS value
  FROM `amsterdamumcdb-data.sicdb105.cases`
  WHERE
      OffsetOfDeath <= (TimeOfStay + (28*24*60*60))
),

fluid_out AS (
    SELECT
        'fluid_out_registrations' AS parameter,
        data.CaseID,
        COUNT(*) / AVG(los.length_of_stay_hours) AS value
    FROM `amsterdamumcdb-data.sicdb105.data_float_h` AS data
             LEFT JOIN length_of_stay AS los
                      ON data.CaseID = los.CaseID
    WHERE data.DataID IN (
        725, -- Sum of Urine
        2322 -- Drainage
        )
    GROUP BY data.CaseID
),

peep AS (
    SELECT
        'peep_per_hour' AS parameter,
        data.CaseID,
        COUNT(*) / AVG(los.length_of_stay_hours) AS value
    FROM `amsterdamumcdb-data.sicdb105.data_float_h` AS data
             LEFT JOIN length_of_stay AS los
                       ON data.CaseID = los.CaseID
    WHERE data.DataID IN (
        2278 -- PEEP
        )
    GROUP BY data.CaseID
),

po2 AS (
    SELECT
        'po2_per_24h' AS parameter,
        lab.CaseID,
        COUNT(*) / AVG(los.length_of_stay_days) AS value
    FROM `amsterdamumcdb-data.sicdb105.laboratory` AS lab
             LEFT JOIN length_of_stay AS los
                       ON lab.CaseID = los.CaseID
    WHERE lab.LaboratoryID IN (
        689 -- PO2 (BGA)
        )
    GROUP BY lab.CaseID
),

so2 AS (
  SELECT
      'so2_per_hour' AS parameter,
      data.CaseID,
      COUNT(*) / AVG(los.length_of_stay_hours) AS value
  FROM `amsterdamumcdb-data.sicdb105.data_float_h` AS data
    LEFT JOIN length_of_stay AS los
        ON data.CaseID = los.CaseID
  WHERE data.DataID IN (
        710 -- SPO2
      )
  GROUP BY data.CaseID
),

sodium AS (
    SELECT
        'sodium_per_24h' AS parameter,
        lab.CaseID,
        COUNT(*) / AVG(los.length_of_stay_days) AS value
    FROM `amsterdamumcdb-data.sicdb105.laboratory` AS lab
             LEFT JOIN length_of_stay AS los
                       ON lab.CaseID = los.CaseID
    WHERE lab.LaboratoryID IN (
        469, -- Natrium (ZL)
        686 -- Natrium (BGA)
        )
    GROUP BY lab.CaseID
),

sys_bp AS (
  SELECT
      'sys_bp_per_hour' AS parameter,
      data.CaseID,
      COUNT(*) / AVG(los.length_of_stay_hours) AS value
  FROM `amsterdamumcdb-data.sicdb105.data_float_h` AS data
    LEFT JOIN length_of_stay AS los
        ON data.CaseID = los.CaseID
  WHERE data.DataID IN (
    701, -- BloodPressureArterialSystolic
    704 -- BloodPressureNISystolic
    )
  GROUP BY data.CaseID
),

unique_admissions AS (
  SELECT
      'unique_admissions' AS parameter,
      COUNT(distinct CaseID) AS value
  FROM `amsterdamumcdb-data.sicdb105.cases`
),

unique_patients AS (
    SELECT
        'unique_patients' AS parameter,
        COUNT(distinct PatientID) AS value
    FROM `amsterdamumcdb-data.sicdb105.cases`
),

age AS (
  SELECT
      'age' AS parameter,
      AgeOnAdmission AS value
  FROM `amsterdamumcdb-data.sicdb105.cases`
),

medication_records AS (
    SELECT
        'medication_records_per_hour' AS parameter,
        med.CaseID,
        COUNT(*) / AVG(los.length_of_stay_hours) AS value
    FROM `amsterdamumcdb-data.sicdb105.medication` AS med
             LEFT JOIN length_of_stay AS los
                       ON med.CaseID = los.CaseID
    GROUP BY CaseID
),

combined AS (
    SELECT parameter, value FROM alat
    UNION ALL
    SELECT parameter, value FROM creatinine
    UNION ALL
    SELECT parameter, value FROM lactate
    UNION ALL
    SELECT parameter, value FROM sodium
    UNION ALL
    SELECT parameter, value FROM hemoglobin
    UNION ALL
    SELECT parameter, value FROM crp
    UNION ALL
    SELECT parameter, value FROM po2
    UNION ALL
    SELECT parameter, value FROM so2
    UNION ALL
    SELECT parameter, value FROM heart_rate
    UNION ALL
    SELECT parameter, value FROM sys_bp
    UNION ALL
    SELECT parameter, value FROM peep
    UNION ALL
    SELECT parameter, value FROM fio2
    UNION ALL
    SELECT parameter, value FROM fluid_out
    UNION ALL
    SELECT 'length_of_stay_days' AS parameter, length_of_stay_days as value FROM length_of_stay
    UNION ALL
    SELECT parameter, value FROM mortality_icu
    UNION ALL
    SELECT parameter, value FROM unique_admissions
    UNION ALL
    SELECT parameter, value FROM unique_patients
    UNION ALL
    SELECT parameter, value FROM age
    UNION ALL
    SELECT parameter, value FROM mortality_28_days
    UNION ALL
    SELECT parameter, value FROM medication_records
)

--resulting end view: parameter name, median of frequency, standard deviation of frequency

SELECT parameter,
       AVG(value) AS value_mean,
       STDDEV_POP(value) AS value_standardeviation,
       APPROX_QUANTILES(value, 100)[OFFSET(25)] AS value_25percentile,
       APPROX_QUANTILES(value, 100)[OFFSET(50)] AS value_median,
       APPROX_QUANTILES(value, 100)[OFFSET(75)] AS value_75percentile
FROM combined
GROUP BY parameter;