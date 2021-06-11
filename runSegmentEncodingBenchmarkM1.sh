#!/bin/bash

run_benchmark() {
    # Checkout Git
    git checkout $1 && git pull && git submodule init && git submodule update
    # Run Benchmark without LTO
    if [ -n "$3" ]; then
       eval $3
    fi
    mkdir -p cmake-build-release && cd cmake-build-release
    # rm -rf *
    if cmake .. -DCMAKE_C_COMPILER=/opt/homebrew/opt/llvm@11/bin/clang -DCMAKE_CXX_COMPILER=/opt/homebrew/opt/llvm@11/bin/clang++ -DCMAKE_BUILD_TYPE=Release -DHYRISE_RELAXED_BUILD=On -GNinja && ninja "$benchmark_name" ; then
        cd ..
        if [ "$run_multithreaded" = true ] ; then
            if ./cmake-build-release/"$benchmark_name" -e ./encoding_$2.json --dont_cache_binary_tables -o ./"$benchmark_name"_$2_28_sf"$scale_factor"_shuffled.json -s "$scale_factor" -t 1800 --scheduler --clients $max_clients --mode=Shuffled ; then
                echo "success"
            else
                # benchmark doesn't support scale factor
                ./cmake-build-release/"$benchmark_name" -e ./encoding_$2.json --dont_cache_binary_tables -o ./"$benchmark_name"_$2_28_sf"$scale_factor"_shuffled.json -t 1800 --scheduler --clients $max_clients --mode=Shuffled
            fi

        else
            ./cmake-build-release/"$benchmark_name" -e ./encoding_$2.json --dont_cache_binary_tables -o ./"$benchmark_name"_$2_sf"$scale_factor"_singlethreaded.json -s "$scale_factor"  > ./sizes_$2.txt
        fi
    else
        cd ..
    fi
}

# Configuration
run_multithreaded=true
max_clients=8
benchmark_name="hyriseBenchmarkTPCH"
scale_factor=3

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
#run_benchmark benchmark/implementSIMDCAI SIMDCAI "cd third_party/SIMDCompressionAndIntersection && make all -j 16 && cd -"
#run_benchmark benchmark/turboPFOR TurboPFOR
#run_benchmark benchmark/turboPFOR_bitpacking TurboPFOR_bitpacking
run_benchmark benchmark/compactVectorSegment1 CompactVector
run_benchmark benchmark/compactVectorSegment1 Dictionary
run_benchmark benchmark/compactVectorSegment1 FrameOfReference
run_benchmark benchmark/compactVectorSegment1 Unencoded
run_benchmark benchmark/compactVectorSegment1 LZ4
run_benchmark benchmark/compactVectorSegment1 RunLength


# Process Results
zip ../$(hostname)_"$benchmark_name"_segmentencoding$(date +%Y%m%d) "$benchmark_name"* sizes*
cd ..
