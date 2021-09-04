select count(admissionid)
  from amsterdamumcdb-data.ams102.numericitems
	where itemid = 6836
	or itemid = 9941 
	and value is not null
	and admissionid is not null