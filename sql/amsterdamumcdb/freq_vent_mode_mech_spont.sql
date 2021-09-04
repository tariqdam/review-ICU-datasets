select count(admissionid)  from `amsterdamumcdb-data.ams102.listitems`
where itemid = 9534 or itemid=  6685  
and value is not null and admissionid is not null