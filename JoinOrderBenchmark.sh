#!/bin/bash

run_benchmark() {
    # Checkout Git
    git checkout $1 && git pull && git submodule init && git submodule update
    # Run Benchmark without LTO
    if [ -n "$3" ]; then
       eval $3
    fi
    mkdir -p cmake-build-release && cd cmake-build-release
    rm -rf *
    if cmake .. -DCMAKE_C_COMPILER=clang-$clang_version -DCMAKE_CXX_COMPILER=clang++-$clang_version -DCMAKE_BUILD_TYPE=Release -DHYRISE_RELAXED_BUILD=On -GNinja && ninja "$benchmark_name" ; then
      if [ "$run_multithreaded" = true ] ; then
        cd ..
        ./cmake-build-release/"$benchmark_name" -e encoding_$2.json --dont_cache_binary_tables -o "$benchmark_name"_$2_28_shuffled.json -t 1800 --scheduler --clients $max_clients --mode=Shuffled
      else
        cd ..
        ./cmake-build-release/"$benchmark_name" -e encoding_$2.json --dont_cache_binary_tables -o "$benchmark_name"_$2_singlethreaded.json >> sizes_$2.txt
        fi
    else
        cd .d.
    fi
}

# Configuration
clang_version=11
run_multithreaded=true
max_clients=28
benchmark_name="hyriseBenchmarkJoinOrder"

if [ "$1" == "-single" ]; then
    run_multithreaded=false
fi

if [ "$1" == "-multi" ]; then
    run_multithreaded=true
fi

# Clone Hyrise Repo
if [ ! -d hyriseColumnCompressionBenchmark ]; then
    git clone git@github.com:benrobby/hyrise.git hyriseColumnCompressionBenchmark
fi
cd hyriseColumnCompressionBenchmark && git pull

# Execute Benchmarks
run_benchmark benchmark/turboPFOR TurboPFOR
run_benchmark benchmark/turboPFOR_bitpacking TurboPFOR_bitpacking
run_benchmark benchmark/compactVectorSegment CompactVector
run_benchmark benchmark/implementSIMDCAI SIMDCAI "cd third_party/SIMDCompressionAndIntersection && make all -j 16 && cd -"
run_benchmark benchmark/turboPFOR Dictionary
run_benchmark benchmark/turboPFOR FrameOfReference
run_benchmark benchmark/turboPFOR Unencoded

# Process Results
zip -m ../$(hostname)_"$benchmark_name"_segmentencoding$(date +%Y%m%d) "$benchmark_name"* sizes*
cd ..