#!/bin/bash
# bench/ の計測を回す。bend が PATH にある環境（Linux、macOS、Containerfile のイメージの中）ならどこでも使える。
#
#   run.sh mandel|nqueens|threads|sort    # 題材ごと。どれも 10 分以内に終わる大きさにしてある
#   BENCH_QUICK=1 run.sh mandel      # 小さな大きさで、全部の条件が動くかだけを見る
#
# 各条件を 2 回ずつ、条件を交互に並べて測る（同じ条件を続けて測ると、機の状態の変化が一方に偏るため）。
# 時間はプロセスの起動から終了まで（GPU の場合、初期化と .gpu の読み込みを含む）。結果は TSV で標準出力に出し、
# 何を飛ばしたかなどの知らせは標準エラーに出す。
#
# 環境の差はここで吸収する。
# - CPU のスレッド数: nproc か sysctl で数える。threads で試す数は BENCH_THREADS（例: "1 2 3 4"）で変えられる
# - C 版: clang -fopenmp を試し、通らなければ（Apple clang）Homebrew の libomp を使う。どちらも無ければ C の行を飛ばす
# - GPU（BEND_GPU=auto|off）: macOS は Metal、Linux は CUDA。WSL2 では build-wsl-gpu.sh の回避を当てる。
#   .gpu ができなければ GPU の行を飛ばす（bend 2.0.29〜2.0.34 は M2 の Metal でここに当たる。2.0.35 で直った。docs/gpu.md）
# - bend の版: 既定は ~/.bend。別の版で測るときは BEND_HOME にその版を展開した場所を指定する
# - GPU 用に別の版の bend を使うときは BEND_GPU_HOME にその BEND_HOME を指定する。2.0.27 のように IO.args の先頭に
#   実行ファイル名を入れない版では、BEND_GPU_ARGS_PREFIX=x で引数の前にダミーを置く
set -euo pipefail
cd "$(dirname "$0")"
export BEND_HOME="${BEND_HOME:-$HOME/.bend}" BEND_NO_TELEMETRY=1
export PATH="$BEND_HOME/bin:$PATH"
tmp=$(mktemp -d "${TMPDIR:-/tmp}/bend-bench.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
note() { echo "[run.sh] $*" >&2; }

# ---- 時間 ----
# GNU の date はナノ秒を出せる。macOS の date は出せないので perl（Time::HiRes）で測る
if [ "$(date +%N)" != N ] && [ -n "$(date +%N)" ]; then
  now_ms() { echo $(( $(date +%s%N) / 1000000 )); }
else
  now_ms() { perl -MTime::HiRes=time -e 'printf "%d\n", time * 1000'; }
fi

t() {
  local s out
  s=$(now_ms)
  out=$("$@")
  printf '%s\t%s\n' "$out" "$(( $(now_ms) - s ))"
}

row() {  # row <題材> <条件> <引数> <コマンド...>
  local what=$1 how=$2 arg=$3
  shift 3
  printf '%s\t%s\t%s\t' "$what" "$how" "$arg"
  t "$@"
}

# ---- CPU ----
ncpu=$(nproc 2>/dev/null || sysctl -n hw.ncpu)
threads=${BENCH_THREADS:-$(printf '%s\n' 1 2 4 $((ncpu / 2)) "$ncpu" | awk '$1 >= 1 && !seen[$1]++' | sort -n | tr '\n' ' ')}

# ---- C 版（OpenMP） ----
cflags=(-O3 -ffp-contract=off)
omp=()
probe=$tmp/omp.c
printf '#include <omp.h>\nint main(void){return omp_get_max_threads() > 0 ? 0 : 1;}\n' > "$probe"
if clang -fopenmp "$probe" -o "$tmp/omp" 2>/dev/null; then
  omp=(-fopenmp)
elif libomp=$(brew --prefix libomp 2>/dev/null) \
  && clang -Xpreprocessor -fopenmp -I"$libomp/include" "$probe" -L"$libomp/lib" -lomp -o "$tmp/omp" 2>/dev/null; then
  omp=(-Xpreprocessor -fopenmp -I"$libomp/include" -L"$libomp/lib" -lomp)
else
  note "OpenMP でビルドできない（Linux は libomp-dev、macOS は brew install libomp）。C の行を飛ばす"
fi
c_build() {  # c_build <名前>: $tmp/<名前>-c を作る。作れなければ 1
  [ ${#omp[@]} -gt 0 ] && clang "${cflags[@]}" "$1.c" ${omp[@]+"${omp[@]}"} -o "$tmp/$1-c"
}

# ---- Bend の CPU 版 ----
# bend x.bend -o x は、`!` を含むプログラムでは GPU 用のビルド（--gpu-build）まで行う。そこが失敗しても
# 実行ファイル自体はできているので、できたかだけを見る（CPU では --gpu off で走らせる）
bend_build() {  # bend_build <名前>
  bend "$1.bend" -o "$tmp/$1" > /dev/null 2>&1 || true
  [ -x "$tmp/$1" ] || { note "$1 の実行ファイルができなかった"; exit 1; }
}

# ---- GPU 版 ----
gpu=${BEND_GPU:-auto}
if [ "$gpu" = auto ]; then
  if [ "$(uname -s)" = Darwin ]; then
    gpu=metal
  elif [ -e /dev/dxg ]; then
    gpu=cuda-wsl  # WSL2 の GPU。concurrent managed access が無いので回避を当てる（docs/gpu.md）
  elif [ -e "${CUDA_HOME:-/usr/local/cuda}/include/nvrtc.h" ]; then
    gpu=cuda
  else
    gpu=off
  fi
fi
gpu_args=(--threads 1)
[ "$gpu" = cuda-wsl ] && gpu_args=(--gpu 1GB --threads 1)  # 既定の大きさでは確保に失敗した
# 空になりうる配列は ${a[@]+"${a[@]}"} で展開する（macOS の bash 3.2 は、set -u で空の配列をエラーにする）
gpu_pre=(${BEND_GPU_ARGS_PREFIX:-})
gpu_build() {  # gpu_build <名前>: $tmp/<名前>-gpu を作る。作れなければ 1
  local home=${BEND_GPU_HOME:-$BEND_HOME}
  case $gpu in
    off) return 1 ;;
    cuda-wsl) PATH="$home/bin:$PATH" BEND_HOME="$home" bash build-wsl-gpu.sh "$1.bend" "$tmp/$1-gpu" > /dev/null 2>&1 || return 1 ;;
    *) BEND_HOME="$home" "$home/bin/bend" "$1.bend" -o "$tmp/$1-gpu" > /dev/null 2>&1 || true ;;
  esac
  [ -f "$tmp/$1-gpu.gpu" ] || [ "$gpu" = cuda-wsl ] || { note "$1 の GPU 用のプログラムができない（$gpu）。GPU の行を飛ばす"; return 1; }
}

# 作れたものだけ測る。C 版ができたら c_<名前>、GPU 版ができたら g_<名前> を 1 にする
build_all() {  # build_all <名前...>
  local n
  for n in "$@"; do
    bend_build "$n"
    eval "c_$n=0 g_$n=0"
    if [ -f "$n.c" ] && c_build "$n"; then eval "c_$n=1"; fi
    if gpu_build "$n"; then eval "g_$n=1"; fi
  done
}
has() { eval "[ \"\${$1_$2:-0}\" = 1 ]"; }  # has c|g <名前>

# ---- 電源（macOS） ----
# 省電力モードやバッテリーでは CPU が抑えられ、C まで 1.7 倍遅くなった（2026-10-06、M2）。承知で測るなら BENCH_ALLOW_LOWPOWER=1
power=""
if command -v pmset > /dev/null 2>&1; then
  lpm=$(pmset -g | awk '$1 == "lowpowermode" {print $2}')
  src=$(pmset -g batt | sed -n "1s/.*'\(.*\)'.*/\1/p")
  power="、電源: ${src:-?}、lowpowermode: ${lpm:-?}"
  if { [ "${lpm:-0}" = 1 ] || [ "$src" = "Battery Power" ]; } && [ "${BENCH_ALLOW_LOWPOWER:-0}" != 1 ]; then
    note "省電力モードかバッテリーで動いている（${power#、}）。AC につなぎ、省電力モードを切ってから測る"
    exit 1
  fi
fi

quick=${BENCH_QUICK:-0}
note "$(bend version)${power}、CPU $ncpu、threads: $threads、GPU: $gpu、OpenMP: ${omp[*]:-なし}${BEND_GPU_HOME:+、GPU 用の bend: $BEND_GPU_HOME}"
printf '題材\t条件\t引数\t答え\tミリ秒\n'
case ${1:-} in
  mandel)
    build_all mandel
    if [ "$quick" = 1 ]; then its="0 16"; big=""; else its="0 256 1024 4096"; big=16384; fi
    for rep in 1 2; do
      for it in $its; do
        row mandel "bend cpu$ncpu" "$it" "$tmp/mandel" "$it" --gpu off
        if has g mandel; then row mandel "bend gpu" "$it" "$tmp/mandel-gpu" ${gpu_pre[@]+"${gpu_pre[@]}"} "$it" "${gpu_args[@]}"; fi
        if has c mandel; then row mandel "C cpu$ncpu" "$it" env OMP_NUM_THREADS="$ncpu" "$tmp/mandel-c" "$it"; fi
      done
      if [ -n "$big" ] && has g mandel; then
        row mandel "bend gpu" "$big" "$tmp/mandel-gpu" ${gpu_pre[@]+"${gpu_pre[@]}"} "$big" "${gpu_args[@]}"
      fi
    done
    ;;
  threads)
    build_all mandel
    if [ "$quick" = 1 ]; then it=16; else it=256; fi
    for rep in 1 2; do
      for th in $threads; do
        row mandel "bend cpu$th" "$it" "$tmp/mandel" "$it" --gpu off --threads "$th"
        if has c mandel; then row mandel "C cpu$th" "$it" env OMP_NUM_THREADS="$th" "$tmp/mandel-c" "$it"; fi
      done
    done
    ;;
  nqueens)
    build_all nqueens nqueens_split
    if [ "$quick" = 1 ]; then ns="8 9"; else ns="13 14 15"; fi
    for rep in 1 2; do
      for n in $ns; do
        row nqueens "bend cpu1" "$n" "$tmp/nqueens" "$n" --gpu off --threads 1
        row nqueens "bend cpu$ncpu" "$n" "$tmp/nqueens" "$n" --gpu off
        if has g nqueens; then row nqueens "bend gpu" "$n" "$tmp/nqueens-gpu" ${gpu_pre[@]+"${gpu_pre[@]}"} "$n" "${gpu_args[@]}"; fi
        row nqueens "split cpu1" "$n" "$tmp/nqueens_split" "$n" --gpu off --threads 1
        row nqueens "split cpu$ncpu" "$n" "$tmp/nqueens_split" "$n" --gpu off
        if has g nqueens_split; then row nqueens "split gpu" "$n" "$tmp/nqueens_split-gpu" ${gpu_pre[@]+"${gpu_pre[@]}"} "$n" "${gpu_args[@]}"; fi
        if has c nqueens; then
          row nqueens "C cpu1" "$n" env OMP_NUM_THREADS=1 "$tmp/nqueens-c" "$n"
          row nqueens "C cpu$ncpu" "$n" env OMP_NUM_THREADS="$ncpu" "$tmp/nqueens-c" "$n"
        fi
      done
    done
    ;;
  sort)
    # sort/main.bend は大きさ（2^d 個）が check(16n) に固定なので、写しの d だけを変えてビルドする（docs/proofs.md の速さ）
    if [ "$quick" = 1 ]; then ds="10 11"; else ds="15 16 17"; fi
    for d in $ds; do
      sed "s/check(16n)/check(${d}n)/" ../sort/main.bend > "$tmp/sort$d.bend"
      grep -q "check(${d}n)" "$tmp/sort$d.bend" || { note "sort/main.bend に check(16n) が無い"; exit 1; }
      bend "$tmp/sort$d.bend" -o "$tmp/sort$d" > /dev/null 2>&1 || true
      [ -x "$tmp/sort$d" ] || { note "sort$d の実行ファイルができなかった"; exit 1; }
    done
    for rep in 1 2; do
      for d in $ds; do
        row sort "bend cpu1" "2^$d" "$tmp/sort$d" --gpu off --threads 1
        row sort "bend cpu$ncpu" "2^$d" "$tmp/sort$d" --gpu off
      done
    done
    ;;
  *)
    echo "usage: run.sh mandel|nqueens|threads|sort" >&2
    exit 2
    ;;
esac
