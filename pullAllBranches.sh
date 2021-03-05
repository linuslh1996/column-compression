for branch_name in benchmark/compactVetor benchmark/compactVectorFixed benchmark/compareColumnEncodings benchmark/implementSIMDCAI benchmark/turboPFOR benchmark/turboPFOR_bitpacking benchmarking/bitCompression benchmarking/bitCompressionSIMDCAI benchmarking/bitCompressionSIMDCAISeq benchmarking/bitCompressionSequential benchmarking/compressionUnencoded;
  do
    git checkout "$branch_name" && git pull && git cherry-pick 0598a2040c4f4d5520b9d6710e795a47b28240d && git push
  done
