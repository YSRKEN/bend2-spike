// nqueens.bend と同じビットの数え方を C で書いたもの。速度比較の基準と、答え合わせに使う。
//   clang -O3 -fopenmp nqueens.c -o nqueens-c && OMP_NUM_THREADS=12 ./nqueens-c 12
// 並列にするのは最初の 2 行の置き方（N * N 通り）だけで、その先は 1 スレッドで数える。
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

static uint32_t go(uint32_t k, uint32_t all, uint32_t cols, uint32_t l, uint32_t r) {
  if (k == 0) {
    return 1;
  }
  uint32_t n = 0;
  uint32_t free = all & ~(cols | l | r);
  while (free != 0) {
    uint32_t b = free & -free;
    free ^= b;
    n += go(k - 1, all, cols | b, (l | b) << 1, (r | b) >> 1);
  }
  return n;
}

int main(int argc, char** argv) {
  uint32_t n = argc > 1 ? (uint32_t)strtoul(argv[1], NULL, 10) : 12;
  uint32_t all = (1u << n) - 1;
  uint32_t total = 0;
#pragma omp parallel for schedule(dynamic, 1) reduction(+ : total)
  for (uint32_t i = 0; i < n * n; i++) {
    uint32_t b0 = 1u << (i / n);
    uint32_t b1 = 1u << (i % n);
    uint32_t l = b0 << 1, r = b0 >> 1;
    if ((b0 | l | r) & b1) {
      continue;
    }
    total += go(n - 2, all, b0 | b1, (l | b1) << 1, (r | b1) >> 1);
  }
  printf("%u\n", total);
  return 0;
}
