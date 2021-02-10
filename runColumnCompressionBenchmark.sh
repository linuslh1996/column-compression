run_benchmark() {
    # Checkout Git
    git checkout $1 && git pull && git submodule init && git submodule update
    # Run Benchmark without LTO
    mkdir -p cmake-build-release && cd cmake-build-release
    rm -rf *
    cmake .. -DCMAKE_BUILD_TYPE=Release -DHYRISE_RELAXED_BUILD=On
    make hyriseBenchmarkTPCH -j 16 && ./hyriseBenchmarkTPCH -e ../encoding_$2.json --dont_cache_binary_tables -o ../tpch_$2_1.json -r 100  >> ../sizes_$2.txt
    # Run Benchmark with LTO
    rm -rf *
    cmake .. -DCMAKE_BUILD_TYPE=Release -DHYRISE_RELAXED_BUILD=On -DENABLE_LTO=On
    make hyriseBenchmarkTPCH -j 16 && ./hyriseBenchmarkTPCH -e ../encoding_$2.json -q 1--dont_cache_binary_tables -o ../tpch_$2_LTO_1.json -r 100
    cd ..
}

rm -rf hyriseColumnCompressionBenchmark
git clone git@github.com:benrobby/hyrise.git hyriseColumnCompressionBenchmark
cd hyriseColumnCompressionBenchmark

run_benchmark benchmarking/bitCompression dictionary
run_benchmark benchmarking/bitCompression bitpacking_turbopfor
run_benchmark benchmark/compactVetor bitpacking_compactvector
