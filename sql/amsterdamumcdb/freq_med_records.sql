select count(admissionid)  from `amsterdamumcdb-data.ams102.drugitems`
    where admissionid is not null and itemid is not null and dose is not null