#!/bin/bash

run_benchmark() {
    # Checkout Git
    git checkout $1 && git pull && git submodule init && git submodule update
    # Run Benchmark without LTO
    if [ -n "$3" ]; then
       eval $3
    fi
    mkdir -p cmake-build-release && cd cmake-build-release
    rm -rf *

    if cmake .. -DCMAKE_C_COMPILER=/opt/homebrew/opt/llvm@12/bin/clang -DCMAKE_CXX_COMPILER=/opt/homebrew/opt/llvm@12/bin/clang++ -DCMAKE_BUILD_TYPE=Release -DHYRISE_RELAXED_BUILD=On -GNinja && ninja "$benchmark_name" ; then
      if [ "$run_multithreaded" = true ] ; then
        cd ..
        for i in "2,3" "4,6" "8,12"  # (cores,clients) tuples
        do
          IFS=',' read item1 item2 <<< "${i}"
          cores=$item1
          max_clients=$item2
          if ./cmake-build-release/$benchmark_name -e ./encoding_${2}.json --dont_cache_binary_tables -o ./${benchmark_name}_${2}_${max_clients}lients_${cores}cores_shuffled.json -t $max_time -s $scale_factor --cores $cores --scheduler --clients $max_clients --mode=Shuffled; then
            echo "Success"
          else
            # scale factor not supported
            ./cmake-build-release/"$benchmark_name" -e ./encoding_${2}.json --dont_cache_binary_tables -o ./${benchmark_name}_${2}_"$max_clients"clients_${cores}cores_shuffled.json -t $max_time --cores $cores --scheduler --clients $max_clients --mode=Shuffled
          fi
        done
      else
          cd ..
          if ./cmake-build-release/"$benchmark_name" -e ./encoding_${2}.json --dont_cache_binary_tables -o ./${benchmark_name}_${2}_singlethreaded.json -s ${scale_factor} >> ./sizes_${benchmark_name}_${2}.txt; then
            echo "Success"
          else
            # scale factor not supported
            ./cmake-build-release/"$benchmark_name" -e ./encoding_${2}.json --dont_cache_binary_tables -o ./${benchmark_name}_${2}_singlethreaded.json >> ./sizes_${benchmark_name}_${2}.txt
          fi
        fi
    else
         cd ..
    fi
}

# Configuration
run_multithreaded=true
max_time=1800
benchmark_name="hyriseBenchmarkTPCH"
scale_factor=3  # use 10 for single-threaded comparisons; 3 for anything multi-threaded

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
cd hyriseColumnCompressionBenchmark && git pull

# Execute Benchmarks
run_benchmark benchmark/compactVectorSegmentOldMaster CompactVector
run_benchmark benchmark/compactVectorSegmentOldMaster Dictionary
run_benchmark benchmark/compactVectorSegmentOldMaster FrameOfReference
run_benchmark benchmark/compactVectorSegmentOldMaster Unencoded
run_benchmark benchmark/compactVectorSegmentOldMaster LZ4
run_benchmark benchmark/compactVectorSegmentOldMaster RunLength


# Process Results
zip -m ../$(hostname)_"$benchmark_name"_segmentencoding$(date +%Y%m%d) "$benchmark_name"* sizes*
cd ..
