select count(admissionid)  from `amsterdamumcdb-data.ams102.numericitems`
where itemid = 13151   or itemid=  6656 
and value is not null and admissionid is not null