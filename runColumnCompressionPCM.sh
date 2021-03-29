#!/bin/bash

run_benchmark() {

    # Checkout Git
    git checkout $1 && git pull && git submodule init && git submodule update
    # Run Benchmark without LTO
    if [ -n "$3" ]; then
       eval $3 && echo "setup"
    fi
    mkdir -p cmake-build-release && cd cmake-build-release
    
    if cmake .. -DCMAKE_C_COMPILER=clang-$clang_version -DCMAKE_CXX_COMPILER=clang++-$clang_version -DCMAKE_BUILD_TYPE=Release -DHYRISE_RELAXED_BUILD=On -GNinja && ninja "$benchmark_name" ; then

        ./"$benchmark_name" -e ../encoding_$2.json --dont_cache_binary_tables -t $max_time -s $scale_factor --scheduler --clients $max_clients --mode=Shuffled
    fi
    cd ..
}

# Configuration
clang_version=11
max_clients=16
scale_factor=3
max_time=500
benchmark_name="hyriseBenchmarkTPCH"
to_measure=l2_rqsts.all_demand_data_rd,l2_rqsts.demand_data_rd_hit,l2_rqsts.demand_data_rd_miss,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses,LLC-prefetch-misses


if [ "$1" == "-tpch" ]; then
   benchmark_name="hyriseBenchmarkTPCH" 
fi
if [ "$1" == "-tpcds" ]; then
   benchmark_name="hyriseBenchmarkTPCDS" 
fi
if [ "$1" == "-job" ]; then
   benchmark_name="hyriseBenchmarkJoinOrder" 
fi


if [ ! -d column-compression ]; then
   sudo apt update && sudo apt install git ninja-build build-essential clang zip cmake
   git clone git@github.com:opcm/pcm.git
   git clone git@github.com:linuslh1996/column-compression.git && cd column-compression
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
run_benchmark benchmark/compactVetor bitpacking_compactvector "cd third_party/TurboPFor-Integer-Compression && make all -j 8 && cd -"
run_benchmark benchmark/compactVectorFixed bitpacking_compactvector_f

# Process Result
zip -m ../columncompression$(date +%Y%m%d) tpch* sizes*
cd ..
