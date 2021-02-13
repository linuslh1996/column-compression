run_benchmark() {
    # Checkout Git
    git checkout $1 && git pull && git submodule init && git submodule update
    # Run Benchmark without LTO
    mkdir -p cmake-build-release && cd cmake-build-release
    rm -rf *
    cmake .. -DCMAKE_C_COMPILER=clang-10 -DCMAKE_CXX_COMPILER=clang++-10 -DCMAKE_BUILD_TYPE=Release -DHYRISE_RELAXED_BUILD=On -GNinja && ninja hyriseBenchmarkTPCH &&
    ./hyriseBenchmarkTPCH -e ../encoding_$2.json --dont_cache_binary_tables -o ../tpch_$2_1.json -r 100  >> ../sizes_$2.txt
    # Run Benchmark with LTO 
    cmake ..  -DCMAKE_C_COMPILER=clang-10 -DCMAKE_CXX_COMPILER=clang++-10 -DENABLE_LTO=On -DCMAKE_BUILD_TYPE=Release -DHYRISE_RELAXED_BUILD=On -GNinja && ninja hyriseBenchmarkTPCH &&
    ./hyriseBenchmarkTPCH -e ../encoding_$2.json --dont_cache_binary_tables -o ../tpch_$2_LTO_1.json -r 100
    cd ..
}

rm -rf hyriseColumnCompressionBenchmark
git clone git@github.com:benrobby/hyrise.git hyriseColumnCompressionBenchmark
cd hyriseColumnCompressionBenchmark
    # Checkout Git
    git checkout  benchmark/compareColumnEncodings && git pull && git submodule init && git submodule update
git checkout benchmark/compareColumnEncodings && cp FastPFOR_CMakeLists.txt third_party/FastPFor/CMakeLists.txt
    # Run Benchmark without LTO
    mkdir -p cmake-build-release && cd cmake-build-release
    rm -rf *
    cmake .. -DCMAKE_C_COMPILER=clang-10 -DCMAKE_CXX_COMPILER=clang++-10 -DCMAKE_BUILD_TYPE=Release -DHYRISE_RELAXED_BUILD=On -GNinja && ninja hyriseBenchmarkTPCH &&
    ./hyriseBenchmarkTPCH -e ../encoding_fastpfor.json --dont_cache_binary_tables -o ../tpch_fastpfor_1.json -r 100  >> ../sizes_fastpfor.txt
    # Run Benchmark with LTO 
    cmake ..  -DCMAKE_C_COMPILER=clang-10 -DCMAKE_CXX_COMPILER=clang++-10 -DENABLE_LTO=On -DCMAKE_BUILD_TYPE=Release -DHYRISE_RELAXED_BUILD=On -GNinja && ninja hyriseBenchmarkTPCH &&
    ./hyriseBenchmarkTPCH -e ../encoding_fastpfor.json --dont_cache_binary_tables -o ../tpch_fastpfor_LTO_1.json -r 100
    cd ..

run_benchmark benchmark/implementSIMDCAI SIMDCAI

git checkout benchmark/turboPFOR && git pull &&
git submodule init && git submodule update &&
cd third_party/TurboPFor-Integer-Compression && make all -j 8 && cd - &&

run_benchmark benchmark/turboPFOR TurboPFOR

run_benchmark benchmark/turboPFOR Dictionary
run_benchmark benchmark/turboPFOR FrameOfReference
run_benchmark benchmark/turboPFOR Unencoded
