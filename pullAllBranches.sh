for branch_name in benchmark/compactVetor benchmark/compareColumnEncodings benchmark/implementSIMDCAI benchmark/turboPFOR benchmarking/bitCompression;
  do
    git checkout "$branch_name" && git pull && git pull https://github.com/hyrise/hyrise $1 --no-edit && git push
  done
