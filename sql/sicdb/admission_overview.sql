# to run in gbq
WITH

Offset AS (
    SELECT
        CaseID,
        OffsetAfterFirstAdmission AS f1
    FROM `amsterdamumcdb-data.sicdb105.cases`
)

SELECT
    cases.`CaseID` AS CaseID,
    OffsetAfterFirstAdmission AS f1,
    Sex AS Sex,
    DischargeState AS f3,
    OffsetOfDeath AS f4,
    TimeOfStay AS TimeOfStay,
    cases.`AgeOnAdmission` AS AgeOnAdmission,
    (SELECT
         Max(data_float_h.Val) AS val
     FROM `amsterdamumcdb-data.sicdb105.data_float_h` AS data_float_h
     WHERE data_float_h.CaseID = cases.CaseID AND data_float_h.DataID = 773 AND Offset >= 0 AND Offset < 604800)
        AS f7,
    HoursOfCRRT AS HoursOfCRRT,
    (SELECT
         Count(data_float_h.id) AS val
     FROM `amsterdamumcdb-data.sicdb105.data_float_h` AS data_float_h
        LEFT JOIN Offset
            ON data_float_h.CaseID = Offset.CaseID
     WHERE data_float_h.CaseID = cases.CaseID AND data_float_h.DataID = 2019 AND data_float_h.Offset >= Offset.f1 + 360 -- todo find out why this gives an error. -> fixed by left joining table
     GROUP BY data_float_h.CaseID ) AS f9,
    (SELECT
         RefID AS val
     FROM `amsterdamumcdb-data.sicdb105.data_ref` AS data_ref
     WHERE data_ref.CaseID = cases.CaseID AND data_ref.CustomFieldID = 3097 AND data_ref.RefID <> - 1 ) -- todo find out why fieldid doesn't work
        AS f10,
    (SELECT RefID AS val
     FROM `amsterdamumcdb-data.sicdb105.data_ref` AS data_ref
     WHERE data_ref.CaseID = cases.CaseID AND data_ref.CustomFieldID = 3098 AND data_ref.RefID <> - 1 )
        AS f11,
    (SELECT RefID AS val
     FROM `amsterdamumcdb-data.sicdb105.data_ref` AS data_ref
     WHERE data_ref.CaseID = cases.CaseID AND data_ref.CustomFieldID = 3103 AND data_ref.RefID <> - 1 )
        AS f12,
    (SELECT RefID AS val
     FROM `amsterdamumcdb-data.sicdb105.data_ref` AS data_ref
     WHERE data_ref.CaseID = cases.CaseID AND data_ref.CustomFieldID = 3104 AND data_ref.RefID <> - 1 )
        AS f13,
    (SELECT d_references.ReferenceValue AS val
    FROM `amsterdamumcdb-data.sicdb105.cases` AS cases
        LEFT JOIN `amsterdamumcdb-data.sicdb105.d_references` AS d_references
            ON cases.ReferringUnit = d_references.ReferenceGlobalID)
        AS ReferringUnit
FROM `amsterdamumcdb-data.sicdb105.cases` AS cases


