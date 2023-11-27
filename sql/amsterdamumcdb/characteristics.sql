WITH
-- create helping tables: complete table of numericitems: validated + unvalidated & length_of_stay table
numericitems_total AS (
    SELECT *
    FROM `amsterdamumcdb-data.ams102.numericitems`
    UNION ALL
    SELECT *
    FROM `amsterdamumcdb-data.ams102.numericitems_unvalidated`
),

length_of_stay AS (
    SELECT
    admissionid as admissionid,
    admittedat as admittedat,
    dischargedat as dischargedat,
    lengthofstay / 24 + 1 AS lengthofstay_days, -- + 1 to prevent very small LOS numbers from skewing the frequency results
    lengthofstay+1 AS lengthofstay_hours -- + 1 to prevent very small LOS numbers from skewing the frequency results
    FROM `amsterdamumcdb-data.ams102.admissions`
    WHERE lengthofstay >= 1
),

-- parameter name, count per admission, length of stay per admission, count divided by length of stay and combine them

unique_admissions as (
    SELECT
    'unique_admissions' as parameter,
    count (distinct admissionid) as value
    FROM `amsterdamumcdb-data.ams102.admissions`
    ),

unique_patients as (
    SELECT
    'unique_patients' as parameter,
    count (distinct patientid) as value
    FROM `amsterdamumcdb-data.ams102.admissions`
    ),

reason_for_admission_non_elective AS (
  SELECT
      'reason_for_admission_non_elective' AS parameter,
      COUNT(DISTINCT(admissionid)) AS value
  FROM `amsterdamumcdb-data.ams102.admissions`
  WHERE urgency = 1
),

reason_for_admission_elective AS (
  SELECT
      'reason_for_admission_elective' AS parameter,
      COUNT(DISTINCT(admissionid)) AS value
  FROM `amsterdamumcdb-data.ams102.admissions`
  WHERE urgency = 0
),

reason_for_admission_operative AS (
  SELECT
      'reason_for_admission_operative' AS parameter,
      COUNT(DISTINCT(admissionid)) AS value
  FROM `amsterdamumcdb-data.ams102.listitems`
  WHERE
      itemid IN (
                --SURGICAL
                 13116, --D_Thoraxchirurgie_CABG en Klepchirurgie
                 16671, --DMC_Thoraxchirurgie_CABG en Klepchirurgie
                 13117, --D_Thoraxchirurgie_Cardio anders
                 16672, --DMC_Thoraxchirurgie_Cardio anders
                 13118, --D_Thoraxchirurgie_Aorta chirurgie
                 16670, --DMC_Thoraxchirurgie_Aorta chirurgie
                 13119, --D_Thoraxchirurgie_Pulmonale chirurgie
                 16673, --DMC_Thoraxchirurgie_Pulmonale chirurgie

                --Not surgical: 13141, --D_Algemene chirurgie_Algemeen
                --Not surgical: 16642, --DMC_Algemene chirurgie_Algemeen
                 13121, --D_Algemene chirurgie_Buikchirurgie
                 16643, --DMC_Algemene chirurgie_Buikchirurgie
                 13123, --D_Algemene chirurgie_Endocrinologische chirurgie
                 16644, --DMC_Algemene chirurgie_Endocrinologische chirurgie
                 13145, --D_Algemene chirurgie_KNO/Overige
                 16645, --DMC_Algemene chirurgie_KNO/Overige
                 13125, --D_Algemene chirurgie_Orthopedische chirurgie
                 16646, --DMC_Algemene chirurgie_Orthopedische chirurgie
                 13122, --D_Algemene chirurgie_Transplantatie chirurgie
                 16647, --DMC_Algemene chirurgie_Transplantatie chirurgie
                 13124, --D_Algemene chirurgie_Trauma
                 16648, --DMC_Algemene chirurgie_Trauma
                 13126, --D_Algemene chirurgie_Urogenitaal
                 16649, --DMC_Algemene chirurgie_Urogenitaal
                 13120, --D_Algemene chirurgie_Vaatchirurgie
                 16650, --DMC_Algemene chirurgie_Vaatchirurgie

                 13128, --D_Neurochirurgie _Vasculair chirurgisch
                 16661, --DMC_Neurochirurgie _Vasculair chirurgisch
                 13129, --D_Neurochirurgie _Tumor chirurgie
                 16660, --DMC_Neurochirurgie _Tumor chirurgie
                 13130, --D_Neurochirurgie_Overige
                 16662, --DMC_Neurochirurgie_Overige

                 18596, --Apache II Operatief  Gastr-intenstinaal
                 18597, --Apache II Operatief Cardiovasculair
                 18598, --Apache II Operatief Hematologisch
                 18599, --Apache II Operatief Metabolisme
                 18600, --Apache II Operatief Neurologisch
                 18601, --Apache II Operatief Renaal
                 18602, --Apache II Operatief Respiratoir

                 17008, --APACHEIV Post-operative cardiovascular
                 17009, --APACHEIV Post-operative gastro-intestinal
                 17010, --APACHEIV Post-operative genitourinary
                 17011, --APACHEIV Post-operative hematology
                 17012, --APACHEIV Post-operative metabolic
                 17013, --APACHEIV Post-operative musculoskeletal /skin
                 17014, --APACHEIV Post-operative neurologic
                 17015, --APACHEIV Post-operative respiratory
                 17016, --APACHEIV Post-operative transplant
                 17017 --APACHEIV Post-operative trauma
          )
        OR (itemid = 18669 AND valueid BETWEEN 1 AND 26)
        OR (itemid = 18671 AND valueid BETWEEN 222 AND 452)
),

reason_for_admission_non_operative AS (
  SELECT
      'reason_for_admission_non_operative' AS parameter,
      COUNT(DISTINCT(admissionid)) AS value
  FROM `amsterdamumcdb-data.ams102.listitems`
  WHERE
      itemid IN (
          --MEDICAL
                 13133, --D_Interne Geneeskunde_Cardiovasculair
                 16653, --DMC_Interne Geneeskunde_Cardiovasculair
                 13134, --D_Interne Geneeskunde_Pulmonaal
                 16658, --DMC_Interne Geneeskunde_Pulmonaal
                 13135, --D_Interne Geneeskunde_Abdominaal
                 16652, --DMC_Interne Geneeskunde_Abdominaal
                 13136, --D_Interne Geneeskunde_Infectieziekten
                 16655, --DMC_Interne Geneeskunde_Infectieziekten
                 13137, --D_Interne Geneeskunde_Metabool
                 16656, --DMC_Interne Geneeskunde_Metabool
                 13138, --D_Interne Geneeskunde_Renaal
                 16659, --DMC_Interne Geneeskunde_Renaal
                 13139, --D_Interne Geneeskunde_Hematologisch
                 16654, --DMC_Interne Geneeskunde_Hematologisch
                 13140, --D_Interne Geneeskunde_Overige
                 16657, --DMC_Interne Geneeskunde_Overige

                 13131, --D_Neurologie_Vasculair neurologisch
                 16664, --DMC_Neurologie_Vasculair neurologisch
                 13132, --D_Neurologie_Overige
                 16663, --DMC_Neurologie_Overige
                 13127, --D_KNO/Overige

                 18589, --Apache II Non-Operatief Cardiovasculair
                 18590, --Apache II Non-Operatief Gastro-intestinaal
                 18591, --Apache II Non-Operatief Hematologisch
                 18592, --Apache II Non-Operatief Metabolisme
                 18593, --Apache II Non-Operatief Neurologisch
                 18594, --Apache II Non-Operatief Renaal
                 18595, --Apache II Non-Operatief Respiratoir

                 16998, --APACHE IV Non-operative cardiovascular
                 16999, --APACHE IV Non-operative Gastro-intestinal
                 17000, --APACHE IV Non-operative genitourinary
                 17001, --APACHEIV  Non-operative haematological
                 17002, --APACHEIV  Non-operative metabolic
                 17003, --APACHEIV Non-operative musculo-skeletal
                 17004, --APACHEIV Non-operative neurologic
                 17005, --APACHEIV Non-operative respiratory
                 17006, --APACHEIV Non-operative transplant
                 17007 --APACHEIV Non-operative trauma
          )
        OR (itemid = 18669 AND valueid NOT BETWEEN 1 AND 26)
        OR (itemid = 18671 AND valueid NOT BETWEEN 222 AND 452)
),

gender AS(
    SELECT
        'gender' as parameter,
        count(case when gender="Man" then 1 end) as value
    FROM `amsterdamumcdb-data.ams102.admissions`
),

alat as(
    select
        'alat per 24h' as parameter,
        n.admissionid as admissionid,
        count(*) as count,
        AVG(l.lengthofstay_days) as lengthofstay, -- AVG aggregation step necessary for group by
        count(*) / AVG(l.lengthofstay_days) as value
    from numericitems_total n JOIN length_of_stay l on n.admissionid = l.admissionid
    where n.itemid IN (
        6800,
        11978,
        11979,
        18847)
    AND n.value is not null
    AND n.admissionid is not null
    AND n.measuredat >= l.admittedat
    AND n.measuredat <= l.dischargedat
    GROUP BY n.admissionid
),

cardiac_output as(
    select
        'cardiac_output_per_hour' as parameter,
        n.admissionid as admissionid,
        count(*) as count,
        AVG(l.lengthofstay_days) as lengthofstay, -- AVG aggregation step necessary for group by
        count(*) / AVG(l.lengthofstay_hours) as value
    from numericitems_total n left join length_of_stay l on n.admissionid = l.admissionid
    where n.itemid IN (
                        13151,
                        6656
                      )
      AND n.value is not null
      AND n.admissionid is not null
      AND n.measuredat >= l.admittedat
      AND n.measuredat <= l.dischargedat
    GROUP BY n.admissionid
),

creatinine AS (
    select 'creatinine per 24h' as parameter,
           n.admissionid as admissionsid,
           count(*) as count,
           AVG(l.lengthofstay_days) as lengthofstay,
           count(*) / AVG(l.lengthofstay_days) as value
    from numericitems_total n left join length_of_stay l on n.admissionid = l.admissionid
    where n.itemid IN (
        6836,
        9941
                      )
    AND n.value is not null
    AND n.admissionid is not null
    AND n.measuredat >= l.admittedat
    AND n.measuredat <= l.dischargedat
    GROUP BY n.admissionid
),

crp AS (
    select 'crp per 24h' as parameter,
           n.admissionid as admissionsid,
           count(*) as count,
           AVG(l.lengthofstay_days) as lengthofstay,
           count(*) / AVG(l.lengthofstay_days) as value
    from numericitems_total n left join length_of_stay l on n.admissionid = l.admissionid
    where n.itemid IN (
                       6825,
                       10079,
                       18854
                      )
    AND n.value is not null
    AND n.admissionid is not null
    AND n.measuredat >= l.admittedat
    AND n.measuredat <= l.dischargedat
    GROUP BY n.admissionid
),

 etCO2 as(
    select
        'etCO2 per 24h' as parameter,
        n.admissionid as admissionid,
        count(*) as count,
        AVG(l.lengthofstay_days) as lengthofstay, -- AVG aggregation step necessary for group by
        count(*) / AVG(l.lengthofstay_days) as value
    from numericitems_total n left join length_of_stay l on n.admissionid = l.admissionid
    where n.itemid IN (
        6707,
        12356,
        9658,
        8884
        )
      AND n.value is not null
      AND n.admissionid is not null
      AND n.measuredat >= l.admittedat
      AND n.measuredat <= l.dischargedat
    GROUP BY n.admissionid
),

fio2 as(
    select
        'fio2_per_hour' as parameter,
        n.admissionid as admissionid,
        count(*) as count,
        AVG(l.lengthofstay_hours) as lengthofstay, -- AVG aggregation step necessary for group by
        count(*) / AVG(l.lengthofstay_hours) as value
    from numericitems_total n left join length_of_stay l on n.admissionid = l.admissionid
    where n.itemid IN (
        6699,
        20134
        )
      AND n.value is not null
      AND n.admissionid is not null
      AND n.measuredat >= l.admittedat
      AND n.measuredat <= l.dischargedat
    GROUP BY n.admissionid
),

fluids_out as(
    select
        'fluids_out_per_hour' as parameter,
        n.admissionid as admissionid,
        count(*) as count,
        AVG(l.lengthofstay_hours) as lengthofstay, -- AVG aggregation step necessary for group by
        count(*) / AVG(l.lengthofstay_hours) as value
    from numericitems_total n left join length_of_stay l on n.admissionid = l.admissionid
    where n.itemid IN (
                       8699, --Thoraxdrain1 Productie
                       8700, --Thoraxdrain2 Productie
                       8701, --Thoraxdrain3 Productie
                       8717, --Wonddrain1 Productie
                       8719, --Wonddrain2 Productie
                       8720, --Wonddrain3 Productie
                       8721, --Wonddrain4 Productie
                       8770, --Ventrikeldrain1 Uit
                       8772, --Pericarddrain Uit
                       12503, --Thoraxdrain4 Productie
                       12504, --Thoraxdrain5 Productie
                       12506, --Thoraxdrain6 Productie
                       10592, --Ascitespunctie
                       10595, --Pleurapunctie
                       9626, --Wondlekkage
                       14428, --Wonddrain5 Productie
                       14429, --Wonddrain6 Productie
                       12553, --Fistel
                       8774, --Maaghevel
                       8777, --MaagRetentieWeg
                       8780, --Braken
                       8782, --Sengtaken
                       8925, --Maagzuig
                       12580, --Galdrain Uit
                       8784, --Jejunostoma
                       8786, --Ileostoma
                       8788, --Colostoma
                       8789, --Ontlasting
                       8792, --Bloedverlies
                       8794, --UrineCAD
                       8796, --UrineSupraPubis
                       8798, --UrineSpontaan
                       8800, --UrineIncontinentie
                       8803, --UrineUP
                       10743, --Nefrodrain li Uit
                       10745, --Nefrodrain re Uit
                       19921, --UrineSplint Li
                       19922, --UrineSplint Re
                       8805, --CVVH Onttrokken
                       8806, --Hemodialyse onttrekken
                       8808, --Peritoneaaldialyse
                       9564, --NDT-syst.
                       9360, --Lumbaaldrain Uit
                       15257, --Cisternale drain Uit
                       13031, --Spinaaldrain Uit
                       13495, --Ventrikeldrain2 Uit
                       10597, --Liquorpunctie
                       12792 --Kolven
        )
      AND n.value is not null
      AND n.admissionid is not null
      AND n.measuredat >= l.admittedat
      AND n.measuredat <= l.dischargedat
    GROUP BY n.admissionid
),

heart_rate as(
    select
        'heart_rate_per_hour' as parameter,
        n.admissionid as admissionid,
        count(*) as count,
        AVG(l.lengthofstay_hours) as lengthofstay, -- AVG aggregation step necessary for group by
        count(*) / AVG(l.lengthofstay_hours) as value
    from numericitems_total n left join length_of_stay l on n.admissionid = l.admissionid
    where n.itemid IN (
        6640,
        13075
        )
      AND n.value is not null
      AND n.admissionid is not null
      AND n.measuredat >= l.admittedat
      AND n.measuredat <= l.dischargedat
    GROUP BY n.admissionid
),

hemoglobin as(
    select
        'hemoglobin_per_24h' as parameter,
        n.admissionid as admissionid,
        count(*) as count,
        AVG(l.lengthofstay_days) as lengthofstay, -- AVG aggregation step necessary for group by
        count(*) / AVG(l.lengthofstay_days) as value
    from numericitems_total n left join length_of_stay l on n.admissionid = l.admissionid
    where n.itemid IN (
        6778,
        9960,
        10286
        )
      AND n.value is not null
      AND n.admissionid is not null
      AND n.measuredat >= l.admittedat
      AND n.measuredat <= l.dischargedat
    GROUP BY n.admissionid
),

lactate as(
    select
        'lactate_per_24h' as parameter,
        n.admissionid as admissionid,
        count(*) as count,
        AVG(l.lengthofstay_days) as lengthofstay, -- AVG aggregation step necessary for group by
        count(*) / AVG(l.lengthofstay_days) as value
    from numericitems_total n left join length_of_stay l on n.admissionid = l.admissionid
    where n.itemid IN (
        10053,
        10304,
        6837,
        9580
        )
      AND n.value is not null
      AND n.admissionid is not null
      AND n.measuredat >= l.admittedat
      AND n.measuredat <= l.dischargedat
    GROUP BY n.admissionid
),

leukocytes as(
    select
        'leukocytes_per_24h' as parameter,
        n.admissionid as admissionid,
        count(*) as count,
        AVG(l.lengthofstay_days) as lengthofstay, -- AVG aggregation step necessary for group by
        count(*) / AVG(l.lengthofstay_days) as value
    from numericitems_total n left join length_of_stay l on n.admissionid = l.admissionid
    where n.itemid IN (
        6779,
        9965
        )
      AND n.value is not null
      AND n.admissionid is not null
      AND n.measuredat >= l.admittedat
      AND n.measuredat <= l.dischargedat
    GROUP BY n.admissionid
),

o2_sat_peripheral as(
    select
        'o2_sat_peripheral_per_hour' as parameter,
        n.admissionid as admissionid,
        count(*) as count,
        AVG(l.lengthofstay_hours) as lengthofstay, -- AVG aggregation step necessary for group by
        count(*) / AVG(l.lengthofstay_hours) as value
    from numericitems_total n left join length_of_stay l on n.admissionid = l.admissionid
    where n.itemid IN (
        8903,
        11543,
        11425,
        12311,
        6709
        )
      AND n.value is not null
      AND n.admissionid is not null
      AND n.measuredat >= l.admittedat
      AND n.measuredat <= l.dischargedat
    GROUP BY n.admissionid
),

peep as(
    select
        'peep_per_hours' as parameter,
        n.admissionid as admissionid,
        count(*) as count,
        AVG(l.lengthofstay_hours) as lengthofstay, -- AVG aggregation step necessary for group by
        count(*) / AVG(l.lengthofstay_hours) as value
    from numericitems_total n left join length_of_stay l on n.admissionid = l.admissionid
    where n.itemid IN (
        8879,
        8882,
        9661,
        9666,
        12284,
        12301,
        12364,
        16250
        )
      AND n.value is not null
      AND n.admissionid is not null
      AND n.measuredat >= l.admittedat
      AND n.measuredat <= l.dischargedat
    GROUP BY n.admissionid
),

po2 as(
    select
        'po2_per_24h' as parameter,
        n.admissionid as admissionid,
        count(*) as count,
        AVG(l.lengthofstay_days) as lengthofstay, -- AVG aggregation step necessary for group by
        count(*) / AVG(l.lengthofstay_days) as value
    from numericitems_total n left join length_of_stay l on n.admissionid = l.admissionid
    where n.itemid IN (
        21214,
        7433,
        9996
        )
      AND n.value is not null
      AND n.admissionid is not null
      AND n.measuredat >= l.admittedat
      AND n.measuredat <= l.dischargedat
    GROUP BY n.admissionid
),

resp_rate as(
    select
        'resp_rate_per_hour' as parameter,
        n.admissionid as admissionid,
        count(*) as count,
        AVG(l.lengthofstay_hours) as lengthofstay, -- AVG aggregation step necessary for group by
        count(*) / AVG(l.lengthofstay_hours) as value
    from numericitems_total n left join length_of_stay l on n.admissionid = l.admissionid
    where n.itemid IN (
        7726,
        8873,
        8874,
        9654,
        12266,
        12283,
        12348,
        12577
        )
      AND n.value is not null
      AND n.admissionid is not null
      AND n.measuredat >= l.admittedat
      AND n.measuredat <= l.dischargedat
    GROUP BY n.admissionid
),

sodium as(
    select
        'sodium_per_24h' as parameter,
        n.admissionid as admissionid,
        count(*) as count,
        AVG(l.lengthofstay_days) as lengthofstay, -- AVG aggregation step necessary for group by
        count(*) / AVG(l.lengthofstay_days) as value
    from numericitems_total n left join length_of_stay l on n.admissionid = l.admissionid
    where n.itemid IN (
        6840,
        9555,
        9924
        )
      AND n.value is not null
      AND n.admissionid is not null
      AND n.measuredat >= l.admittedat
      AND n.measuredat <= l.dischargedat
    GROUP BY n.admissionid
),

sys_bp as(
    select
        'sys_bp_per_hour' as parameter,
        n.admissionid as admissionid,
        count(*) as count,
        AVG(l.lengthofstay_hours) as lengthofstay, -- AVG aggregation step necessary for group by
        count(*) / AVG(l.lengthofstay_hours) as value
    from numericitems_total n left join length_of_stay l on n.admissionid = l.admissionid
    where n.itemid IN (
        6641,
        6678,
        8841
        )
      AND n.value is not null
      AND n.admissionid is not null
      AND n.measuredat >= l.admittedat
      AND n.measuredat <= l.dischargedat
    GROUP BY n.admissionid
),

icu_mortality_overall AS (
    SELECT
        'mortality_overall' as parameter,
        count(*) as value
    FROM `amsterdamumcdb-data.ams102.admissions`
    WHERE dateofdeath < dischargedat
),

icu_mortality_elective AS (
  SELECT
      'mortality_elective' AS parameter,
      COUNT(*) AS value
  FROM `amsterdamumcdb-data.ams102.admissions`
  WHERE (dateofdeath < dischargedat)
  AND (urgency = 0)
),

icu_mortality_non_elective AS (
    SELECT
        'mortality_non_elective' AS parameter,
        COUNT(*) AS value
    FROM `amsterdamumcdb-data.ams102.admissions`
    WHERE (dateofdeath < dischargedat)
    AND (urgency = 1)
),

icu_mortality_28days AS (
    SELECT
        'mortality_28days' AS parameter,
        COUNT(*) AS value
    FROM `amsterdamumcdb-data.ams102.admissions`
    WHERE (dateofdeath < (dischargedat + 2419200000)) -- 28 days = 2 419 200 000 ms
),

age AS (
    SELECT
        COUNT(CASE WHEN agegroup = '18-39' THEN admissionid END) AS age_18_39,
        COUNT(CASE WHEN agegroup = '40-49' THEN admissionid END) AS age_40_49,
        COUNT(CASE WHEN agegroup = '50-59' THEN admissionid END) AS age_50_59,
        COUNT(CASE WHEN agegroup = '60-69' THEN admissionid END) AS age_60_69,
        COUNT(CASE WHEN agegroup = '70-79' THEN admissionid END) AS age_70_79,
        COUNT(CASE WHEN agegroup = '80+' THEN admissionid END) AS age_80
    FROM `amsterdamumcdb-data.ams102.admissions`
),

vasopressor_usage AS (
  SELECT
      'vasopressor_usage' AS parameter,
      COUNT(DISTINCT admissionid) AS value
  FROM `amsterdamumcdb-data.ams102.drugitems`
  WHERE
        ordercategoryid = 65 -- continuous i.v. perfusor
        AND itemid IN (
           6818, -- Adrenaline (Epinefrine)
           7135, -- Isoprenaline (Isuprel)
           7178, -- Dobutamine (Dobutrex)
           7179, -- Dopamine (Inotropin)
           7196, -- Enoximon (Perfan)
           7229, -- Noradrenaline (Norepinefrine)
           12467, -- Terlipressine (Glypressin)
           13490, -- Methyleenblauw IV (Methylthionide cloride)
           19929 -- Fenylefrine
        )
        AND rate > 0.1
),

mech_vent_usage AS (
    SELECT
        'mech_vent_usage' AS parameter,
        COUNT(DISTINCT admissionid) AS value
    FROM `amsterdamumcdb-data.ams102.listitems`
    WHERE
        (
        itemid = 9534  --Type beademing Evita 1
        AND valueid IN (
            1, --IPPV
            2, --IPPV_Assist
            3, --CPPV
            4, --CPPV_Assist
            5, --SIMV
            6, --SIMV_ASB
            7, --ASB
            8, --CPAP
            9, --CPAP_ASB
            10, --MMV
            11, --MMV_ASB
            12, --BIPAP
            13 --Pressure Controled
                )
            )
       OR (
            itemid = 6685 --Type Beademing Evita 4
            AND valueid IN (
                1, --CPPV
                3, --ASB
                5, --CPPV/ASSIST
                6, --SIMV/ASB
                8, --IPPV
                9, --IPPV/ASSIST
                10, --CPAP
                11, --CPAP/ASB
                12, --MMV
                13, --MMV/ASB
                14, --BIPAP
                20, --BIPAP-SIMV/ASB
                22 --BIPAP/ASB
            )
        )
       OR (
        itemid = 8189 --Toedieningsweg O2
        AND valueid = 16 --CPAP
        )
       OR (
        itemid IN (
           12290, --Ventilatie Mode (Set) - Servo-I and Servo-U ventilators
           12347 --Ventilatie Mode (Set) (2) Servo-I and Servo-U ventilators
        )
        AND valueid IN (
            --IGNORE: 1, --Stand By
            2, --PC
            3, --VC
            4, --PRVC
            5, --VS
            6, --SIMV(VC)+PS
            7, --SIMV(PC)+PS
            8, --PS/CPAP
            9, --Bi Vente
            10, --PC (No trig)
            11, --VC (No trig)
            12, --PRVC (No trig)
            13, --PS/CPAP (trig)
            14, --VC (trig)
            15, --PRVC (trig)
            16, --PC in NIV
            17, --PS/CPAP in NIV
            18 --NAVA
            )
        )
       OR (itemid = 12376 --Mode (Bipap Vision)
        AND valueid IN (
                1, --CPAP
                2 --BIPAP
            )
        )
),

rrt_usage AS (
    SELECT
        'rrt_usage' AS parameter,
        COUNT(DISTINCT admissionid) AS value
    FROM numericitems_total
    WHERE itemid IN (
                       10736, --Bloed-flow
                       12460, --Bloedflow
                       14850 --MFT_Bloedflow (ingesteld): Fresenius multiFiltrate blood flow
        )
    AND value > 0
),

med_records as(
    select
        'med_records_per_hour' as parameter,
        d.admissionid as admissionid,
        count(*) / AVG(l.lengthofstay_hours) as value
    from `amsterdamumcdb-data.ams102.drugitems` d left join length_of_stay l on d.admissionid = l.admissionid
    WHERE d.itemid IS NOT NULL
      AND d.dose IS NOT NULL
      AND d.admissionid is not null
      AND d.stop >= l.admittedat
      AND d.start <= l.dischargedat
    GROUP BY d.admissionid
),

COMBINED AS (
        SELECT parameter, value FROM unique_admissions
        UNION ALL
        SELECT parameter, value FROM unique_patients
        UNION ALL
        SELECT parameter, value FROM alat
        UNION ALL
        SELECT parameter, value FROm cardiac_output
        UNION ALL
        SELECT parameter, value FROM creatinine
        UNION ALL
        SELECT parameter, value FROM crp
        UNION ALL
        SELECT parameter, value FROM etCO2
        UNION ALL
        SELECT parameter, value FROM fio2
        UNION ALL
        SELECT parameter, value FROM fluids_out
        UNION ALL
        SELECT parameter, value FROM heart_rate
        UNION ALL
        SELECT parameter, value FROM hemoglobin
        UNION ALL
        SELECT parameter, value FROM lactate
        UNION ALL
        SELECT parameter, value FROM leukocytes
        UNION ALL
        SELECT parameter, value FROM o2_sat_peripheral
        UNION ALL
        SELECT parameter, value FROM peep
        UNION ALL
        SELECT parameter, value FROM po2
        UNION ALL
        SELECT parameter, value FROM resp_rate
        UNION ALL
        SELECT parameter, value FROM sodium
        UNION ALL
        SELECT parameter, value FROM sys_bp
        UNION ALL
        SELECT parameter, value FROM gender
        UNION ALL
        SELECT parameter, value FROM icu_mortality_overall
        UNION ALL
        SELECT parameter, value FROM icu_mortality_elective
        UNION ALL
        SELECT parameter, value FROM icu_mortality_non_elective
        UNION ALL
        SELECT parameter, value FROM icu_mortality_28days
        UNION ALL
        SELECT parameter, value FROM vasopressor_usage
        UNION ALL
        SELECT parameter, value FROM mech_vent_usage
        UNION ALL
        SELECT parameter, value FROM rrt_usage
        UNION ALL
        SELECT 'age_18_39' AS parameter, age_18_39 AS value FROM age
        UNION ALL
        SELECT 'age_40_49' AS parameter, age_40_49 AS value FROM age
        UNION ALL
        SELECT 'age_50_59' AS parameter, age_50_59 AS value FROM age
        UNION ALL
        SELECT 'age_60_69' AS parameter, age_60_69 AS value FROM age
        UNION ALL
        SELECT 'age_70_79' AS parameter, age_70_79 AS value FROM age
        UNION ALL
        SELECT 'age_80+' AS parameter, age_80 AS value FROM age
        UNION ALL
        SELECT parameter, value FROM reason_for_admission_non_elective
        UNION ALL
        SELECT parameter, value FROM reason_for_admission_elective
        UNION ALL
        SELECT parameter, value FROM reason_for_admission_operative
        UNION ALL
        SELECT parameter, value FROM reason_for_admission_non_operative
        UNION ALL
        SELECT 'length_of_stay_days' AS parameter, lengthofstay_days AS value FROM length_of_stay
        UNION ALL
        SELECT 'length_of_stay_hours' AS parameter, lengthofstay_hours AS value FROM length_of_stay
        UNION ALL
        SELECT parameter, value FROM med_records
    )


--resulting end view: parameter name, median of frequency, standard deviation of frequency;

SELECT parameter,
       AVG(value) AS value_mean,
       APPROX_QUANTILES(value, 100)[OFFSET(25)] AS lower_IQR,
       APPROX_QUANTILES(value, 100)[OFFSET(50)] AS value_median,
       APPROX_QUANTILES(value, 100)[OFFSET(75)] AS upper_IQR,
       MIN(value) AS lowest_value,
       STDDEV_POP(value) AS value_standardeviation
FROM COMBINED
GROUP BY parameter;