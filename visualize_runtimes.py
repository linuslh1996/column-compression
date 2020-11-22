from typing import List

import pandas as pd
from pandas import DataFrame, Series
import seaborn as sns
import matplotlib.pyplot as plt

RUNTIME = "runtime"
RELATIVE_RUNTIME = "relative_runtime"
TYPE = "type"
COLUMN_TYPE = "COLUMN_TYPE"
DATA_TYPE = "DATA_TYPE"
OPERATOR = "operator"
BENCHMARK = "benchmark"


def get_relative_inequality(table: DataFrame):
    series: Series = Series()
    if len(table) == 1:
        series[RELATIVE_RUNTIME] = 0
        return series
    referenced_time: int = table[table.COLUMN_TYPE == "REFERENCE"][RUNTIME].iloc[0]
    data_time: int = table[table.COLUMN_TYPE == "DATA"][RUNTIME].iloc[0]
    series[RELATIVE_RUNTIME] = referenced_time / data_time
    return series

def get_figure_for_data_reference_proportion() -> sns.catplot:
    filename: str = "data/runtimes_per_data_type_mix.csv"
    data: DataFrame = pd.read_csv(filename)
    data[COLUMN_TYPE] = [row.split(",")[0] for row in data[TYPE]]
    data[DATA_TYPE] = [row.split(",")[1] for row in data[TYPE]]
    grouped_by_operation = data.groupby([OPERATOR, BENCHMARK, DATA_TYPE], as_index=False).apply(get_relative_inequality)
    grouped_by_operation = grouped_by_operation.loc[grouped_by_operation[RELATIVE_RUNTIME] != 0]
    plot : sns.catplot = sns.catplot(x=OPERATOR, y=RELATIVE_RUNTIME, hue=DATA_TYPE, kind="box", data=grouped_by_operation)
    plot.set(ylim=(0,20))
    return plot

def get_with_runtime_relative_to_int(data: DataFrame) -> DataFrame:
    rows: List[Series] = []
    for _, row in data.iterrows():
        integer_runtime: float = data.loc[(data[BENCHMARK] == row[BENCHMARK]) &
                                          (data[OPERATOR] == row[OPERATOR]) &
                                          (data[TYPE] == "int")][RUNTIME].iloc[0]
        row[RELATIVE_RUNTIME] = row[RUNTIME] / integer_runtime
        rows.append(row)
    return DataFrame(rows)

def get_figure_for_difference_between_data_types() -> sns.catplot:
    filename: str = "data/runtimes_per_data_type.csv"
    data: DataFrame = pd.read_csv(filename)
    with_rows_relative_to_int = get_with_runtime_relative_to_int(data)

    grouped_by_workload = with_rows_relative_to_int.groupby([OPERATOR, TYPE], as_index=False)[RELATIVE_RUNTIME].median()
    plot: sns.catplot = sns.catplot(x=OPERATOR, y=RELATIVE_RUNTIME, hue=TYPE, kind="bar", data=grouped_by_workload)
    return plot

def run():
    difference_between_data_types_plot : sns.catplot = get_figure_for_difference_between_data_types()
    difference_between_reference_and_data: sns.catplot = get_figure_for_data_reference_proportion()

    difference_between_data_types_plot.savefig("figures/data_difference")
    difference_between_reference_and_data.savefig("figures/reference_effect")



if __name__ == "__main__":
    run()