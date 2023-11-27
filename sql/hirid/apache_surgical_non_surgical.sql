WITH

APACHE_II_NON AS (
    SELECT DISTINCT
        patientid,
        value,
        value
    FROM `amsterdamumcdb-data.hirid111.observation`
    WHERE
        variableid = 9990002 AND
        (value = 98 OR value = 99 OR value = 100 OR value = 101 OR value = 102 OR value = 103 OR value = 104 OR value = 105 OR value = 106)
),

APACHE_II_SURGICAL AS (
    SELECT DISTINCT
        patientid,
        value,
        value
    FROM `amsterdamumcdb-data.hirid111.observation`
    WHERE
        variableid = 9990002 AND
        (value = 107 OR value = 108 OR value = 109 OR value = 110 OR value = 111 OR value = 112 OR value = 113 OR value = 114)
),

APACHE_IV_NON AS (
    SELECT DISTINCT
        patientid,
        value,
        value
    FROM `amsterdamumcdb-data.hirid111.observation`
    WHERE
        variableid = 9990004 AND
        (value = 190 OR value = 191 OR value = 192 OR value = 193 OR value = 197 OR value = 194 OR value = 195 OR value = 196 OR value = 198 OR value = 206)
),

APACHE_IV_SURGICAL AS (
    SELECT DISTINCT
        patientid,
        value,
        value
    FROM `amsterdamumcdb-data.hirid111.observation`
    WHERE
        variableid = 9990004 AND
        (value = 199 OR value = 201 OR value = 200 OR value = 202 OR value = 203 OR value = 204 OR value = 205)),

APACHE_NON_SURGICAL AS (
    SELECT
        patientid,
        'non_surgical' as type
    FROM APACHE_II_NON
    UNION ALL
    SELECT
        patientid,
        'non_surgical' as type
    FROM APACHE_IV_NON
),

APACHE_SURGICAL AS (
    SELECT
        patientid,
        'surgical' as type
    FROM APACHE_II_SURGICAL
    UNION ALL
    SELECT
        patientid,
        'surgical' as type
    FROM APACHE_IV_SURGICAL
),

APACHE_COMBINED AS (
    SELECT DISTINCT
        n.patientid,
        n.type
    FROM APACHE_NON_SURGICAL n
    UNION ALL
    SELECT DISTINCT
        s.patientid,
        s.type
    FROM APACHE_SURGICAL s
)

SELECT distinct
    type,
    count(*) as count
FROM APACHE_COMBINED
GROUP BY type