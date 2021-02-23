for branch_name in benchmark/compactVetor benchmark/compareColumnEncodings benchmark/implementSIMDCAI benchmark/turboPFOR benchmark/turboPFOR_bitpacking benchmarking/bitCompression benchmarking/bitCompressionSIMDCAI benchmarking/bitCompressionSIMDCAISeq benchmarking/bitCompressionSequential;
  do
    git checkout "$branch_name" && git pull && git pull https://github.com/hyrise/hyrise $1 --no-edit && git push
  done
