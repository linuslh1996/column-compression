#!/usr/bin/env python3

import argparse
import os
import socket
import subprocess

from datetime import date
from pathlib import Path
from sys import platform

DEBUG = True

hostname = socket.gethostname()
today = date.today()
max_runtime = 1800 if not DEBUG else 2

cores = -1
if platform.startswith("linux"):
    cores = int(subprocess.check_output(["lscpu -p | egrep -v '^#' | grep '^[0-9]*,[0-9]*,0,0' | wc -l"], shell=True))
elif platform.startswith("darwin"):
    cores = int(subprocess.check_output(["sysctl -n hw.ncpu"], shell=True))
else:
    exit("Unknown platform.")
assert cores != -1
print(f"Using up to {cores} cores.")
    

parser = argparse.ArgumentParser()
parser.add_argument('--evaluation', choices=("columncompression", "segmentencoding"),
                    default="segmentencoding", required=True)
parser.add_argument('--execution_mode', choices=("single-threaded", "multi-threaded", "both"),
                    default="single-threaded", required=True)
parser.add_argument('--compiler', choices=("GCC", "Clang"), default="Clang", required=True)
parser.add_argument('--compiler_path', type=str, default="", required=False)
parser.add_argument('--scale_factor', type=int, default=10, required=True)
parser.add_argument('--track_performance_counters', choices=("ON", "OFF"), default="OFF", required=True)
parser.add_argument('--intel_pcm_path', type=str, required=False)
parser.add_argument('--amd_uprof_path', type=str, required=False)
parser.add_argument('benchmarks', nargs='+', help="List of benchmarks to execute (TPCH, TPCDS, or JoinOrder).")
args = parser.parse_args()

if args.amd_uprof_path is not None:
    uprof_path = Path(arg.amd_uprof_path).expanduser().resolve()
    assert Path(uprof_path / "AMDuProfPcm").exists(), "Not able to find AMD uProf"
    assert args.intel_pcm_path is None, "Cannot run Intel and AMD instrumentalization at the same time."
    uprof_binary = uprof_path / "AMDuProfPcm"
    arch = "AMD"

# TODO: same for Intel

if args.compiler_path != "":
    assert args.compiler_path[-1] == "/"


def run_benchmark(branch_name, encoding_str, benchmark, execution_mode, preparation_cmd = None):
    execution_mode_short = "ST" if execution_mode == "single-threaded" else "MT"

    # Checkout Git
    git_checkout = os.system(f"git checkout {branch_name} && git pull && git submodule update --init --recursive")
    assert git_checkout == 0

    if preparation_cmd is not None:
        preparation = os.system(preparation_cmd)

    build_folder = "cmake-build-release"
    os.makedirs(build_folder, exist_ok=True)
    os.chdir(build_folder)
    if not DEBUG:
        os.system("rm -rf *")

    assert args.compiler in ["Clang", "GCC"]
    c_compiler = "gcc"
    cpp_compiler = "g++"
    if args.compiler == "Clang":
        c_compiler = "clang"
        cpp_compiler = "clang++"

    binary = f"hyriseBenchmark{benchmark}"

    scale_factor = 0.1 if DEBUG else args.scale_factor

    build_type = "Debug" if DEBUG else "Release"

    # Ensure we fully saturate the system for MT measurements
    clients = int(max(cores + 1, cores * 1.1))

    cmake = os.system(f"cmake .. -DCMAKE_C_COMPILER={args.compiler_path}{c_compiler} -DCMAKE_CXX_COMPILER={args.compiler_path}{cpp_compiler} -DCMAKE_BUILD_TYPE={build_type} -DHYRISE_RELAXED_BUILD=On -GNinja")
    assert cmake == 0
    ninja = os.system(f"ninja {binary}")
    assert ninja == 0

    os.chdir("..")

    benchmark_command = f"./{build_folder}/{binary} -e ./encoding_{encoding_str}.json --dont_cache_binary_tables -o ./{binary}_{encoding_str}_{clients}clients_{cores}cores_{execution_mode_short}.json"
    if binary != "hyriseBenchmarkJoinOrder":
        benchmark_command += f" -s {scale_factor} "
    if DEBUG:
        benchmark_command += " -r 5 "

    if execution_mode == "multi-threaded":
        benchmark_command += f" -t {max_runtime} --scheduler --clients {max_clients} --mode=Shuffled"
        if args.track_performance_counters:
            if args.amd_pcm_path is not None:
                adm_pcm = os.system(f"sudo ${uprof_binary} -m memory,tlb,l1,l2,l3 -c package=1 -q -A package -o {binary}_{encoding_str}_SF{scale_factor}_{clients}clients_{cores}cores_pcm.log  -- numactl -m 0 -N 0 " + benchmark_command + f' | ts -s "%s" > {binary}_{encoding_str}_SF{scale_factor}_{clients}clients_{cores}cores.log')
                assert adm_pcm == 0
            elif args.intel_pcm_path is not None:
                intel_pcm = os.system(f"sudo ${pcm_binary} 1 -csv={binary}_{encoding_str}_SF{scale_factor}_{clients}clients_{cores}cores_pcm.log --nosockets --nocores -- numactl -m 0 -N 0 " + benchmark_command + f' | ts -s "%s" > {binary}_{encoding_str}_SF{scale_factor}_{clients}clients_{cores}cores.log')
                assert intel_pcm == 0
            os.system(f"python3 ../extract_csv_from_pcm_log.py {arch} {binary}_{encoding_str}_SF{scale_factor}_{clients}clients_{cores}cores.log {binary}_{encoding_str}_SF{scale_factor}_{clients}clients_{cores}cores_pcm.log")
        else:
            mt_exec = os.system("numactl -m 0 -N 0 " + benchmark_command)
            assert mt_exec == 0
        
    else:
        st_exec = os.system("numactl -m 0 -N 0 " + benchmark_command + f"./sizes_{binary}_{encoding_str}_SF{scale_factor}.txt")


def main():
    # Clone Hyrise Repo
    if not Path("hyriseColumnCompressionBenchmark").exists():
        clone = os.system("git clone git@github.com:benrobby/hyrise.git hyriseColumnCompressionBenchmark")
        assert clone == 0

    os.chdir("hyriseColumnCompressionBenchmark")

    # Execute Benchmarks
    execution_modes = ['single-threaded', 'multi-threaded']
    if args.execution_mode != "both":
        execution_modes = [args.execution_mode]

    for execution_mode in execution_modes:
        execution_mode_short = "ST" if execution_mode == "single-threaded" else "MT"
        for benchmark in args.benchmarks:
            print(benchmark)

            run_benchmark("benchmark/compactVetor" ,"bitpacking_compactvector", benchmark, execution_mode)
            run_benchmark("benchmark/compactVectorFixed" ,"bitpacking_compactvector_f", benchmark, execution_mode)
            run_benchmark("benchmarking/compressionUnencoded" ,"compressionUnencoded", benchmark, execution_mode)
            run_benchmark("benchmarking/bitCompressionSIMDCAI" ,"bitpacking_simdcai", benchmark, execution_mode,
                          "cd third_party/SIMDCompressionAndIntersection && make all -j 16 && cd -")
            run_benchmark("benchmarking/bitCompression" ,"dictionary", benchmark, execution_mode,
                          "cd third_party/TurboPFor-Integer-Compression && make all -j 8 && cd -")
            run_benchmark("benchmarking/bitCompression" ,"bitpacking_turbopfor", benchmark, execution_mode)

            # Process Result
            os.system(f"zip -m ../{hostname}_{benchmark}_SF{args.scale_factor}_{args.evaluation}_{execution_mode_short}_{today.strftime('%Y%m%d')} {benchmark}* sizes* *pcm.csv")


if __name__ == "__main__":
    main()

