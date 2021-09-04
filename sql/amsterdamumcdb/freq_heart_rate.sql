select count(admissionid)  from `amsterdamumcdb.numericitems`
where itemid = 6640 or itemid= 13075 
and value is not null and admissionid is not null