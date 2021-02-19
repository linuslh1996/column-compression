run_benchmark() {
    # Checkout Git
    git checkout $1 && git pull && git submodule init && git submodule update
    # Run Benchmark without LTO
    if [ -n "$3" ]; then
       eval $3
    fi
    mkdir -p cmake-build-release && cd cmake-build-release
    rm -rf *
    cmake .. -DCMAKE_C_COMPILER=clang-10 -DCMAKE_CXX_COMPILER=clang++-10 -DCMAKE_BUILD_TYPE=Release -DHYRISE_RELAXED_BUILD=On -GNinja && ninja hyriseBenchmarkTPCH &&
    ./hyriseBenchmarkTPCH -e ../encoding_$2.json --dont_cache_binary_tables -o ../tpch_$2_5.json -r 100 --scheduler --clients 5
    ./hyriseBenchmarkTPCH -e ../encoding_$2.json --dont_cache_binary_tables -o ../tpch_$2_10.json -r 100 --scheduler --clients 10 
    ./hyriseBenchmarkTPCH -e ../encoding_$2.json --dont_cache_binary_tables -o ../tpch_$2_20.json -r 100 --scheduler --clients 20
    cd ..
}

rm -rf hyriseColumnCompressionBenchmark
git clone git@github.com:benrobby/hyrise.git hyriseColumnCompressionBenchmark
cd hyriseColumnCompressionBenchmark

run_benchmark benchmark/implementSIMDCAI SIMDCAI "cd third_party/SIMDCompressionAndIntersection && make all -j 16 && cd -"

git checkout benchmark/turboPFOR && git pull &&
git submodule init && git submodule update &&
cd third_party/TurboPFor-Integer-Compression && make all -j 8 && cd - &&

run_benchmark benchmark/turboPFOR TurboPFOR
run_benchmark benchmark/turboPFOR_bitpacking TurboPFOR_bitpacking

run_benchmark benchmark/turboPFOR Dictionary
run_benchmark benchmark/turboPFOR FrameOfReference
run_benchmark benchmark/turboPFOR Unencoded
run_benchmark benchmark/turboPFOR LZ4
run_benchmark benchmark/turboPFOR RunLength
