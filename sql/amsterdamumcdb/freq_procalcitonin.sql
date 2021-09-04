select count(admissionid)
  from `amsterdamumcdb-data.ams102.numericitems`
	where itemid = 15565
	or itemid=  15775
	and value is not null
	and admissionid is not null