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
           ./"$benchmark_name" -e ../encoding_$2.json --dont_cache_binary_tables -o ../tpch_$2_14_shuffled.json -s $scale_factor -t $max_time --scheduler --clients $((max_clients / 2)) --mode=Shuffled
          ./"$benchmark_name" -e ../encoding_$2.json --dont_cache_binary_tables -o ../tpch_$2_28_shuffled.json -s $scale_factor -t $max_time --scheduler --clients $max_clients --mode=Shuffled
      else
          ./"$benchmark_name" -e ../encoding_$2.json --dont_cache_binary_tables -o ../tpch_$2_singlethreaded.json -s $scale_factor >> ../sizes_$2.txt
        fi
    fi
    cd ..
}

# Configuration
clang_version=11
run_multithreaded=true
max_clients=28
scale_factor=10
max_time=1800
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


# Clone Hyrise Repo
if [ ! -d hyriseColumnCompressionBenchmark ]; then
    git clone git@github.com:benrobby/hyrise.git hyriseColumnCompressionBenchmark
fi
cd hyriseColumnCompressionBenchmark

# Execute Benchmarks
run_benchmark benchmarking/bitCompressionSIMDCAISeq bitpacking_simdcai_seq "cd third_party/SIMDCompressionAndIntersection && make all -j     16 && cd -"
run_benchmark benchmarking/bitCompressionSIMDCAI bitpacking_simdcai "cd third_party/SIMDCompressionAndIntersection && make all -j     16 && cd -"
run_benchmark benchmarking/bitCompression dictionary "cd third_party/TurboPFor-Integer-Compression && make all -j 8 && cd -"
run_benchmark benchmarking/bitCompression bitpacking_turbopfor
run_benchmark benchmarking/bitCompressionSequential bitpacking_turbopfor_seq
run_benchmark benchmark/compactVetor bitpacking_compactvector
run_benchmark benchmark/compactVectorFixed bitpacking_compactvector_f
run_benchmark benchmark/compactVetor simdbp
run_benchmark benchmarking/compressionUnencoded compressionUnencoded

# Process Result
zip -m ../columncompression$(date +%Y%m%d) tpch* sizes*
cd ..
