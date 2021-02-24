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
    ./hyriseBenchmarkTPCH -s 10 -e ../encoding_$2.json --dont_cache_binary_tables -o ../tpch_$2_5.json -r 100 --scheduler --mode Shuffled --clients 5  
    ./hyriseBenchmarkTPCH -s 10 -e ../encoding_$2.json --dont_cache_binary_tables -o ../tpch_$2_10.json -r 100 --scheduler --mode Shuffled --clients 10  
    ./hyriseBenchmarkTPCH -s 10 -e ../encoding_$2.json --dont_cache_binary_tables -o ../tpch_$2_20.json -r 100 --scheduler --mode Shuffled --clients 20
    cd ..
}

rm -rf hyriseColumnCompressionBenchmark
git clone git@github.com:benrobby/hyrise.git hyriseColumnCompressionBenchmark
cd hyriseColumnCompressionBenchmark

run_benchmark benchmarking/bitCompressionSIMDCAISeq bitpacking_simdcai_seq "cd third_party/SIMDCompressionAndIntersection && make all -j     16 && cd -"
run_benchmark benchmarking/bitCompressionSIMDCAI bitpacking_simdcai "cd third_party/SIMDCompressionAndIntersection && make all -j     16 && cd -"
run_benchmark benchmarking/bitCompression dictionary "cd third_party/TurboPFor-Integer-Compression && make all -j 8 && cd -"
run_benchmark benchmarking/bitCompression bitpacking_turbopfor
run_benchmark benchmarking/bitCompressionSequential bitpacking_turbopfor_seq
run_benchmark benchmark/compactVetor bitpacking_compactvector
run_benchmark benchmark/compactVectorFixed bitpacking_compactvector_f
run_benchmark benchmark/compactVetor simdbp
