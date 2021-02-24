run_benchmark() {
    # Checkout Git
    git checkout $1 && git pull && git submodule init && git submodule update
    # Run Benchmark without LTO
    if [ -n "$3" ]; then
       eval $3
    fi
    mkdir -p cmake-build-release && cd cmake-build-release
    rm -rf *
    if cmake .. -DCMAKE_C_COMPILER=clang-$clang_version -DCMAKE_CXX_COMPILER=clang++-$clang_version -DCMAKE_BUILD_TYPE=Release -DHYRISE_RELAXED_BUILD=On -GNinja && ninja hyriseBenchmarkTPCH ; then
      if [ "$run_multithreaded" = true ] ; then
          ./hyriseBenchmarkTPCH -e ../encoding_$2.json --dont_cache_binary_tables -o ../tpch_$2_14_shuffled.json -s 10 -t 1800 --scheduler --clients 14 --mode=Shuffled
          ./hyriseBenchmarkTPCH -e ../encoding_$2.json --dont_cache_binary_tables -o ../tpch_$2_28_shuffled.json -s 10 -t 1800 --scheduler --clients 28 --mode=Shuffled
      else
          ./hyriseBenchmarkTPCH -e ../encoding_$2.json --dont_cache_binary_tables -o ../tpch_$2_singlethreaded.json
        fi
    fi
    cd ..
}

# Configuration
clang_version=11
run_multithreaded=true

if [ "$1" == "-single" ]; then
    run_multithreaded=false
fi

if [ "$1" == "-multi" ]; then
    run_multithreaded=true
fi

# Clone Hyrise Repo
rm -rf hyriseColumnCompressionBenchmark
git clone git@github.com:benrobby/hyrise.git hyriseColumnCompressionBenchmark
cd hyriseColumnCompressionBenchmark

# Execute Benchmarks
run_benchmark benchmark/implementSIMDCAI SIMDCAI "cd third_party/SIMDCompressionAndIntersection && make all -j 16 && cd -"
run_benchmark benchmark/turboPFOR TurboPFOR
run_benchmark benchmark/turboPFOR_bitpacking TurboPFOR_bitpacking
run_benchmark benchmark/turboPFOR Dictionary
run_benchmark benchmark/turboPFOR FrameOfReference
run_benchmark benchmark/turboPFOR Unencoded
run_benchmark benchmark/turboPFOR LZ4
run_benchmark benchmark/turboPFOR RunLength

# Process Results
zip segmentencoding$(date +%Y%m%d) *.json

