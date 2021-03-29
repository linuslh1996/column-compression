#!/bin/bash

run_benchmark() {
    # Checkout Git
    git checkout $1 && git pull && git submodule init && git submodule update
    # Run Benchmark without LTO
    if [ -n "$3" ]; then
       eval $3 && echo "setup"
    fi
    mkdir -p cmake-build-release && cd cmake-build-release
    rm -rf *
    
    if cmake .. -DCMAKE_C_COMPILER=clang-$clang_version -DCMAKE_CXX_COMPILER=clang++-$clang_version -DCMAKE_BUILD_TYPE=Release -DHYRISE_RELAXED_BUILD=On -GNinja && ninja "$benchmark_name" ; then
      if [ "$run_multithreaded" = true ] ; then
          cd ..
           ./cmake-build-release/"$benchmark_name" -e ./encoding_$2.json --dont_cache_binary_tables -o ./tpch_$2_14_shuffled.json -t $max_time --scheduler --clients $((max_clients / 2)) --mode=Shuffled
          ./cmake-build-release/"$benchmark_name" -e ./encoding_$2.json --dont_cache_binary_tables -o ./tpch_$2_28_shuffled.json -t $max_time --scheduler --clients $max_clients --mode=Shuffled
      else
          cd ..
          ./cmake-build-release/"$benchmark_name" -e ./encoding_$2.json --dont_cache_binary_tables -o ./tpch_$2_singlethreaded.json >> ./sizes_$2.txt
        fi
    else
         cd ..
    fi
    
}

# Configuration
clang_version=11
run_multithreaded=true
max_clients=4
scale_factor=1
max_time=180
benchmark_name="hyriseBenchmarkTPCH"


if [ "$1" == "-single" ]; then
    run_multithreaded=false
fi
if [ "$1" == "-multi" ]; then
    run_multithreaded=true
fi

if [ "$2" == "-tpcds" ]; then
   benchmark_name="hyriseBenchmarkTPCDS" 
fi
if [ "$2" == "-job" ]; then
   benchmark_name="hyriseBenchmarkJoinOrder" 
fi



# Clone Hyrise Repo
if [ ! -d hyriseColumnCompressionBenchmark ]; then
    git clone git@github.com:benrobby/hyrise.git hyriseColumnCompressionBenchmark
fi
cd hyriseColumnCompressionBenchmark

# Execute Benchmarks
run_benchmark benchmark/compactVetor bitpacking_compactvector
run_benchmark benchmark/compactVectorFixed bitpacking_compactvector_f

# Process Result
zip -m ../columncompression$(date +%Y%m%d) tpch* sizes*
cd ..
