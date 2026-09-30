#pragma push_macro("FAR")
#undef FAR
#include <zlib.h>
#pragma pop_macro("FAR")

Term zlib_crc32_run(Env e, Term* f, IoWork* w) {
  u64 len;
  char* s = io_cstr(e, f[0], &len);
  uLong c = crc32(0L, (const Bytef*)s, len);
  free(s);
  return (Term)(uint32_t)c;
}

static void __attribute__((constructor)) zlib_crc32_use(void) {
  io_eff(CID(Zlib.crc32), zlib_crc32_run, 0);
}
