select count(admissionid)
  from `amsterdamumcdb-data.ams102.numericitems`
	where itemid = 6825
    or itemid=  10079
	or itemid=18854
	and value is not null
	and admissionid is not null