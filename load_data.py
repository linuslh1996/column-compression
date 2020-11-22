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

RUNTIME_NS = "RUNTIME_NS"
COLUMN_TYPE = "COLUMN_TYPE"
QUERY_HASH = "QUERY_HASH"
OPERATOR_HASH = "OPERATOR_HASH"
DATA_TYPE = "DATA_TYPE"
TABLE_NAME = "TABLE_NAME"
COLUMN_NAME = "COLUMN_NAME"

BENCHMARKS: List[str] = ["CH-benCHmark", "Join Order Benchmark", "TPC-C", "TPC-DS", "TPC-H"]

def get_runtime_ns_per_grouped_attributes(table: DataFrame, grouped_attributes: List[str]) -> List[Tuple[str, int]]:
    grouped_by_column_type: DataFrame = table.groupby(grouped_attributes, as_index=False)[RUNTIME_NS].mean()
    runtime_ns_per_column_type: List[Tuple[str, int]] = []
    for _, row in grouped_by_column_type.iterrows():
        runtime_ns_per_column_type.append((f"{','.join([row[attr] for attr in grouped_attributes])}", row[RUNTIME_NS]))
    return runtime_ns_per_column_type

def get_with_column_data_type(table: DataFrame, metadata: DataFrame) -> DataFrame:
    table[TABLE_NAME] = table[TABLE_NAME].astype(object)
    table[COLUMN_NAME] = table[COLUMN_NAME].astype(object)
    table_with_data_types = table.merge(metadata, how="left", on=[TABLE_NAME, COLUMN_NAME])
    return table_with_data_types

def get_grouped_by_operator_hash(table: DataFrame) -> DataFrame:
    grouped_by_operator_hash: DataFrame = table.groupby([QUERY_HASH, OPERATOR_HASH], as_index=False)[RUNTIME_NS] \
        .agg(["count", "mean"])
    grouped_by_operator_hash[RUNTIME_NS] = [mean / count for mean, count in zip(grouped_by_operator_hash["mean"], grouped_by_operator_hash["count"])]
    grouped_by_operator_hash = grouped_by_operator_hash.reset_index()

    table = table.drop(RUNTIME_NS, axis=1)
    table = table.merge(grouped_by_operator_hash, on=[QUERY_HASH, OPERATOR_HASH])
    return table

def run():
    # Initialize
    data_path: str = sys.argv[1] if len(sys.argv) > 1 else "workloads"
    workloads_folder: Path = Path(data_path)

    runtimes_per_data_type = []
    runtimes_per_data_type_mix = []

    for benchmark in BENCHMARKS:
        print(f"Processing {benchmark}")
        benchmark_folder: Path = workloads_folder / benchmark
        metadata = pd.read_csv(benchmark_folder / "column_meta_data.csv", delimiter="|")
        for operator in list(Operator):
            print(f"Processing {operator}")

            # Get Dataframe
            table: DataFrame = pd.read_csv(benchmark_folder / f"{operator}.csv", delimiter="|")

            # Preprocess in case that we have a join (since both columns that we join on have the same type, we
            # select the left column as the "true" column)
            if operator is Operator.JOIN:
                table = table.rename({f"LEFT_{COLUMN_NAME}": COLUMN_NAME, f"LEFT_{COLUMN_TYPE}":COLUMN_TYPE,
                                     f"LEFT_{TABLE_NAME}":TABLE_NAME}, axis="columns")

            # Groupby to avoid having missleading results
            if operator is not Operator.SCAN:
                table = get_grouped_by_operator_hash(table)
            table = get_with_column_data_type(table, metadata)
            #table = table.groupby([TABLE_NAME, COLUMN_NAME, COLUMN_TYPE, DATA_TYPE], as_index=False)[RUNTIME_NS].mean()

            # Calculate Information
            runtime_per_data_type_mix = get_runtime_ns_per_grouped_attributes(table, [COLUMN_TYPE, DATA_TYPE])
            runtime_per_data_type = get_runtime_ns_per_grouped_attributes(table, [DATA_TYPE])

            for runtimes, name in zip([runtime_per_data_type, runtime_per_data_type_mix], ["type", "data_type_mix"]):
                for type, runtime in runtimes:
                    in_milliseconds: float = runtime / 1_000_000
                    print(f"{name} {type} takes {round(in_milliseconds, 2)} milliseconds on average")

                
                print("")
            
            runtimes_per_data_type_mix += [[t[0], t[1], operator, benchmark] for t in runtime_per_data_type_mix]
            runtimes_per_data_type += [[t[0], t[1], operator, benchmark] for t in runtime_per_data_type]

        print("")
    pd.DataFrame(runtimes_per_data_type_mix, columns=["type", "runtime", "operator", "benchmark"]).to_csv("data/runtimes_per_data_type_mix.csv", index=False)
    pd.DataFrame(runtimes_per_data_type, columns=["type", "runtime", "operator", "benchmark"]).to_csv("data/runtimes_per_data_type.csv", index=False)

if __name__ == "__main__":
    run()
