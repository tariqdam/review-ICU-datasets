select count(admissionid)  from `amsterdamumcdb-data.ams102.numericitems`
where itemid = 8903 or itemid= 11543 or itemid = 11425 or itemid = 12311 or itemid =6709 
and value is not null and admissionid is not null