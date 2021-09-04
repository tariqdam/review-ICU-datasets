select count(admissionid)
  from `amsterdamumcdb-data.ams102.numericitems`
	where itemid = 10053
	or itemid = 10304
	or itemid = 6837
	or itemid = 9580
	and value is not null
	and admissionid is not null