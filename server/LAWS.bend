# サーバーの法則。人間が書いて確かめる側の仕様。PROOF.bend が証明する。
import Base
import ./server.bend as Srv

# ---- 仕様: UTF-8 の符号化（RFC 3629 のビット配置） ----
# rest の前に文字 c のバイト列を付ける

def Spec.char4(+c: U32, small: Bool, rest: List<&2, U32>) -> List<&2, U32>:
  match small:
    case True{}:
      (224 .|. (c >> 12n) : U32) <> ((128 .|. ((c >> 6n) .&. 63) : U32) <> ((128 .|. (c .&. 63) : U32) <> rest))
    case False{}:
      (240 .|. (c >> 18n) : U32) <> ((128 .|. ((c >> 12n) .&. 63) : U32) <> ((128 .|. ((c >> 6n) .&. 63) : U32) <> ((128 .|. (c .&. 63) : U32) <> rest)))

def Spec.char2(+c: U32, small: Bool, rest: List<&2, U32>) -> List<&2, U32>:
  match small:
    case True{}:
      (192 .|. (c >> 6n) : U32) <> ((128 .|. (c .&. 63) : U32) <> rest)
    case False{}:
      Spec.char4(c, (c < 65536 : U32), rest)

def Spec.char(+c: U32, small: Bool, rest: List<&2, U32>) -> List<&2, U32>:
  match small:
    case True{}:
      c <> rest
    case False{}:
      Spec.char2(c, (c < 2048 : U32), rest)

def Spec.encode(s: String) -> List<&2, U32>:
  match s:
    case SNil{}:
      Nil{}
    case SCon{Chr{+c}, t}:
      Spec.char(c, (c < 128 : U32), Spec.encode(t))

# ---- 仕様: 空白（' '）を含まない文字列 ----
# 各文字について「空白ではない」ことの証拠を並べた型

def Spec.NoSpace(s: String) -> Type:
  match s:
    case SNil{}:
      Unit
    case SCon{c, t}:
      {False{} == Char.is_eq(c, ' ') : Bool} & Spec.NoSpace(t)

# ---- 法則 ----

# LAW: "/" には決まった挨拶を返す
law root_page:
  {Srv.route("/") == Srv.respond("200 OK", "Hello from Bend!\n") : String}

# LAW: どんな名前でも /hello/<name> はその名前をそのまま埋め込んで 200 を返す
law hello_echo:
  for +name: String
  {Srv.route("/hello/" ++ name) == Srv.respond("200 OK", "Hello, " ++ name ++ "!\n") : String}

# LAW: Content-Length に使う utf8.bytes は、仕様どおり符号化したバイト列の長さに等しい
law utf8_bytes:
  for s: String
  {List.length(&2, U32, Spec.encode(s)) == Srv.utf8.bytes(s, 0n) : Nat}

# LAW: 応答の形式。Content-Length には、仕様どおりに符号化した本文のバイト数が入り、
# 空行の後に本文がそのまま続く
law response_format:
  for status: String
  for +body: String
  {Srv.respond(status, body) == "HTTP/1.1 " ++ (status ++ ("\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: " ++ (Nat.show(List.length(&2, U32, Spec.encode(body))) ++ ("\r\nConnection: close\r\n\r\n" ++ body)))) : String}

# LAW: リクエスト行 "<method> <path> <rest>" から、method と path が空白を含まなければ、
# path_of は path をそのまま取り出す（rest は何でもよい）
law path_of_request:
  for m: String
  for +p: String
  for r: String
  for nm: Spec.NoSpace(m)
  for np: Spec.NoSpace(p)
  {Srv.path_of(m ++ (" " ++ (p ++ (" " ++ r)))) == p : String}

# LAW: 受け取ったリクエスト行が "<method> /hello/<name> <rest>" で、method と name が空白を含まなければ、
# サーバーはその name を埋め込んだ 200 応答を返す（path_of と route をつないだ全体の主張）
law hello_request:
  for m: String
  for +name: String
  for r: String
  for nm: Spec.NoSpace(m)
  for nn: Spec.NoSpace(name)
  {Srv.route(Srv.path_of(m ++ (" " ++ (("/hello/" ++ name) ++ (" " ++ r))))) == Srv.respond("200 OK", "Hello, " ++ name ++ "!\n") : String}
