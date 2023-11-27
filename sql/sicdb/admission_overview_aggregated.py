import pandas as pd
import numpy as np

admission_overview = pd.read_csv('export (7).csv')
admission_overview_extra = pd.read_csv('export_gbq.csv')

# number of admissions
number_of_admissions = len(admission_overview['CaseID'].unique())

# age, median and IQR
age_quantiles = admission_overview['AgeOnAdmission'].quantile([0.25, 0.5, 0.75])

# calculate sex
male_fraction = len(admission_overview.loc[admission_overview['Sex'] == 'male']) / len(admission_overview['Sex'])

# mortality ICU
mortality_icu = len(admission_overview.loc[admission_overview['DeceasedICU'] == 1]) / len(admission_overview['DeceasedICU'])

mortality_28_days = len(admission_overview.loc[admission_overview['Deceased28Day'] == 1]) / len(admission_overview['Deceased28Day'])

# length of stay (SD) in days
los_days_mean = (admission_overview_extra['TimeOfStay'] / (60*60*24)).mean()
los_days_sd = (admission_overview_extra['TimeOfStay'] / (60*60*24)).std()

# >1 comorbidity
comorbidity_fraction = len(admission_overview.loc[(admission_overview['PreconditionArtHypertension'] == 1) | (admission_overview['PreconditionDiabetes'] == 1) | (admission_overview['PreconditionLungDisease'] == 1) | (admission_overview['PreconditionRenalDysfunction'] == 1)]) / len(admission_overview)

# admission unit
admission_unit = pd.read_csv('origin.csv')
admission_unit['medical_or_surgical'] = np.NaN
medical_or_surgical_dict = {
    'surgical':
        [
        'Allgemeinchirurgie',
        'Herzchirurgie',
        'Gefäßchirurgie',
        'Unfallchirurgie',
        'HNO',
        'Orthopädie',
        'Urologie',
        'Kieferchirurgie',
        'Augenheilkunde',
        'Neurochirurgie',
        'Kinderchirurgie'
        ],
    'medical':
        [
        '2. Medizin',
        'Pneumologie',
        '1. Medizin',
        '3. Medizin',
        'Dermatologie',
        'Neurologie',
        'Intensivstation 2. Medizin',
        'Psychiatrie',
        'Pädiatrie',
        'Angiologie',
        'Endokrinologie'
        ],
    'other/unknown':
        [
        'Gynäkologie',
        'Unknown',
        'Zentrale Notaufnahme',
        'Externes Krankenhaus',
        'Externe Intensivstation',
        'Zentralambulanz (ZANE) CDK'
        ]
}

for index, row in admission_unit.iterrows():
    unit_name = row['origin']

    # Check if the unit_name is in any category of the dictionary
    for category, departments in medical_or_surgical_dict.items():
        if unit_name in departments:
            admission_unit.at[index, 'medical_or_surgical'] = category
            break  # No need to check other categories

admission_unit = admission_unit['medical_or_surgical'].value_counts()

# vasopressor usage
vasopressor_usage = len(admission_overview.loc[admission_overview['VasopresserUsage'] == 1]) / len(admission_overview)

# RRT usage
rrt_usage = len(admission_overview.loc[admission_overview['HadCRRT'] == 1]) / len(admission_overview)

# Ventilated on ICU
ventilated_usage = len(admission_overview.loc[admission_overview['VentilatedOnICU'] == 1]) / len(admission_overview)