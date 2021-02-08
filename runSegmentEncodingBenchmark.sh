rm -rf hyriseColumnCompressionBenchmark &&
git clone git@github.com:benrobby/hyrise.git hyriseColumnCompressionBenchmark && cd hyriseColumnCompressionBenchmark &&

# SIMDCAI
git checkout benchmark/implementSIMDCAI && git pull &&
git submodule init && git submodule update &&
mkdir cmake-build-release && cd cmake-build-release &&
cmake .. -DCMAKE_BUILD_TYPE=Release -DHYRISE_RELAXED_BUILD=On && make hyriseBenchmarkTPCH -j 16 &&
./hyriseBenchmarkTPCH -e ../encoding_SIMDCAI.json --dont_cache_binary_tables -o ../tpch_SIMDCAI_1.json -r 100 >> ../sizes_SIMDCAI.txt &&
rm -rf * &&
cmake .. -DCMAKE_BUILD_TYPE=Release -DHYRISE_RELAXED_BUILD=On -DENABLE_LTO=On && make hyriseBenchmarkTPCH -j 16 &&
./hyriseBenchmarkTPCH -e ../encoding_SIMDCAI.json --dont_cache_binary_tables -o ../tpch_SIMDCAI_LTO_1.json -r 100 &&


# TurboPFOR
git checkout benchmark/turboPFOR && git pull &&
rm -rf * &&
git submodule init && git submodule update &&
cd ../third_party/TurboPFor-Integer-Compression && make all -j 8 && cd - &&
cmake .. -DCMAKE_BUILD_TYPE=Release -DHYRISE_RELAXED_BUILD=On && make hyriseBenchmarkTPCH -j 16 &&
./hyriseBenchmarkTPCH -e ../encoding_TurboPFOR.json --dont_cache_binary_tables -o ../tpch_TurboPFOR_1.json -r 100 >> ../sizes_TurboPFOR.txt &&
rm -rf * &&
cmake .. -DCMAKE_BUILD_TYPE=Release -DHYRISE_RELAXED_BUILD=On -DENABLE_LTO=On && make hyriseBenchmarkTPCH -j 16 &&
./hyriseBenchmarkTPCH -e ../encoding_TurboPFOR.json --dont_cache_binary_tables -o ../tpch_TurboPFOR_LTO_1.json -r 100 &&

# Dict
./hyriseBenchmarkTPCH -e ../encoding_Dictionary.json --dont_cache_binary_tables -o ../tpch_Dictionary_1.json -r 100 >> ../sizes_Dictionary.txt &&
rm -rf * &&
cmake .. -DCMAKE_BUILD_TYPE=Release -DHYRISE_RELAXED_BUILD=On -DENABLE_LTO=On && make hyriseBenchmarkTPCH -j 16 &&
./hyriseBenchmarkTPCH -e ../encoding_Dictionary.json --dont_cache_binary_tables -o ../tpch_Dictionary_LTO_1.json -r 100 &&

# FrameOfReference
./hyriseBenchmarkTPCH -e ../encoding_FrameOfReference.json --dont_cache_binary_tables -o ../tpch_FrameOfReference_1.json -r 100 >> ../sizes_FrameOfReference.txt &&
rm -rf * &&
cmake .. -DCMAKE_BUILD_TYPE=Release -DHYRISE_RELAXED_BUILD=On -DENABLE_LTO=On && make hyriseBenchmarkTPCH -j 16 &&
./hyriseBenchmarkTPCH -e ../encoding_FrameOfReference.json --dont_cache_binary_tables -o ../tpch_FrameOfReference_LTO_1.json -r 100 &&

# Unencoded
./hyriseBenchmarkTPCH -e ../encoding_Unencoded.json --dont_cache_binary_tables -o ../tpch_Unencoded_1.json -r 100 >> ../sizes_Unencoded.txt &&
rm -rf * &&
cmake .. -DCMAKE_BUILD_TYPE=Release -DHYRISE_RELAXED_BUILD=On -DENABLE_LTO=On && make hyriseBenchmarkTPCH -j 16 &&
./hyriseBenchmarkTPCH -e ../encoding_Unencoded.json --dont_cache_binary_tables -o ../tpch_Unencoded_LTO_1.json -r 100
