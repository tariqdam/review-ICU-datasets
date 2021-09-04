select count(admissionid)
  from `amsterdamumcdb-data.ams102.numericitems`
    where itemid = 6778
    or itemid = 9960
	or itemid = 10286
    and value is not null
	and admissionid is not null