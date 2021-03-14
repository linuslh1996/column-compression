run_benchmark(){

    to_measure=l2_rqsts.all_demand_data_rd,l2_rqsts.demand_data_rd_hit,l2_rqsts.demand_data_rd_miss,LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses,LLC-prefetch-misses

    perf stat -e "$to_measure" -o ../"$folder"/"$1"_shuffled_sf"$scale_factor"_cache.txt ./hyriseBenchmarkTPCH -r 300 -s "$scale_factor" -q 3 --clients 16 --scheduler --mode=Shuffled -e ../encoding_"$1".json --dont_cache_binary_tables > ../"$folder"/"$1"_shuffled_sf"$scale_factor"_benchmark.txt
    perf stat -e "$to_measure" -o ../"$folder"/"$1"_baseline_sf"$scale_factor"_cache.txt ./hyriseBenchmarkTPCH -r 1 -s "$scale_factor" -q 3 --clients 16 --scheduler --mode=Shuffled -e ../encoding_"$1".json --dont_cache_binary_tables > ../"$folder"/"$1"_baseline_sf"$scale_factor"_benchmark.txt

}

folder="cache_results_3"
mkdir -p ../"$folder"

scale_factor=2
run_benchmark TurboPFOR_bitpacking
run_benchmark Unencoded
run_benchmark Dictionary
run_benchmark FrameOfReference


