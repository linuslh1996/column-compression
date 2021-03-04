import json
from typing import List
import numpy as np
from dataclasses import dataclass
import os
import sys
import math

def geometric_mean(values):
    product = 1
    for value in values:
        product *= value

    return product ** (1 / float(len(values)))

@dataclass
class BenchmarkResults:
    name: str
    total_duration: float
    avg_throughput: float

    queries: List[str]
    avg_durations: List[float]
    throughputs: List[float]


def parse_benchmark(filename):
    print(filename)

    with open(filename) as f:
        data = json.load(f)
        f.close()

    query_names = []
    mean_durations = []
    throughputs = []

    for d in data["benchmarks"]:
        successful_durations = np.array([run["duration"] for run in d["successful_runs"]], dtype=np.float64)
        
        avg_successful_duration = np.mean(successful_durations)
        avg_duration = avg_successful_duration if not math.isnan(avg_successful_duration) else 0.0
        mean_durations.append(avg_duration)

        query_names.append(d["name"])

        if float(d["items_per_second"]) > 0.0:
            throughput = float(d["items_per_second"])
            throughputs.append(throughput)
        
        if len(d["unsuccessful_runs"]) > 0:
            print("had unsuccessful runs!")

    
    mean_throughput = geometric_mean(throughputs)
    total_duration = np.sum(np.array(mean_durations, dtype=np.float64))
    return BenchmarkResults(filename, total_duration, mean_throughput, query_names, mean_durations, throughputs)

def benchmarks_to_low_level_csv(folder_name):
    directory = os.fsencode(folder_name)
    with open(os.path.join(folder_name, "benchmarks_parsed_high_level.csv"), "w") as f:
        f.write("benchmark_run_name,total_runtime,avg_throughput\n")
        for file in os.listdir(directory):
            filename = os.fsdecode(file)
            if filename.endswith(".json"): 
                benchmark = parse_benchmark(folder_name + "/" + filename)
                f.write(f"{benchmark.name},{benchmark.total_duration},{benchmark.avg_throughput}\n")
        f.close()


def benchmarks_to_high_level_csv(folder_name):
    directory = os.fsencode(folder_name)
    with open(os.path.join(folder_name, "benchmarks_parsed_low_level.csv"), "w") as f:
        f.write("benchmark_run_name,query_name,avg_duration,throughput\n")
        for file in os.listdir(directory):
            filename = os.fsdecode(file)
            if filename.endswith(".json"): 
                benchmark = parse_benchmark(folder_name + "/" + filename)
                for query, duration, throughput in zip(benchmark.queries, benchmark.avg_durations, benchmark.throughputs):
                    f.write(f"{benchmark.name},{query},{duration},{throughput}\n")
        f.close()

def benchmark_to_csv(folder_name):
    benchmarks_to_low_level_csv(folder_name)
    benchmarks_to_high_level_csv(folder_name)

if __name__ == "__main__":
    benchmark_to_csv(sys.argv[1])

