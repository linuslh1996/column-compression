unzd() {
    if [[ $# != 1 ]]; then echo I need a single argument, the name of the archive to extract; return 1; fi
    target="${1%.zip}"
    unzip "$1" -d "${target##*/}"
    cd "${target##*/}"
}
unzd $1
mkdir sizes
mv sizes_* sizes
mkdir shuffled
mv *shuffled.json shuffled
mkdir multithreaded
mv *20.json *10.json *5.json multithreaded
python3 ../../notebooks/benchmark_to_csv.py .