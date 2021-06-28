#!/bin/bash

run_benchmark() {
    # Checkout Git
    git checkout $1 && git pull && git submodule init && git submodule update
    # Run Benchmark without LTO

    mkdir -p cmake-build-release && cd cmake-build-release
    rm -rf *

    if cmake .. -DCMAKE_C_COMPILER=/opt/homebrew/opt/llvm@12/bin/clang -DCMAKE_CXX_COMPILER=/opt/homebrew/opt/llvm@12/bin/clang++ -DCMAKE_BUILD_TYPE=Release -DHYRISE_RELAXED_BUILD=On -GNinja && ninja "$3" ; then
      if [ "$run_multithreaded" = true ] ; then
        cd ..
        for i in "2,3" "4,6" "8,12"  # (cores,clients) tuples
        do
          IFS=',' read item1 item2 <<< "${i}"
          cores=$item1
          max_clients=$item2
          if ./cmake-build-release/"$3" -e ./encoding_$2.json --dont_cache_binary_tables -o ./$3_$2_"$max_clients"clients_${cores}cores_shuffled.json -t $max_time -s "$scale_factor" --cores $cores --scheduler --clients $max_clients --mode=Shuffled; then
            echo "Success"
          else
            # scale factor not supported
            ./cmake-build-release/"$3" -e ./encoding_$2.json --dont_cache_binary_tables -o ./$3_$2_"$max_clients"clients_${cores}cores_shuffled.json -t $max_time --cores $cores --scheduler --clients $max_clients --mode=Shuffled
          fi
        done
      else
          cd ..
          if ./cmake-build-release/"$3" -e ./encoding_$2.json --dont_cache_binary_tables -o ./$3_$2_singlethreaded.json -s ${scale_factor} >> ./sizes_$3_$2.txt; then
            echo "Success"
          else
            # scale factor not supported
            ./cmake-build-release/"$3" -e ./encoding_$2.json --dont_cache_binary_tables -o ./$3_$2_singlethreaded.json >> ./sizes_$3_$2.txt   
          fi
        fi
    else
         cd ..
    fi

}

# Configuration
clang_version="" #"-12"
run_multithreaded=true
scale_factor=10   # 10 is only ok for single-threaded if swapping during data generation is ok; use 3 for MT experiments
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
cd hyriseColumnCompressionBenchmark && git pull

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
zip -m ../$(hostname)_"$benchmark_name"_columncompression$(date +%Y%m%d) "$benchmark_name"* sizes*
cd ..
