from pathlib import Path

from typing import List, Dict

import pandas as pd
from pandas import DataFrame

# Benchmark Table
LIBRARY_NAME: str = "Compression Scheme"
WITH_LTO: str = "with_lto"
CLIENTS: str = "clients"
MULTITHREADED: str = "multithreaded"
RUN_NAME: str = "benchmark_run_name"
QUERY_NAME: str = "Query Name"
RUNTIME_TO_BASELINE: str = "runtime_to_baseline"
AVG_DURATION: str = "Avg. Runtime (in ms)"
TOTAL_RUNTIME: str = "Total Runtime (in seconds)"
REDUCTION: str = "reduction"
BETTER_THAN_DEFAULT: str = "better_than_default"

# Sizes
SIZE_TO_BASELINE: str = "size_to_baseline"
TABLE_NAME: str = "table_name"
COLUMN_NAME: str = "column_name"
DATA_TYPE: str = "Data Type"
SIZE_IN_BYTES: str = "Size (in Bytes)"
SIZE_IN_GB: str = "Size (in GB)"
INT: str = "int"


def fancy_name(benchmark_name: str) -> str:
    fancy_name: str = benchmark_name.split(".")[-2]\
        .replace("_shuffled", "")\
        .replace("_LTO", "")\
        .replace("tpch_", "")\
        .split("/")[-1]
    removed_numbers = fancy_name[:fancy_name.rindex("_")]
    return removed_numbers

def filter_unneccessary_benchmarks(data: DataFrame) -> DataFrame:
    filtered: DataFrame = data[~data[RUN_NAME].str.match(".*(LZ4|RunLength|fastpfor).*")]
    return filtered

def get_clients(run_name: str) -> int:
    if "shuffled" in run_name:
        clients_number: str = run_name.split(".")[-2].replace("_shuffled", "").split("_")[-1]
        return int(clients_number)
    return 1

def complete_info(data: DataFrame) -> DataFrame:
    new_data: DataFrame = data.copy()
    new_data[LIBRARY_NAME] = [fancy_name(b) for b in new_data[RUN_NAME]]
    new_data[WITH_LTO] = ["LTO" in benchmark_run_name for benchmark_run_name in new_data[RUN_NAME]]
    new_data[CLIENTS] = [get_clients(run_name)
                           for run_name in new_data[RUN_NAME]]
    new_data[MULTITHREADED] = ["shuffled" in benchmark_run_name for benchmark_run_name in new_data[RUN_NAME]]
    return new_data

def complete_with_sizes(data: DataFrame, sizes_folder: Path) -> DataFrame:
    all_sizes: DataFrame = DataFrame()
    for library in data[LIBRARY_NAME].drop_duplicates():
        sizes: DataFrame = load_sizes(sizes_folder / f"sizes_{library}.txt")
        grouped_by_datatype = sizes.groupby(DATA_TYPE)[SIZE_IN_BYTES].sum()
        grouped_by_datatype = grouped_by_datatype.T
        grouped_by_datatype[LIBRARY_NAME] = library
        all_sizes = all_sizes.append(grouped_by_datatype)
    completed_with_size = data.merge(all_sizes, on=LIBRARY_NAME, how="left")
    return completed_with_size

def get_relative_to_baseline_high_level(data: DataFrame, baseline="Dictionary") -> DataFrame:
    dictionary_results: DataFrame = data[data[LIBRARY_NAME] == baseline]
    with_baseline: DataFrame = data.copy()
    with_baseline[RUNTIME_TO_BASELINE] = [runtime / dictionary_results[TOTAL_RUNTIME][0]
                                             for runtime in with_baseline[TOTAL_RUNTIME]]
    with_baseline[SIZE_TO_BASELINE] = [int_size / dictionary_results[INT][0]
                                             for int_size in with_baseline[INT]]
    return with_baseline

def get_relative_to_baseline_low_level(data: DataFrame, baseline="Dictionary") -> DataFrame:
    baseline_results: DataFrame = data[data[LIBRARY_NAME] == baseline]
    columns_to_merge: List[str] = [QUERY_NAME, LIBRARY_NAME, AVG_DURATION]
    with_baseline: DataFrame = data.merge(baseline_results[columns_to_merge], on=[QUERY_NAME],
                                          suffixes=("", "_baseline"))
    with_baseline[RUNTIME_TO_BASELINE] = [runtime / baseline
                                          for runtime,baseline
                                          in zip (with_baseline[AVG_DURATION], with_baseline[f"{AVG_DURATION}_baseline"])]
    return with_baseline

def rename(data: DataFrame) -> DataFrame:
    renamed: DataFrame = data.rename(columns={"benchmark_run_name": RUN_NAME, "total_runtime": TOTAL_RUNTIME,
                                              "query_name": QUERY_NAME, "avg_duration": AVG_DURATION})
    return renamed

def get_high_level(data_folder: Path, sizes_folder: Path) -> DataFrame:
    high_level: DataFrame = pd.read_csv(f"{data_folder}/benchmarks_parsed_high_level.csv")
    high_level = rename(high_level)
    high_level = high_level.sort_values(RUN_NAME)
    high_level = filter_unneccessary_benchmarks(high_level)
    high_level = complete_info(high_level)
    high_level = complete_with_sizes(high_level, sizes_folder)
    high_level[TOTAL_RUNTIME] = [runtime / 1e9 for runtime in high_level[TOTAL_RUNTIME]]
    high_level = get_relative_to_baseline_high_level(high_level)
    return high_level

def get_low_level(data_folder: Path) -> DataFrame:
    low_level: DataFrame = pd.read_csv(f"{data_folder}/benchmarks_parsed_low_level.csv")
    low_level = rename(low_level)
    low_level = low_level.sort_values(QUERY_NAME)
    low_level = filter_unneccessary_benchmarks(low_level)
    low_level = complete_info(low_level)
    low_level[AVG_DURATION] = [duration / 1e6 for duration in low_level[AVG_DURATION]]
    low_level = get_relative_to_baseline_low_level(low_level)
    return low_level

def load_sizes(sizes_file: Path) -> DataFrame:
    all_entries: List[List[str]] = []
    av_dict_entries: List[List[int]] = []
    column_names: List[str] = []
    types: List[str] = []
    with sizes_file.open() as file:
        table_starts: bool = False
        for line in file:
            if len(column_names) != 0 and table_starts and not '|' in line:
                break
            if not '|' in line:
                continue
            if len(column_names) == 0:
                column_names = [entry.replace(" ", "")
                                for entry in line.split("|") if entry != "" and entry != "\n"]
                continue
            if len(types) == 0:
                types =  [entry.replace(" ", "")
                          for entry in line.split("|") if entry != "" and entry != "\n"]
                continue
            if "<ValueS>" in line:
                table_starts = True
                continue
            if not table_starts:
                continue
            new_entry: List[str] = [entry.replace(" ", "")
                                    for entry in line.split("|") if entry != "" and entry != "\n"]
            all_entries.append(new_entry)
    as_type: Dict[str, str] = {column_names[i]:types[i] for i in range(0, len(column_names))}
    df = DataFrame(data=all_entries, columns=column_names).astype(as_type)
    renamed: DataFrame = df.rename(columns={"size_in_bytes": SIZE_IN_BYTES,
                                            "column_data_type": DATA_TYPE})
    renamed[SIZE_IN_GB] = [in_bytes / 1e9 for in_bytes in renamed[SIZE_IN_BYTES]]
    return renamed