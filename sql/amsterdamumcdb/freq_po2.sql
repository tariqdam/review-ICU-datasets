select count(admissionid)
  from `amsterdamumcdb-data.ams102.numericitems`
	where itemid = 21214
	or itemid = 7433
	or itemid = 9996
	and value is not null
	and admissionid is not null