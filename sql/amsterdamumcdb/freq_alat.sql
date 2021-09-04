select count(admissionid)
  from `amsterdamumcdb-data.ams102.numericitems`
	where itemid = 6800
	or itemid = 11978
	or itemid = 11979
	or itemid = 18847
	and value is not null and admissionid is not null