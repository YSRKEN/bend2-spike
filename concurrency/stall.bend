# 重い純粋計算の最中に、ほかの接続が待たされるのを避ける方法を比べるサーバー。
# 同じ計算 pow2(d)（2 の d 乗を分割統治で数える）を、4 通りの呼び方で受ける。
#
#   /            すぐ返す（待たされ方を測る側）
#   /pure/<d>    その場で計算する。server/server.bend の /pow2 と同じ（比べる基準）
#   /step/<d>    64 個に区切り、区切りごとに IO.sleep(0) で順番を譲る
#   /proc/<d>    自分自身を子プロセスとして起こし、Process.run で計算させる
#   /fork/<d>    IO.fork に渡して IO.join で待つ
#
#   bend stall.bend -o stall && ./stall            # 8080 で待ち受ける（BEND_HOST で待ち受け先を変える）
#   ./stall calc 28                                # 子プロセスとしての動き: pow2(28) を出力する
import Base

def pow2(+n: Nat) -> U32:
  match n:
    case 0n:
      1
    case 1n+p:
      a b = pow2(p) pow2(p)
      (a + b : U32)

# 本文は ASCII だけなので、Content-Length は文字数で足りる
def respond(status: String, +body: String) -> String:
  "HTTP/1.1 " ++ status ++ "\r\nContent-Type: text/plain\r\nContent-Length: " ++ Nat.show(String.length(body)) ++ "\r\nConnection: close\r\n\r\n" ++ body

def answer(+d: Nat, v: U32) -> String:
  respond("200 OK", "pow2(" ++ Nat.show(d) ++ ") = " ++ U32.show(v) ++ "\n")

def pick(m: Maybe<&2, String>) -> String:
  match m:
    case Some{p}:
      p
    case None{}:
      "/"

def path_of(req: String) -> String:
  pick(List.get(&2, String, String.split(req, ' '), 1n))

# ---- 4 通りの呼び方 ----

def pure.run(+d: Nat) -> IO(String):
  IO.pure(String, answer(d, pow2(d)))

# 残り k 回。1 回ごとに IO.sleep(0) で順番を譲ってから、pow2(d) を 1 つ足す
def step.go(k: Nat, +d: Nat, acc: U32) -> IO(U32):
  match k:
    case 0n:
      IO.pure(U32, acc)
    case 1n+p:
      do IO<U32>:
        Unit <- IO.sleep(0)
        step.go(p, d, (acc + pow2(d) : U32))

# pow2(d) = 64 * pow2(d - 6)。d が 6 未満なら区切らない
def step.pick(+d: Nat, big: Bool) -> IO(U32):
  match big:
    case True{}:
      step.go(64n, Nat.sub(d, 6n), 0)
    case False{}:
      IO.pure(U32, pow2(d))

def step.run(+d: Nat) -> IO(String):
  do IO<String>:
    v : U32 <- step.pick(d, Nat.is_ge(d, 6n))
    return answer(d, v)

def proc.got(r: Result<&1, &1, U32 & String, U32 & (String & String)>) -> String:
  match r:
    case Done{v}:
      (st, oe) = v
      (out, err) = oe
      respond("200 OK", out)
    case Fail{e}:
      respond("500 Internal Server Error", "the child process failed\n")

def proc.run(+self: String, +d: Nat) -> IO(String):
  do IO<String>:
    r : Result<&1, &1, U32 & String, U32 & (String & String)> <- Process.run(self, ["calc", Nat.show(d)], "", 4096, 600000)
    return proc.got(r)

def fork.run(+d: Nat) -> IO(String):
  do IO<String>:
    ch : Chan(U32) <- IO.fork(U32, IO.pure(U32, pow2(d)))
    v : U32 <- IO.join(U32, ch)
    return answer(d, v)

# ---- ルーティング ----

def depth.read(m: Maybe<&2, U32>) -> Maybe<&2, Nat>:
  match m:
    case Some{d}:
      Some{U32.to_nat(d)}
    case None{}:
      None{}

# 経路の 6 文字（"/pure/" など）の後ろを深さとして読む。30 を超えるものは断る
def depth(+path: String) -> Maybe<&2, Nat>:
  depth.read(U32.read(String.drop(path, 6n)))

def with.ok(-A: Type, +d: Nat, ok: Bool, run: Nat -> IO(String)) -> IO(String):
  match ok:
    case True{}:
      run(d)
    case False{}:
      IO.pure(String, respond("400 Bad Request", "depth must be <= 30\n"))

def with.got(m: Maybe<&2, Nat>, run: Nat -> IO(String)) -> IO(String):
  match m:
    case Some{+d}:
      with.ok(String, d, Nat.is_le(d, 30n), run)
    case None{}:
      IO.pure(String, respond("400 Bad Request", "depth must be a number\n"))

def with(+path: String, run: Nat -> IO(String)) -> IO(String):
  with.got(depth(path), run)

def route.fork(+path: String, hit: Bool) -> IO(String):
  match hit:
    case True{}:
      with(path, d => fork.run(d))
    case False{}:
      IO.pure(String, respond("404 Not Found", "not found\n"))

def route.proc(+path: String, +self: String, hit: Bool) -> IO(String):
  match hit:
    case True{}:
      with(path, d => proc.run(self, d))
    case False{}:
      route.fork(path, String.starts_with(path, "/fork/"))

def route.step(+path: String, +self: String, hit: Bool) -> IO(String):
  match hit:
    case True{}:
      with(path, d => step.run(d))
    case False{}:
      route.proc(path, self, String.starts_with(path, "/proc/"))

def route.pure(+path: String, +self: String, hit: Bool) -> IO(String):
  match hit:
    case True{}:
      with(path, d => pure.run(d))
    case False{}:
      route.step(path, self, String.starts_with(path, "/step/"))

def route.root(+path: String, +self: String, hit: Bool) -> IO(String):
  match hit:
    case True{}:
      IO.pure(String, respond("200 OK", "fast\n"))
    case False{}:
      route.pure(path, self, String.starts_with(path, "/pure/"))

def route(+path: String, +self: String) -> IO(String):
  route.root(path, self, String.eq(path, "/"))

# ---- 1 接続の処理 ----

def handle.sent(m: Socket & Result<&1, &1, U32 & String, Unit>) -> IO(Unit):
  (s, r) = m
  Socket.close(s)

def handle.read(+self: String, m: Socket & Result<&1, &1, U32 & String, String>) -> IO(Unit):
  (s, r) = m
  match r:
    case Done{req}:
      do IO<Unit>:
        resp : String <- route(path_of(req), self)
        sent : Socket & Result<&1, &1, U32 & String, Unit> <- TCP.send(s, resp)
        handle.sent(sent)
    case Fail{e}:
      Socket.close(s)

def handle(+self: String, s: Socket) -> IO(Unit):
  do IO<Unit>:
    m : Socket & Result<&1, &1, U32 & String, String> <- TCP.recv(s, 4096)
    handle.read(self, m)

# ---- accept ループ（停止性のため Nat の燃料で回数を決める） ----

def serve.got(+self: String, rest: Listener -> IO(Unit), m: Listener & Result<&1, &1, U32 & String, Socket>) -> IO(Unit):
  (l, r) = m
  do IO<Unit>:
    s : Socket <- IO.pass(Socket, r)
    Unit <- IO.spawn(Unit, handle(self, s))
    rest(l)

def serve(n: Nat, +self: String, l: Listener) -> IO(Unit):
  match n:
    case 0n:
      Listener.close(l)
    case 1n+p:
      IO.bind(Listener & Result<&1, &1, U32 & String, Socket>, Unit,
        TCP.accept(l), serve.got(self, l2 => serve(p, self, l2)))

def host.pick(r: Result<&1, &1, U32 & String, String>) -> String:
  match r:
    case Done{h}:
      h
    case Fail{e}:
      "127.0.0.1"

def listen(+self: String, +host: String) -> IO(Unit):
  do IO<Unit>:
    l : Listener <- IO.try(Listener, TCP.listen(host, 8080))
    Unit <- IO.print("listening on http://" ++ host ++ ":8080")
    serve(1000000n, self, l)

# ---- 起動: 引数が calc <d> なら子プロセスとして計算だけする ----

def calc.read(m: Maybe<&2, U32>) -> IO(Unit):
  match m:
    case Some{d}:
      IO.print(U32.show(pow2(U32.to_nat(d))))
    case None{}:
      IO.print("0")

def calc.arg(rest: List<String>) -> IO(Unit):
  match rest:
    case Con{d, _}:
      calc.read(U32.read(d))
    case Nil{}:
      IO.print("0")

def start.mode(+self: String, rest: List<String>, is_calc: Bool) -> IO(Unit):
  match is_calc:
    case True{}:
      calc.arg(rest)
    case False{}:
      IO.bind(Result<&1, &1, U32 & String, String>, Unit,
        IO.get_env("BEND_HOST"), r => listen(self, host.pick(r)))

# args は「自分のパス、第 1 引数、残り」。第 1 引数が calc なら、残りの先頭を深さとして読む
def start(args: List<String>) -> IO(Unit):
  match args:
    case Con{+self, Con{mode, more}}:
      start.mode(self, more, String.eq(mode, "calc"))
    case Con{+self, Nil{}}:
      start.mode(self, Nil{}, False{})
    case Nil{}:
      IO.print("no program name")

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    start(args)
