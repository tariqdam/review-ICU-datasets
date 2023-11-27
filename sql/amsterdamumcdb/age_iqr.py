import pandas as pd

# helper function
def make_sorter(l):
    """
    Create a dict from the list to map to 0..len(l)
    Returns a mapper to map a series to this custom sort order
    """
    sort_order = {k:v for k,v in zip(l, range(len(l)))}
    return lambda s: s.map(lambda x: sort_order[x])

output = pd.read_csv('output.csv')

age = output.loc[output['parameter'].str.contains("age_")]

# sort values
sorter = [
    "age_18_39",
    "age_40_49",
    "age_50_59",
    "age_60_69",
    "age_70_79",
    "age_80+"
]
age = age.sort_values('parameter', key=make_sorter(sorter))

age['cumsum_of_count'] = age['value_mean'].cumsum()