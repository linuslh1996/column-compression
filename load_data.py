import sys
from enum import Enum
from pathlib import Path
import pandas as pd
from pandas import DataFrame

class Workload(str, Enum):
    SCAN = "table_scans",
    PROJECTION = "projections",
    AGGREGATE = "aggregates",
    JOINS = "joins"

class Colum(str, Enum):
    RUNTIME_NS = "RUNTIME_NS"

def read_csv(benchmark_folder: Path, workload: Workload) -> DataFrame:
    return pd.read_csv(benchmark_folder / f"{workload}.csv", delimiter="|")

# Load Data
data_path: str = sys.argv[1]
workloads_folder: Path = Path(data_path)
tpch_benchmark: Path = workloads_folder / "TPC-H"
table: DataFrame = read_csv(tpch_benchmark, Workload.SCAN)

# Calculate Information
sum_in_nanoseconds: int = table[Colum.RUNTIME_NS].sum()
in_seconds = sum_in_nanoseconds / 1_000_000_000
print(round(in_seconds,2))

# Runtime for the other Scans is probably pretty straightforward by simply replacing the folder name. The other measurements can
# probably aggregated using some dataframe groupby function calls.




