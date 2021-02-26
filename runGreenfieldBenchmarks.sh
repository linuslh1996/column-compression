rm -rf hyriseGreenfieldBenchmark
git clone git@github.com:benrobby/hyrise.git hyriseGreenfieldBenchmark
cd hyriseGreenfieldBenchmark

git checkout ben/benchmarking && git pull
git submodule init && git submodule update
cd third_party/TurboPFor && make all -j 16 && cd -
cd third_party/SIMDCompressionAndIntersection && make all -j 16 && cd -
cd third_party/sdsl-lite && ./install.sh ./ && cd -

mkdir cmake-build-release && cd cmake-build-release
cmake .. -DCMAKE_C_COMPILER=clang-10 -DCMAKE_CXX_COMPILER=clang++-10 -DCMAKE_BUILD_TYPE=Release -DHYRISE_RELAXED_BUILD=On -DENABLE_UNSUPPORTED_COMPILER=On -GNinja
ninja hyriseBenchmarkColumnCompression
./hyriseBenchmarkColumnCompression --benchmark_filter="" --benchmark_format=console --benchmark_out=benchmark_results.txt --benchmark_out_format=csv --benchmark_min_time=0.2
mv bits_per_int.csv bits_per_int_nolto.csv
mv benchmark_results.txt benchmark_results_nolto.txt

cmake .. -DCMAKE_C_COMPILER=clang-10 -DCMAKE_CXX_COMPILER=clang++-10 -DCMAKE_BUILD_TYPE=Release -DHYRISE_RELAXED_BUILD=On -DENABLE_UNSUPPORTED_COMPILER=On -DENABLE_LTO=On -GNinja --benchmark_min_time=0.2
ninja hyriseBenchmarkColumnCompression
./hyriseBenchmarkColumnCompression --benchmark_filter="" --benchmark_format=console --benchmark_out=benchmark_results.txt --benchmark_out_format=csv


zip greenfield_results.zip  bits_per_int.csv benchmark_results.txt bits_per_int_nolto.csv benchmark_results_nolto.txt
