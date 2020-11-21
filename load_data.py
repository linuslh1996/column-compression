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

RUNTIME_NS = "RUNTIME_NS"
COLUMN_TYPE = "COLUMN_TYPE"
QUERY_HASH = "QUERY_HASH"
OPERATOR_HASH = "OPERATOR_HASH"

BENCHMARKS: List[str] = ["CH-benCHmark", "Join Order Benchmark", "TPC-C", "TPC-DS", "TPC-H"]

def get_runtime_ns_per_column_type(table: DataFrame) -> List[Tuple[str, int]]:
    grouped_by_column_type: DataFrame = table.groupby(COLUMN_TYPE, as_index=False)[RUNTIME_NS].mean()
    runtime_ns_per_column_type: List[Tuple[str, int]] = []
    for index, row in grouped_by_column_type.iterrows():
        runtime_ns_per_column_type.append((row[COLUMN_TYPE], row[RUNTIME_NS]))
    return runtime_ns_per_column_type

def get_grouped_by_operator_hash(table: DataFrame) -> DataFrame:
    grouped_by_operator_hash: DataFrame = table.groupby([QUERY_HASH, OPERATOR_HASH, COLUMN_TYPE], as_index=False)[RUNTIME_NS] \
        .agg(["count", "mean"])
    grouped_by_operator_hash[RUNTIME_NS] = [mean / count for mean, count in zip(grouped_by_operator_hash["mean"], grouped_by_operator_hash["count"])]
    grouped_by_operator_hash = grouped_by_operator_hash.reset_index()
    return grouped_by_operator_hash

def run():
    # Initialize
    data_path: str = sys.argv[1] if len(sys.argv) > 1 else "workloads"
    workloads_folder: Path = Path(data_path)

    for benchmark in BENCHMARKS:
        print(f"Processing {benchmark}")
        for operator in list(Operator):
            print(f"Processing {operator}")

            # Get Dataframe
            benchmark_folder: Path = workloads_folder / benchmark
            table: DataFrame = pd.read_csv(benchmark_folder / f"{operator}.csv", delimiter="|")
            if operator is not Operator.SCAN:
                table = get_grouped_by_operator_hash(table)

            # Calculate Information
            runtime_per_column_type: List[Tuple[str, int]] = get_runtime_ns_per_column_type(table)
            for type, runtime in runtime_per_column_type:
                in_milliseconds: float = runtime / 1_000_000
                print(f"column type {type} takes {round(in_milliseconds, 2)} milliseconds on average")

            print("")
        print("")


if __name__ == "__main__":
    run()
