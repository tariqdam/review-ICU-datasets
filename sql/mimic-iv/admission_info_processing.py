import pandas as pd

 # load output from mimic_admissions.sql file
admissions = pd.read_csv('admission_info.csv')

# count medical admissions
print("Medical admissions:")
print(len(admissions.loc[admissions['first_careunit'] == 'Medical Intensive Care Unit (MICU)']))

# count surgical admissions
print("Surgical admissions")
print(len(admissions.loc[admissions['first_careunit'] == 'Surgical Intensive Care Unit (SICU)']))

print("other/unknown admissions")
print(len(admissions.loc[~(
        (admissions['first_careunit'] == 'Medical Intensive Care Unit (MICU)') |
        (admissions['first_careunit'] == 'Surgical Intensive Care Unit (SICU)')
        )
        ]))
print("")

# get mortality overall: load mortality info dataset
adm_mortality = pd.read_csv('mortality_info.csv')

print("elective admissions")
print(len(
                adm_mortality.loc[(adm_mortality['admission_type'] == "ELECTIVE") |
                                  (adm_mortality['admission_type'] == "SURGICAL SAME DAY ADMISSION")
                                ]
        )
)

print("urgent admissions")
print(
        len(
                adm_mortality.loc[(adm_mortality['admission_type'] != "ELECTIVE") &
                                  (adm_mortality['admission_type'] != "SURGICAL SAME DAY ADMISSION")
                                  ]
        )
)

print("ICU_mortality count:")
print(adm_mortality['icu_mortality'].sum())

print("ICU_mortality count of elective admissions:")
print(
        len(
                adm_mortality.loc[
                                (
                                (adm_mortality['admission_type'] == "ELECTIVE") |
                                (adm_mortality['admission_type'] == "SURGICAL SAME DAY ADMISSION")
                                )
                                &
                                (adm_mortality['icu_mortality'] == 1)
                                ]
        )
)

print("ICU_mortality count of urgent admissions:")
print(
        len(
                adm_mortality.loc[
                                    (
                                    (adm_mortality['admission_type'] != "ELECTIVE") &
                                    (adm_mortality['admission_type'] != "SURGICAL SAME DAY ADMISSION")
                                    )
                                    &
                                    (adm_mortality['icu_mortality'] == 1)
                                ]
        )
)

