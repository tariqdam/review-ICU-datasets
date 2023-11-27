SELECT
    cases.CaseID AS CaseID,
    d_references.ReferenceValue AS origin
FROM `amsterdamumcdb-data.sicdb105.cases` AS cases
         LEFT JOIN `amsterdamumcdb-data.sicdb105.d_references` AS d_references
                   ON cases.ReferringUnit = d_references.ReferenceGlobalID