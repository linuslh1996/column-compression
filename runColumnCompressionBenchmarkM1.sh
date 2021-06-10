#!/bin/bash

run_benchmark() {
    # Checkout Git
    git checkout $1 && git pull && git submodule init && git submodule update
    # Run Benchmark without LTO

    mkdir -p cmake-build-release && cd cmake-build-release
    # rm -rf *

    if cmake .. -DCMAKE_C_COMPILER=/opt/homebrew/opt/llvm@11/bin/clang -DCMAKE_CXX_COMPILER=/opt/homebrew/opt/llvm@11/bin/clang++ -DCMAKE_BUILD_TYPE=Release -DHYRISE_RELAXED_BUILD=On -GNinja && ninja "$3" ; then
      if [ "$run_multithreaded" = true ] ; then
          cd ..
          ./cmake-build-release/"$3" -e ./encoding_$2.json --dont_cache_binary_tables -o ./$3_$2_"$max_clients"_shuffled.json -t $max_time --scheduler --clients $max_clients --mode=Shuffled
      else
          cd ..
          ./cmake-build-release/"$3" -e ./encoding_$2.json --dont_cache_binary_tables -o ./$3_$2_singlethreaded.json -s >> ./sizes_$2.txt
        fi
    else
         cd ..
    fi

}

# Configuration
clang_version="" #"-11"
run_multithreaded=true
max_clients=8
scale_factor=3
max_time=1200
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

run_benchmark benchmark/compactVetor bitpacking_compactvector "hyriseBenchmarkTPCH"
run_benchmark benchmark/compactVetor bitpacking_compactvector "hyriseBenchmarkTPCDS"
run_benchmark benchmark/compactVetor bitpacking_compactvector "hyriseBenchmarkJoinOrder"

run_benchmark benchmark/compactVetor dictionary "hyriseBenchmarkTPCH"
run_benchmark benchmark/compactVetor dictionary "hyriseBenchmarkTPCDS"
run_benchmark benchmark/compactVetor dictionary "hyriseBenchmarkJoinOrder"

run_benchmark benchmark/compactVectorFixed bitpacking_compactvector_f "hyriseBenchmarkTPCH"
run_benchmark benchmark/compactVectorFixed bitpacking_compactvector_f "hyriseBenchmarkTPCDS"
run_benchmark benchmark/compactVectorFixed bitpacking_compactvector_f "hyriseBenchmarkJoinOrder"

run_benchmark benchmarking/compressionUnencoded compressionUnencoded "hyriseBenchmarkTPCH"
run_benchmark benchmarking/compressionUnencoded compressionUnencoded "hyriseBenchmarkTPCDS"
run_benchmark benchmarking/compressionUnencoded compressionUnencoded "hyriseBenchmarkJoinOrder"


# Process Result
zip ../columncompression$(date +%Y%m%d) hyriseBenchmark* sizes*
cd ..
