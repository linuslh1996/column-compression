run_benchmark(){

    to_measure=l2_rqsts.all_demand_data_rd,l2_rqsts.demand_data_rd_hit,l2_rqsts.demand_data_rd_miss,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses,LLC-prefetch-misses

    #perf stat -e "$to_measure" -o ../cache_results/"$1"_shuffled_sf"$scale_factor"_cache.txt ./hyriseBenchmarkTPCH -t 600 -s "$scale_factor" --clients 10 --scheduler --mode=Shuffled -e ../encoding_"$1".json --dont_cache_binary_tables > ../cache_results/"$1"_shuffled_sf"$scale_factor"_benchmark.txt

    #perf stat -e "$to_measure" -o ../cache_results/"$1"_sequential_sf"$scale_factor"_cache.txt ./hyriseBenchmarkTPCH -r 200 -t 1800 -s "$scale_factor"  --clients 10 --scheduler -e ../encoding_"$1".json --dont_cache_binary_tables > ../cache_results/"$1"_sequential_sf"$scale_factor"_benchmark.txt

    perf stat -e "$to_measure" -o ../cache_results/"$1"_baseline_sf"$scale_factor"_cache.txt ./hyriseBenchmarkTPCH -r 1 -s "$scale_factor"  -e ../encoding_"$1".json --dont_cache_binary_tables > ../cache_results/"$1"_baseline_sf"$scale_factor"_benchmark.txt
}


mkdir -p ../cache_results

scale_factor=1
run_benchmark TurboPFOR_bitpacking
run_benchmark Unencoded
run_benchmark Dictionary
run_benchmark FrameOfReference
run_benchmark RunLength
run_benchmark LZ4

scale_factor=2
run_benchmark TurboPFOR_bitpacking
run_benchmark Unencoded
run_benchmark Dictionary
run_benchmark FrameOfReference
run_benchmark RunLength
run_benchmark LZ4

