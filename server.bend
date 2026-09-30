# 小さな HTTP サーバー
#   GET /             -> 挨拶
#   GET /hello/<name> -> "Hello, <name>!"
#   GET /pow2/<d>     -> 2^d を並列の分割統治で数える (d <= 30)
#   それ以外          -> 404
import Base

# ---- 応答の組み立て ----

# UTF-8 でのバイト数（String.length は文字数を返すため自前で数える）
def utf8.width3(+c: U32, small: Bool) -> Nat:
  match small:
    case True{}:
      3n
    case False{}:
      4n

def utf8.width2(+c: U32, small: Bool) -> Nat:
  match small:
    case True{}:
      2n
    case False{}:
      utf8.width3(c, (c < 65536 : U32))

def utf8.width(+c: U32, small: Bool) -> Nat:
  match small:
    case True{}:
      1n
    case False{}:
      utf8.width2(c, (c < 2048 : U32))

def utf8.bytes(s: String, acc: Nat) -> Nat:
  match s:
    case SNil{}:
      acc
    case SCon{Chr{+c}, t}:
      utf8.bytes(t, Nat.add(acc, utf8.width(c, (c < 128 : U32))))

def respond(status: String, +body: String) -> String:
  len = Nat.show(utf8.bytes(body, 0n))
  String.concat([
    "HTTP/1.1 ", status, "\r\n",
    "Content-Type: text/plain; charset=utf-8\r\n",
    "Content-Length: ", len, "\r\n",
    "Connection: close\r\n\r\n",
    body])

# ---- リクエスト行からパスを取り出す ----

def pick(m: Maybe<&2, String>) -> String:
  match m:
    case None{}:
      "/"
    case Some{p}:
      p

def path_of(req: String) -> String:
  pick(List.get(&2, String, String.split(req, ' '), 1n))

# ---- 並列計算 ----

def pow2(+n: Nat) -> U32:
  match n:
    case 0n:
      1
    case 1n+p:
      a b = pow2(p) pow2(p)
      (a + b : U32)

def pow2.check(+d: U32, ok: Bool) -> String:
  match ok:
    case False{}:
      respond("400 Bad Request", "depth must be <= 30\n")
    case True{}:
      respond("200 OK", "pow2(" ++ U32.show(d) ++ ") = " ++ U32.show(pow2(U32.to_nat(d))) ++ "\n")

def pow2.page(m: Maybe<&2, U32>) -> String:
  match m:
    case None{}:
      respond("400 Bad Request", "depth must be a number\n")
    case Some{+d}:
      pow2.check(d, (d <= 30 : U32))

# ---- ルーティング（if がないので Bool に match する。呼ばれる側を先に書く） ----

def route.pow2(+path: String, hit: Bool) -> String:
  match hit:
    case True{}:
      pow2.page(U32.read(String.drop(path, 6n)))
    case False{}:
      respond("404 Not Found", "not found: " ++ path ++ "\n")

def route.hello(+path: String, hit: Bool) -> String:
  match hit:
    case True{}:
      respond("200 OK", "Hello, " ++ String.drop(path, 7n) ++ "!\n")
    case False{}:
      route.pow2(path, String.starts_with(path, "/pow2/"))

def route.root(+path: String, hit: Bool) -> String:
  match hit:
    case True{}:
      respond("200 OK", "Hello from Bend!\n")
    case False{}:
      route.hello(path, String.starts_with(path, "/hello/"))

def route(+path: String) -> String:
  route.root(path, String.eq(path, "/"))

# ---- 1 接続の処理 ----

def handle.sent(m: Socket & Result<&1, &1, U32 & String, Unit>) -> IO(Unit):
  (s, r) = m
  Socket.close(s)

# 受信に失敗した接続は閉じるだけにする（IO.pass は失敗でプログラム全体を終了させる）
def handle.read(m: Socket & Result<&1, &1, U32 & String, String>) -> IO(Unit):
  (s, r) = m
  match r:
    case Done{req}:
      +path = path_of(req)
      do IO<Unit>:
        Unit <- IO.print("GET " ++ path)
        sent : Socket & Result<&1, &1, U32 & String, Unit> <- TCP.send(s, route(path))
        handle.sent(sent)
    case Fail{e}:
      Socket.close(s)

def handle(s: Socket) -> IO(Unit):
  do IO<Unit>:
    m : Socket & Result<&1, &1, U32 & String, String> <- TCP.recv(s, 4096)
    handle.read(m)

# ---- accept ループ（停止性のため Nat の燃料で回数を決める） ----

def serve.got(rest: Listener -> IO(Unit), m: Listener & Result<&1, &1, U32 & String, Socket>) -> IO(Unit):
  (l, r) = m
  do IO<Unit>:
    s : Socket <- IO.pass(Socket, r)
    Unit <- IO.spawn(Unit, handle(s))
    rest(l)

def serve(n: Nat, l: Listener) -> IO(Unit):
  match n:
    case 0n:
      Listener.close(l)
    case 1n+p:
      IO.bind(Listener & Result<&1, &1, U32 & String, Socket>, Unit,
        TCP.accept(l), serve.got(l2 => serve(p, l2)))

def main() -> IO(Unit):
  do IO<Unit>:
    l : Listener <- IO.try(Listener, TCP.listen("127.0.0.1", 8080))
    Unit <- IO.print("listening on http://127.0.0.1:8080")
    serve(1000000n, l)
