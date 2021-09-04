select count(admissionid)  from `amsterdamumcdb-data.ams102.numericitems`
where itemid = 6699 or itemid= 20134  
and value is not null and admissionid is not null