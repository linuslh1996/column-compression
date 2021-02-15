run_benchmark() {
    # Checkout Git
    git checkout $1 && git pull && git submodule init && git submodule update
    # Run Benchmark without LTO
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

run_benchmark benchmarking/bitCompression dictionary
run_benchmark benchmarking/bitCompression bitpacking_turbopfor
run_benchmark benchmark/compactVetor bitpacking_compactvector
run_benchmark benchmark/compactVetor fsba
run_benchmark benchmark/compactVetor simdbp
