#!/usr/bin/env bash
#
# Builds the benchmarks for .NET and for llvm, and times each benchmark on
# both, each in a process of its own. Writes one table: family, benchmark,
# size, fastest and median milliseconds on each target, llvm's median over
# .NET's, and whether the two computed the same checksum.
#
#   benchmarks/run.sh [options] [benchmark ...]
#
#   --scale <x>      multiplies every benchmark's size (default 1)
#   --repeats <n>    timed runs per benchmark after one warm-up (default 5)
#   --check          runs each benchmark once on each target, untimed, and
#                    compares the checksums; no timing
#   --no-build       uses the binaries the last run built
#   --out <dir>      where the raw results go (default: a new temporary dir)
#
# With no benchmark names, every benchmark runs. The .NET build is the
# Release configuration of benchmarks.ghulproj, against the runtime built
# from this repository; the llvm build is `ghul build --target llvm
# --optimise 2` against the same sources. Timings mean nothing on a busy
# machine: run it when nothing else is.

set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
cd "$here"

scale=1
repeats=5
check=0
build=1
out=""
names=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --scale) scale=${2:?--scale needs a value}; shift 2 ;;
        --repeats) repeats=${2:?--repeats needs a value}; shift 2 ;;
        --check) check=1; shift ;;
        --no-build) build=0; shift ;;
        --out) out=${2:?--out needs a directory}; shift 2 ;;
        -h|--help) sed -n '2,/^set -euo/p' "$0" | sed 's/^# \{0,1\}//; /^set -euo/d'; exit 0 ;;
        -*) echo "run.sh: unknown option $1" >&2; exit 2 ;;
        *) names+=("$1"); shift ;;
    esac
done

out=${out:-$(mktemp -d)}
mkdir -p "$out"

dotnet_bin=(dotnet "$here/bin/Release/net10.0/benchmarks.dll")
llvm_bin=("$here/out/llvm/benchmarks")

if [[ $build == 1 ]]; then
    echo "building for .NET" >&2
    dotnet build -c Release -v:q -nologo benchmarks.ghulproj > "$out/dotnet-build.log" 2>&1 ||
        { echo "the .NET build failed: $out/dotnet-build.log" >&2; exit 1; }

    echo "building for llvm" >&2
    dotnet ghul build --target llvm --optimise 2 > "$out/llvm-build.log" 2>&1 ||
        { echo "the llvm build failed: $out/llvm-build.log" >&2; exit 1; }
fi

if [[ $check == 1 ]]; then
    "${dotnet_bin[@]}" check "$scale" > "$out/dotnet.check"
    "${llvm_bin[@]}" check "$scale" > "$out/llvm.check"

    if diff "$out/dotnet.check" "$out/llvm.check" > "$out/check.diff"; then
        echo "all $(wc -l < "$out/dotnet.check") checksums agree"
    else
        echo "the targets disagree:" >&2
        cat "$out/check.diff" >&2
        exit 1
    fi

    exit 0
fi

if [[ ${#names[@]} == 0 ]]; then
    mapfile -t names < <("${dotnet_bin[@]}" list | cut -f2)
fi

printf 'family\tbenchmark\tsize\tdotnet_min\tdotnet_median\tllvm_min\tllvm_median\tllvm/dotnet\tchecksums\n' > "$out/table.tsv"

# Each benchmark's line: family, name, size, fastest ms, median ms, checksum,
# and a seventh field, "inconsistent", where its own runs disagreed.
for name in "${names[@]}"; do
    echo "timing $name" >&2
    IFS=$'\t' read -r family _ size d_min d_median d_sum d_note < <("${dotnet_bin[@]}" run "$name" "$scale" "$repeats")
    IFS=$'\t' read -r _ _ _ l_min l_median l_sum l_note < <("${llvm_bin[@]}" run "$name" "$scale" "$repeats")

    if [[ "$d_sum" == "$l_sum" && -z "${d_note:-}" && -z "${l_note:-}" ]]; then
        agree=agree
    else
        agree=DIFFER
    fi

    ratio=$(awk -v l="$l_median" -v d="$d_median" 'BEGIN { printf "%.2f", (d > 0 ? l / d : 0) }')

    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$family" "$name" "$size" "$d_min" "$d_median" "$l_min" "$l_median" "$ratio" "$agree" >> "$out/table.tsv"
done

column -t -s $'\t' "$out/table.tsv"

echo "raw results: $out" >&2
