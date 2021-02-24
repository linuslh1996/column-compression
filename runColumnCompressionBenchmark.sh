run_benchmark() {
    # Checkout Git
    git checkout $1 && git pull && git submodule init && git submodule update
    # Run Benchmark without LTO
    if [ -n "$3" ]; then
      eval $3 && echo "setup"
    fi
    mkdir -p cmake-build-release && cd cmake-build-release
    rm -rf *
    cmake .. -DCMAKE_C_COMPILER=clang-10 -DCMAKE_CXX_COMPILER=clang++-10 -DCMAKE_BUILD_TYPE=Release -DHYRISE_RELAXED_BUILD=On -GNinja && ninja hyriseBenchmarkTPCH &&
    ./hyriseBenchmarkTPCH -s 10 -e ../encoding_$2.json --dont_cache_binary_tables -o ../tpch_$2_1.json -r 100  >> ../sizes_$2.txt
    # Run Benchmark with LTO 
    cmake ..  -DCMAKE_C_COMPILER=clang-10 -DCMAKE_CXX_COMPILER=clang++-10 -DENABLE_LTO=On -DCMAKE_BUILD_TYPE=Release -DHYRISE_RELAXED_BUILD=On -GNinja && ninja hyriseBenchmarkTPCH &&
    ./hyriseBenchmarkTPCH -s 10 -e ../encoding_$2.json --dont_cache_binary_tables -o ../tpch_$2_LTO_1.json -r 100
    cd ..
}

rm -rf hyriseColumnCompressionBenchmark
git clone git@github.com:benrobby/hyrise.git hyriseColumnCompressionBenchmark
cd hyriseColumnCompressionBenchmark

run_benchmark benchmarking/bitCompression dictionary
run_benchmark benchmarking/bitCompression bitpacking_turbopfor
run_benchmark benchmarking/bitCompressionSequential bitpacking_turbopfor_seq
run_benchmark benchmark/compactVetor bitpacking_compactvector
run_benchmark benchmark/compactVectorFixed bitpacking_compactvector_f
run_benchmark benchmark/compactVetor simdbp
run_benchmark benchmarking/bitCompressionSIMDCAISeq bitpacking_simdcai_seq "cd third_party/SIMDCompressionAndIntersection && make all -j     16 && cd -"
run_benchmark benchmarking/bitCompressionSIMDCAI bitpacking_simdcai "cd third_party/SIMDCompressionAndIntersection && make all -j     16 && cd -"
