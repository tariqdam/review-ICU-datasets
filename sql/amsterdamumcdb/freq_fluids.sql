WITH fluids_out_categorised AS (

    SELECT measuredat as time,
        itemid,
		admissionid,
        item,
        value,
        CASE 
            WHEN itemid IN (
                8699, --Thoraxdrain1 Productie
                8700, --Thoraxdrain2 Productie
                8701, --Thoraxdrain3 Productie
                8717, --Wonddrain1 Productie
                8719, --Wonddrain2 Productie
                8720, --Wonddrain3 Productie
                8721, --Wonddrain4 Productie
                8770, --Ventrikeldrain1 Uit
                8772, --Pericarddrain Uit
                12503, --Thoraxdrain4 Productie
                12504, --Thoraxdrain5 Productie
                12506, --Thoraxdrain6 Productie
                10592, --Ascitespunctie
                10595, --Pleurapunctie
                9626, --Wondlekkage
                14428, --Wonddrain5 Productie
                14429, --Wonddrain6 Productie
                12553 --Fistel
            ) THEN '04. Surgical drains'
            WHEN itemid IN (
                8774, --Maaghevel
                8777, --MaagRetentieWeg
                8780, --Braken
                8782, --Sengtaken
                8925, --Maagzuig
                12580 --Galdrain Uit
            ) THEN '03. Gastric/Bile'
            WHEN itemid IN (
                8784, --Jejunostoma
                8786, --Ileostoma
                8788, --Colostoma
                8789 --Ontlasting
            ) THEN '02. Faeces'
            WHEN itemid IN (
                8792 --Bloedverlies
            ) THEN '05. Blood loss'
            WHEN itemid IN (
                8794, --UrineCAD
                8796, --UrineSupraPubis
                8798, --UrineSpontaan
                8800, --UrineIncontinentie
                8803, --UrineUP
                10743, --Nefrodrain li Uit
                10745, --Nefrodrain re Uit
                19921, --UrineSplint Li
                19922 --UrineSplint Re
            ) THEN '00. Urine'
            WHEN itemid IN (
                8805, --CVVH Onttrokken
                8806, --Hemodialyse onttrekken
                8808 --Peritoneaaldialyse
            ) THEN '01. Ultrafiltrate'
            WHEN itemid IN (
                9564, --NDT-syst.
                9360, --Lumbaaldrain Uit
                15257, --Cisternale drain Uit
                13031, --Spinaaldrain Uit
                13495, --Ventrikeldrain2 Uit
                10597 --Liquorpunctie
            ) THEN '06. Cerebrospinal fluid'
            WHEN itemid IN (
                12792 --Kolven
            ) THEN '07. Lactation'
        END AS category
    FROM `amsterdamumcdb-data.ams102.numericitems`
    WHERE 
        fluidout > 0  )
SELECT *,
    CASE category
        WHEN '00. Urine' THEN 'xkcd:dandelion'
        WHEN '01. Ultrafiltrate' THEN
'xkcd:light yellow'
        WHEN '02. Faeces' THEN 'xkcd:poop'
        WHEN '03. Gastric/Bile' THEN
'xkcd:bile'
        WHEN '04. Surgical drains' THEN
'xkcd:carnation'
        WHEN '05. Blood loss' THEN 'xkcd:red'
        WHEN '06. Cerebrospinal fluid' THEN
'xkcd:very light pink'
        WHEN '07. Lactation' THEN 'xkcd:off
white'
        ELSE 'black'
    END AS colour
FROM
fluids_out_categorised
ORDER BY
admissionid, category, itemid, time