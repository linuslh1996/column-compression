import sys
from enum import Enum
from pathlib import Path
from typing import List, Tuple

import pandas as pd
from pandas import DataFrame

class Operator(str, Enum):
    SCAN = "table_scans",
    PROJECTION = "projections",
    AGGREGATE = "aggregates",
    JOIN = "joins"

RUNTIME_S = "Runtime (in seconds)"
COLUMN_TYPE = "Data Access"
QUERY_HASH = "QUERY_HASH"
OPERATOR_HASH = "OPERATOR_HASH"
DATA_TYPE = "Data Type"
TABLE_NAME = "TABLE_NAME"
COLUMN_NAME = "COLUMN_NAME"
OPERATOR_TYPE = "Operator"
WORKLOAD = "WORKLOAD"

BENCHMARKS: List[str] = ["CH-benCHmark", "Join Order Benchmark", "TPC-C", "TPC-DS", "TPC-H"]

def get_with_column_data_type(table: DataFrame, metadata: DataFrame) -> DataFrame:
    table[TABLE_NAME] = table[TABLE_NAME].astype(object)
    table[COLUMN_NAME] = table[COLUMN_NAME].astype(object)
    table_with_data_types = table.merge(metadata, how="left", on=[TABLE_NAME, COLUMN_NAME])
    return table_with_data_types

def get_grouped_by_operator_hash(table: DataFrame) -> DataFrame:
    grouped_by_operator_hash: DataFrame = table.groupby([QUERY_HASH, OPERATOR_HASH], as_index=False)[RUNTIME_S] \
        .agg(["count", "mean"])
    grouped_by_operator_hash[RUNTIME_S] = [mean / count for mean, count in zip(grouped_by_operator_hash["mean"], grouped_by_operator_hash["count"])]
    grouped_by_operator_hash = grouped_by_operator_hash.reset_index()

    table = table.drop(RUNTIME_S, axis=1)
    table = table.merge(grouped_by_operator_hash, on=[QUERY_HASH, OPERATOR_HASH])
    return table

def get_workload_data(workload_directory: Path) -> DataFrame:
    # Initialize
    metadata = pd.read_csv(workload_directory / "column_meta_data.csv", delimiter="|")
    metadata = metadata.rename(columns={"DATA_TYPE": DATA_TYPE})
    workload_name: str = workload_directory.name
    aggregated_data: DataFrame = DataFrame()
    for operator in list(Operator):
        # print(f"Processing {operator}")

        # Get Dataframe
        table: DataFrame = pd.read_csv(workload_directory / f"{operator}.csv", delimiter="|")
        table["RUNTIME_NS"] = [runtime / 1e9 for runtime in table["RUNTIME_NS"]]
        table = table.rename(columns={"RUNTIME_NS" : RUNTIME_S, "DATA_TYPE": DATA_TYPE,
                                      "COLUMN_TYPE": COLUMN_TYPE, "OPERATOR_TYPE": OPERATOR_TYPE})
        table[WORKLOAD] = [workload_name for i in range(len(table))]

        # Preprocess in case that we have a join (since both columns that we join on have the same type, we
        # select the left column as the "true" column)
        if operator is Operator.JOIN:
            table = table.rename({f"LEFT_COLUMN_NAME": COLUMN_NAME, f"LEFT_COLUMN_TYPE":COLUMN_TYPE,
                                 f"LEFT_TABLE_NAME":TABLE_NAME}, axis="columns")

        # Groupby to avoid having missleading results
        if operator is not Operator.SCAN:
            table = get_grouped_by_operator_hash(table)
        table = get_with_column_data_type(table, metadata)

        # Calculate Information
        grouped_by_column_type: DataFrame = table.groupby([COLUMN_TYPE, DATA_TYPE, OPERATOR_TYPE, WORKLOAD], as_index=False)[RUNTIME_S].sum().reset_index()
        aggregated_data = aggregated_data.append(grouped_by_column_type)
    return aggregated_data
