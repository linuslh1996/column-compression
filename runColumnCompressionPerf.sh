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
        perf stat -e "$to_measure" -o ../$out_dir/"$2"_baseline_sf"$scale_factor"_multi.txt ./"$benchmark_name" -e ../encoding_$2.json --dont_cache_binary_tables -r 1 -s $scale_factor --scheduler --clients $max_clients --mode=Shuffled >> ../$out_dir/sizes_$2_multi.txt 
        perf stat -e "$to_measure" -o ../$out_dir/"$2"_baseline_sf"$scale_factor"_single.txt ./"$benchmark_name" -e ../encoding_$2.json --dont_cache_binary_tables -r 1 -s $scale_factor >> ../$out_dir/sizes_$2.txt

        perf stat -e "$to_measure" -o ../$out_dir/"$2"_cache_sf"$scale_factor"_single.txt ./"$benchmark_name" -e ../encoding_$2.json --dont_cache_binary_tables -o ../$out_dir/tpch_$2_28_shuffled.json -t $max_time -s $scale_factor --scheduler --clients $max_clients --mode=Shuffled >> ../$out_dir/sizes_$2_cache_single.txt
        perf stat -e "$to_measure" -o ../$out_dir/"$2"_cache_sf"$scale_factor"_multi.txt ./"$benchmark_name" -e ../encoding_$2.json --dont_cache_binary_tables -o ../$out_dir/tpch_$2_singlethreaded.json -r 300 >> ../$out_dir/sizes_$2_cache_multi.txt
    fi
    cd ..
}

# Configuration
clang_version=11
max_clients=16
scale_factor=3
max_time=900
benchmark_name="hyriseBenchmarkTPCH"
to_measure=l2_rqsts.all_demand_data_rd,l2_rqsts.demand_data_rd_hit,l2_rqsts.demand_data_rd_miss,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses,LLC-prefetch-misses
out_dir=$2


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
run_benchmark benchmarking/bitCompressionSIMDCAI bitpacking_simdcai "cd third_party/SIMDCompressionAndIntersection && make all -j 16 && cd -"
run_benchmark benchmarking/compressionUnencoded compressionUnencoded

# Process Result
zip -m ../columncompression$(date +%Y%m%d) tpch* sizes*
cd ..
