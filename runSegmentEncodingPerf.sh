#!/bin/bash

run_benchmark() {

    # Checkout Git
    git checkout $1 && git pull && git submodule init && git submodule update
    # Run Benchmark without LTO
    if [ -n "$3" ]; then
       eval $3 && echo "setup"
    fi
    mkdir -p $out_dir 
    mkdir -p cmake-build-release && cd cmake-build-release
    rm -rf *
    
    if cmake .. -DCMAKE_C_COMPILER=clang-$clang_version -DCMAKE_CXX_COMPILER=clang++-$clang_version -DCMAKE_BUILD_TYPE=Release -DHYRISE_RELAXED_BUILD=On -GNinja && ninja "$benchmark_name" ; then
        perf stat -e "$to_measure" -o ../"$out_dir"/"$2"_baseline_sf"$scale_factor"_multi.txt ./"$benchmark_name" -e ../encoding_$2.json --dont_cache_binary_tables -r 1 -s $scale_factor --scheduler --clients $max_clients --mode=Shuffled >> ../"$out_dir"/sizes_$2_sf"$scale_factor"_multi.txt
        perf stat -e "$to_measure" -o ../"$out_dir"/"$2"_cache_sf"$scale_factor"_multi.txt ./"$benchmark_name" -e ../encoding_$2.json --dont_cache_binary_tables -o ../"$out_dir"/tpch_$2_sf"$scale_factor"_shuffled.json -t $max_time -s $scale_factor --scheduler --clients $max_clients --mode=Shuffled >> ../"$out_dir"/sizes_$2_sf"$scale_factor"_cache_multi.txt
    fi
    cd ..
}

# Configuration
clang_version=11
max_clients=28
scale_factor=10
max_time=1200
benchmark_name="hyriseBenchmarkTPCH"
to_measure=l2_rqsts.all_demand_data_rd,l2_rqsts.demand_data_rd_hit,l2_rqsts.demand_data_rd_miss,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses,LLC-prefetch-misses
out_dir="cache_results"


if [ "$1" == "-tpch" ]; then
   benchmark_name="hyriseBenchmarkTPCH" 
fi
if [ "$1" == "-tpcds" ]; then
   benchmark_name="hyriseBenchmarkTPCDS" 
fi
if [ "$1" == "-job" ]; then
   benchmark_name="hyriseBenchmarkJoinOrder" 
fi


# Clone Hyrise Repo
if [ ! -d hyriseColumnCompressionBenchmark ]; then
    git clone git@github.com:benrobby/hyrise.git hyriseColumnCompressionBenchmark
    cd hyriseColumnCompressionBenchmark
    ./install_dependencies.sh

else
	cd hyriseColumnCompressionBenchmark
fi

# Execute Benchmarks
run_benchmark benchmark/compactVectorSegment CompactVector
run_benchmark benchmark/implementSIMDCAI SIMDCAI "cd third_party/SIMDCompressionAndIntersection && make all -j 16 && cd -"
run_benchmark benchmark/turboPFOR TurboPFOR
run_benchmark benchmark/turboPFOR_bitpacking TurboPFOR_bitpacking
run_benchmark benchmark/turboPFOR Dictionary
run_benchmark benchmark/turboPFOR FrameOfReference
run_benchmark benchmark/turboPFOR Unencoded
run_benchmark benchmark/turboPFOR LZ4
run_benchmark benchmark/turboPFOR RunLength

# Process Result
zip -m ../segmentEncoding$(date +%Y%m%d) tpch* sizes* "$out_dir"/*"
cd ..
