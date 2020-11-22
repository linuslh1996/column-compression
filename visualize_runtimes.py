import pandas as pd
from pandas import DataFrame, Series


def get_relative_inequality(table: DataFrame):
    series: Series = Series()
    if len(table) == 1:
        series["reference_vs_data"] = 0
        return series
    referenced_time: int = table[table.COLUMN_TYPE == "REFERENCE"]["runtime"].iloc[0]
    data_time: int = table[table.COLUMN_TYPE == "DATA"]["runtime"].iloc[0]
    series["reference_vs_data"] = referenced_time / data_time
    return series

def run():
    filename: str = "runtimes_per_data_type.csv"
    data: DataFrame = pd.read_csv(filename)
    data["COLUMN_TYPE"] = [row.split(",")[0] for row in data["type"]]
    data["DATA_TYPE"] = [row.split(",")[1] for row in data["type"]]
    grouped_by_operation = data.groupby(["operator", "benchmark", "DATA_TYPE"], as_index=False).apply(get_relative_inequality)
    grouped_by_operation = grouped_by_operation[grouped_by_operation.reference_vs_data != 0]
    print(grouped_by_operation)
    grouped_by_operation.to_csv("difference_between_value_and_reference.csv")

if __name__ == "__main__":
    run()