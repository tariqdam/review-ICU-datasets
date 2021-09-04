select count(admissionid)
from `amsterdamumcdb-data.ams102.processitems`
where itemid = 9328
and admissionid is not null