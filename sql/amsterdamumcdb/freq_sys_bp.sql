select count(admissionid)  from `amsterdamumcdb-data.ams102.numericitems`
where itemid = 6641 or itemid= 6678 or itemid=8841
and value is not null and admissionid is not null