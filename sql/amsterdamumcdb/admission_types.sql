WITH diagnosis_groups AS (
SELECT admissionid,
item, 
CASE WHEN itemid IN (
18669, --NICE APACHEII diagnosen
18671 --NICE APACHEIV diagnosen
) THEN split_part(value, ' - ', 1) -- 'e.g. 'Non-operative cardiovascular - Anaphylaxis' -> Non-operative cardiovascular
ELSE value END as diagnosis_group,
valueid as diagnosis_group_id,
ROW_NUMBER() OVER(PARTITION BY admissionid
ORDER BY 
CASE --prefer NICE > APACHE IV > II > D
WHEN itemid = 18671 THEN 6 --NICE APACHEIV diagnosen
WHEN itemid = 18669 THEN 5 --NICE APACHEII diagnosen 
WHEN itemid BETWEEN 16998 AND 17017 THEN 4 --APACHE IV diagnosis 
WHEN itemid BETWEEN 18589 AND 18602 THEN 3 --APACHE II diagnosis
WHEN itemid BETWEEN 13116 AND 13145 THEN 2 --D diagnosis ICU
WHEN itemid BETWEEN 16642 AND 16673 THEN 1 --DMC diagnosis Medium Care
END DESC,
measuredat DESC) AS rownum
FROM listitems
WHERE itemid IN (
--MAIN GROUP - LEVEL 0
13110, --D_Hoofdgroep
16651, --DMC_Hoofdgroep, Medium Care

18588, --Apache II Hoofdgroep
16997, --APACHE IV Groepen

18669, --NICE APACHEII diagnosen
18671 --NICE APACHEIV diagnosen
)
),diagnosis_subgroups AS (
SELECT admissionid,
item, 
value as diagnosis_subgroup,
valueid as diagnosis_subgroup_id,
ROW_NUMBER() OVER(PARTITION BY admissionid
ORDER BY measuredat DESC) AS rownum
FROM listitems
WHERE itemid IN (
--SUB GROUP - LEVEL 1
13111, --D_Subgroep_Thoraxchirurgie
16669, --DMC_Subgroep_Thoraxchirurgie
13112, --D_Subgroep_Algemene chirurgie
16665, --DMC_Subgroep_Algemene chirurgie
13113, --D_Subgroep_Neurochirurgie
16667, --DMC_Subgroep_Neurochirurgie
13114, --D_Subgroep_Neurologie
16668, --DMC_Subgroep_Neurologie
13115, --D_Subgroep_Interne geneeskunde
16666 --DMC_Subgroep_Interne geneeskunde
)
), diagnoses AS (
SELECT admissionid,
item, 
CASE
WHEN itemid IN (
18669, --NICE APACHEII diagnosen
18671 --NICE APACHEIV diagnosen
)
THEN split_part(value, ' - ', 2) 
-- 'e.g. 'Non-operative cardiovascular - Anaphylaxis' -> Anaphylaxis
ELSE value
END as diagnosis,
CASE
WHEN itemid IN (
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

18596, --Apache II Operatief Gastr-intenstinaal
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

) THEN 1
WHEN itemid = 18669 AND valueid BETWEEN 1 AND 26 THEN 1 --NICE APACHEII diagnosen
WHEN itemid = 18671 AND valueid BETWEEN 222 AND 452 THEN 1 --NICE APACHEIV diagnosen
ELSE 0
END AS surgical,
valueid as diagnosis_id,
CASE 
WHEN itemid = 18671 THEN 'NICE APACHE IV'
WHEN itemid = 18669 THEN 'NICE APACHE II'
WHEN itemid BETWEEN 16998 AND 17017 THEN 'APACHE IV'
WHEN itemid BETWEEN 18589 AND 18602 THEN 'APACHE II'
WHEN itemid BETWEEN 13116 AND 13145 THEN 'Legacy ICU'
WHEN itemid BETWEEN 16642 AND 16673 THEN 'Legacy MCU'
END AS diagnosis_type,
ROW_NUMBER() OVER(PARTITION BY admissionid
ORDER BY 
CASE --prefer NICE > APACHE IV > II > D
WHEN itemid = 18671 THEN 6 --NICE APACHEIV diagnosen
WHEN itemid = 18669 THEN 5 --NICE APACHEII diagnosen 
WHEN itemid BETWEEN 16998 AND 17017 THEN 4 --APACHE IV diagnosis 
WHEN itemid BETWEEN 18589 AND 18602 THEN 3 --APACHE II diagnosis
WHEN itemid BETWEEN 13116 AND 13145 THEN 2 --D diagnosis ICU
WHEN itemid BETWEEN 16642 AND 16673 THEN 1 --DMC diagnosis Medium Care
END DESC,
measuredat DESC) AS rownum
FROM listitems
WHERE itemid IN (
-- Diagnosis - LEVEL 2
--SURGICAL
13116, --D_Thoraxchirurgie_CABG en Klepchirurgie
16671, --DMC_Thoraxchirurgie_CABG en Klepchirurgie
13117, --D_Thoraxchirurgie_Cardio anders
16672, --DMC_Thoraxchirurgie_Cardio anders
13118, --D_Thoraxchirurgie_Aorta chirurgie
16670, --DMC_Thoraxchirurgie_Aorta chirurgie
13119, --D_Thoraxchirurgie_Pulmonale chirurgie
16673, --DMC_Thoraxchirurgie_Pulmonale chirurgie

13141, --D_Algemene chirurgie_Algemeen 
16642, --DMC_Algemene chirurgie_Algemeen
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

18596, --Apache II Operatief Gastr-intenstinaal
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
17017, --APACHEIV Post-operative trauma

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
17001, --APACHEIV Non-operative haematological
17002, --APACHEIV Non-operative metabolic
17003, --APACHEIV Non-operative musculo-skeletal
17004, --APACHEIV Non-operative neurologic
17005, --APACHEIV Non-operative respiratory
17006, --APACHEIV Non-operative transplant
17007, --APACHEIV Non-operative trauma

--NICE: surgical/medical combined in same parameter
18669, --NICE APACHEII diagnosen
18671 --NICE APACHEIV diagnosen
)
),combined_diagnoses AS (
SELECT
admissions.* 
, diagnosis_type
, diagnosis, diagnosis_id
, diagnosis_subgroup
, diagnosis_subgroup_id
, diagnosis_group
, diagnosis_group_id
, surgical
FROM admissions
LEFT JOIN diagnoses on admissions.admissionid = diagnoses.admissionid
LEFT JOIN diagnosis_subgroups on admissions.admissionid = diagnosis_subgroups.admissionid
LEFT JOIN diagnosis_groups on admissions.admissionid = diagnosis_groups.admissionid
WHERE --only last updated record
(diagnoses.rownum = 1 OR diagnoses.rownum IS NULL) AND 
(diagnosis_subgroups.rownum = 1 OR diagnosis_subgroups.rownum IS NULL) AND
(diagnosis_groups.rownum = 1 OR diagnosis_groups.rownum IS NULL)
)
SELECT 
(
SELECT COUNT(admissionid)
FROM combined_diagnoses
WHERE surgical = 1
) AS surgical
,(
SELECT COUNT(admissionid)
FROM combined_diagnoses
WHERE surgical = 0
) AS medical
,(
SELECT COUNT(admissionid)
FROM combined_diagnoses
WHERE surgical IS NULL
) AS unknown
