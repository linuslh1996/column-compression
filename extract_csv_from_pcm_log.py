#!/usr/bin/env python3
import io
import pandas as pd
import sys

from pathlib import Path


# expects three parameters:
#  - first is either "AMD" or "Intel"
#  - second is file path to log file (logs the time at which the actual bechmark started)
#  - third is the file path to the PCM log file
assert len(sys.argv) == 4

cpu_arch = sys.argv[1].lower()
assert cpu_arch in ["intel", "amd"]

log_filepath = sys.argv[2]
assert Path(log_filepath).exists()

pcm_filepath = sys.argv[3]
assert Path(pcm_filepath).exists()

benchmark_start_time = -1
with open(log_filepath, "r") as file:
    for line in file:
        if "Starting Benchmark..." in line:
           benchmark_start_time = int(line.split(" ")[0]) + 1
           break
assert benchmark_start_time >= 0

csv_lines = ""

if cpu_arch == "amd":
    with open(pcm_filepath, "r") as file:
        found_csv_start = False
        for line in file:
            if not found_csv_start and line.count(",") < 10:
                continue
            
            if not found_csv_start and line.startswith("Package") and line.count(",") > 10:
                found_csv_start = True
                continue  # next line is the header

            csv_lines += line + "\n"

df = pd.read_csv(io.StringIO(csv_lines), encoding='utf8', sep=",")
pcm_csv = df[benchmark_start_time:]
pcm_csv.to_csv(pcm_filepath.replace(".log", ".csv"), index=False)

