select count(admissionid)
  from `amsterdamumcdb-data.ams102.numericitems`
	where itemid = 6840
	or itemid = 9555
	or itemid = 9924
	and value is not null
	and admissionid is not null