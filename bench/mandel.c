// mandel.bend と同じ計算を C で書いたもの。速度比較の基準と、答え合わせに使う。
//   clang -O3 -ffp-contract=off -fopenmp mandel.c -o mandel-c && OMP_NUM_THREADS=12 ./mandel-c 256
// -ffp-contract=off は、掛け算と足し算を 1 命令（FMA）にまとめさせないため。
// まとめると丸めが変わり、Bend 版と合計が一致しなくなる。
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define SIDE 4096

static uint32_t orbit(uint32_t k, float cx, float cy) {
  float x = 0.0f, y = 0.0f;
  uint32_t n = 0;
  for (uint32_t i = 0; i < k; i++) {
    float xx = x * x;
    float yy = y * y;
    n += (xx + yy) < 4.0f;
    float nx = (xx - yy) + cx;
    float ny = (2.0f * x) * y + cy;
    x = nx;
    y = ny;
  }
  return n;
}

int main(int argc, char** argv) {
  uint32_t k = argc > 1 ? (uint32_t)strtoul(argv[1], NULL, 10) : 256;
  float s = 3.0f / (float)SIDE;
  uint32_t total = 0;
#pragma omp parallel for schedule(dynamic, 16) reduction(+ : total)
  for (int py = 0; py < SIDE; py++) {
    float cy = (float)py * s - 1.5f;
    for (int px = 0; px < SIDE; px++) {
      total += orbit(k, (float)px * s - 2.0f, cy);
    }
  }
  printf("%u\n", total);
  return 0;
}
