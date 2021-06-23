#!/bin/bash

run_benchmark() {
    # Checkout Git
    git checkout $1 && git pull && git submodule init && git submodule update
    # Run Benchmark without LTO
    if [ -n "$3" ]; then
       eval $3 && echo "setup"
    fi
    mkdir -p cmake-build-release && cd cmake-build-release
    rm -rf *
    
    if cmake .. -DCMAKE_C_COMPILER=clang-$clang_version -DCMAKE_CXX_COMPILER=clang++-$clang_version -DCMAKE_BUILD_TYPE=Release -DHYRISE_RELAXED_BUILD=On -GNinja && ninja "$benchmark_name" ; then
    #if true; then
      if [ "$run_multithreaded" = true ] ; then
          cd ..
          cmd="./cmake-build-release/${benchmark_name} -e ./encoding_${2}.json --dont_cache_binary_tables -o ./tpch_${2}_${max_clients}_shuffled.json -t ${max_time} --scheduler --clients ${max_clients} --mode=Shuffled"
          if [ "$run_pcm" = true ] ; then
              sudo ${amd_pcm_path} -m memory,tlb,l1,l2,l3 -c package=1 -q -A package -o ${benchmark_name}_${2}_${max_clients}_pcm.log  -- numactl -m 1 -N 1 $cmd | ts -s "%s" > ${benchmark_name}_${2}_${max_clients}.log
	      python3 ../extract_csv_from_pcm_log.py AMD ${benchmark_name}_${2}_${max_clients}.log ${benchmark_name}_${2}_${max_clients}_pcm.log


	      #sudo ./pcm/pcm.x 1 -csv=test.log --nosockets --nocores -- numactl -m 0 -N 0 ./hyrise_wip/rel_clang/hyriseBenchmarkTPCH -s 1 --mode=Shuffled -t 60 --clients 10 2>/dev/null
	  else
              eval $cmd
          fi
      else
          cd ..
          ./cmake-build-release/"$benchmark_name" -e ./encoding_$2.json --dont_cache_binary_tables -o ./tpch_$2_singlethreaded.json >> ./sizes_$2.txt
        fi
    else
         cd ..
    fi
    
}

# Configuration
clang_version=11
run_multithreaded=true
max_clients=48
scale_factor=10
max_time=1800
benchmark_name="hyriseBenchmarkTPCH"
run_pcm=true

amd_pcm_path="/home/Martin.Boissier/AMDuProf_Linux_x64_3.4.475/bin/AMDuProfPcm"

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
cd hyriseColumnCompressionBenchmark

# Execute Benchmarks
run_benchmark benchmark/compactVetor bitpacking_compactvector
run_benchmark benchmark/compactVectorFixed bitpacking_compactvector_f
run_benchmark benchmarking/compressionUnencoded compressionUnencoded
run_benchmark benchmarking/bitCompressionSIMDCAI bitpacking_simdcai "cd third_party/SIMDCompressionAndIntersection && make all -j 16 && cd -"
run_benchmark benchmarking/bitCompression dictionary "cd third_party/TurboPFor-Integer-Compression && make all -j 8 && cd -"
run_benchmark benchmarking/bitCompression bitpacking_turbopfor

# Process Result
zip -m ../$(hostname)_"$benchmark_name"_columncompression$(date +%Y%m%d) "$benchmark_name"* sizes* *pcm.csv
cd ..
