select count(admissionid)
  from `amsterdamumcdb-data.ams102.numericitems`
    where itemid = 6779
	or itemid = 9965
    and value is not null
	and admissionid is not null