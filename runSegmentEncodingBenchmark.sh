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

    if cmake .. -DCMAKE_C_COMPILER=$compiler -DCMAKE_CXX_COMPILER=$cppcompiler -DCMAKE_BUILD_TYPE=Release -DHYRISE_RELAXED_BUILD=On -GNinja && ninja "$benchmark_name" ; then
      if [ "$run_multithreaded" = true ] ; then
        LD_LIBRARY_PATH=/usr/local/lib64/ ./"$benchmark_name" -e ../encoding_$2.json --dont_cache_binary_tables -o ../"$benchmark_name"_$2_$((max_clients / 2))_sf"$scale_factor"_shuffled.json -s "$scale_factor" -t 1800 --scheduler --clients $((max_clients / 2)) --mode=Shuffled
        LD_LIBRARY_PATH=/usr/local/lib64/ ./"$benchmark_name" -e ../encoding_$2.json --dont_cache_binary_tables -o ../"$benchmark_name"_$2_"$max_clients"_sf"$scale_factor"_shuffled.json -s "$scale_factor" -t 1800 --scheduler --clients $max_clients --mode=Shuffled > ../sizes_$2.txt
      else
        LD_LIBRARY_PATH=/usr/local/lib64/ ./"$benchmark_name" -e ../encoding_$2.json --dont_cache_binary_tables -o ../"$benchmark_name"_$2_sf"$scale_factor"_singlethreaded.json -s "$scale_factor"  > ../sizes_$2.txt
      fi
    fi
    cd ..
}

# Configuration
clang_version=11
compiler="gcc"
cppcompiler="g++"
run_multithreaded=true
max_clients=`lscpu -b -p=CPU | grep -v '^#' | sort -u | wc -l`
benchmark_name="hyriseBenchmarkTPCH"
scale_factor=10

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
cd hyriseColumnCompressionBenchmark && git pull

# Execute Benchmarks
run_benchmark benchmark/compactVectorSegmentOldMaster CompactVector
run_benchmark benchmark/compactVectorSegmentOldMaster CompactVector
run_benchmark benchmark/compactVectorSegmentOldMaster Dictionary
run_benchmark benchmark/compactVectorSegmentOldMaster FrameOfReference
run_benchmark benchmark/compactVectorSegmentOldMaster Unencoded
run_benchmark benchmark/compactVectorSegmentOldMaster LZ4
run_benchmark benchmark/compactVectorSegmentOldMaster RunLength
run_benchmark benchmark/implementSIMDCAI SIMDCAI "cd third_party/SIMDCompressionAndIntersection && make all -j 16 && cd -"
run_benchmark benchmark/turboPFOR TurboPFOR
run_benchmark benchmark/turboPFOR_bitpacking TurboPFOR_bitpacking


# Process Results
zip -m ../$(hostname)_"$benchmark_name"_segmentencoding$(date +%Y%m%d) "$benchmark_name"* sizes*
cd ..
