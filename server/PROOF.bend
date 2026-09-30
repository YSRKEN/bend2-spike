# LAWS.bend の証明
import Base
import ./server.bend as Srv
import ./LAWS.bend as Laws

# ---- ルーティング: 計算で両辺が一致する。name の空・非空で場合分け ----

def Laws.root_page():
  {==}

def Laws.hello_echo(name):
  match name:
    case SNil{}:
      {==}
    case SCon{h, t}:
      {==}

# ---- Nat の補題 ----

def add_zero(a: Nat) -> {Nat.add(a, 0n) == a : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_zero(p) : {1n+Nat.add(p, 0n) == 1n+_ : Nat}
      {==}

def add_assoc(a: Nat, -b: Nat, -c: Nat) -> {Nat.add(a, Nat.add(b, c)) == Nat.add(Nat.add(a, b), c) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_assoc(p, b, c) : {1n+Nat.add(p, Nat.add(b, c)) == 1n+_ : Nat}
      {==}

# ---- 1 文字分: 仕様のバイト数 = 実装の幅 ----

def len4(-c: U32, small: Bool, -rest: List<&2, U32>) -> {List.length(&2, U32, Laws.Spec.char4(c, small, rest)) == Nat.add(Srv.utf8.width3(c, small), List.length(&2, U32, rest)) : Nat}:
  match small:
    case True{}:
      {==}
    case False{}:
      {==}

def len2(+c: U32, small: Bool, -rest: List<&2, U32>) -> {List.length(&2, U32, Laws.Spec.char2(c, small, rest)) == Nat.add(Srv.utf8.width2(c, small), List.length(&2, U32, rest)) : Nat}:
  match small:
    case True{}:
      {==}
    case False{}:
      len4(c, (c < 65536 : U32), rest)

def len1(+c: U32, small: Bool, -rest: List<&2, U32>) -> {List.length(&2, U32, Laws.Spec.char(c, small, rest)) == Nat.add(Srv.utf8.width(c, small), List.length(&2, U32, rest)) : Nat}:
  match small:
    case True{}:
      {==}
    case False{}:
      len2(c, (c < 2048 : U32), rest)

# ---- 文字列全体: 累積値 acc を一般化して帰納法 ----

def bytes_gen(s: String, +acc: Nat) -> {Nat.add(acc, List.length(&2, U32, Laws.Spec.encode(s))) == Srv.utf8.bytes(s, acc) : Nat}:
  match s:
    case SNil{}:
      add_zero(acc)
    case SCon{Chr{+c}, t}:
      %bytes_gen(t, Nat.add(acc, Srv.utf8.width(c, (c < 128 : U32)))) : {Nat.add(acc, List.length(&2, U32, Laws.Spec.encode(SCon{Chr{c}, t}))) == _ : Nat}
      %add_assoc(acc, Srv.utf8.width(c, (c < 128 : U32)), List.length(&2, U32, Laws.Spec.encode(t))) : {Nat.add(acc, List.length(&2, U32, Laws.Spec.encode(SCon{Chr{c}, t}))) == _ : Nat}
      %len1(c, (c < 128 : U32), Laws.Spec.encode(t)) : {Nat.add(acc, List.length(&2, U32, Laws.Spec.encode(SCon{Chr{c}, t}))) == Nat.add(acc, _) : Nat}
      {==}

def Laws.utf8_bytes(s):
  bytes_gen(s, 0n)

# ---- 応答の形式 ----

def append_nil(s: String) -> {String.append(s, SNil{}) == s : String}:
  match s:
    case SNil{}:
      {==}
    case SCon{h, t}:
      %append_nil(t) : {SCon{h, String.append(t, SNil{})} == SCon{h, _} : String}
      {==}

# respond を展開した形の中で、Content-Length の値を utf8_bytes で、末尾の本文を append_nil で書き換える
def Laws.response_format(status, body):
  %Laws.utf8_bytes(body) : {String.concat(["HTTP/1.1 ", status, "\r\n", "Content-Type: text/plain; charset=utf-8\r\n", "Content-Length: ", Nat.show(_), "\r\n", "Connection: close\r\n\r\n", body]) == "HTTP/1.1 " ++ (status ++ ("\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: " ++ (Nat.show(List.length(&2, U32, Laws.Spec.encode(body))) ++ ("\r\nConnection: close\r\n\r\n" ++ body)))) : String}
  %append_nil(body) : {String.concat(["HTTP/1.1 ", status, "\r\n", "Content-Type: text/plain; charset=utf-8\r\n", "Content-Length: ", Nat.show(List.length(&2, U32, Laws.Spec.encode(body))), "\r\n", "Connection: close\r\n\r\n", body]) == "HTTP/1.1 " ++ (status ++ ("\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: " ++ (Nat.show(List.length(&2, U32, Laws.Spec.encode(body))) ++ ("\r\nConnection: close\r\n\r\n" ++ _)))) : String}
  {==}

# ---- path_of ----

# 空白を含まない p を前に付けると、分割結果の先頭要素に p がくっつくだけ
def split_prefix(p: String, -y: String, -h: String, -t: List<&2, String>, e: {h <> t == String.split(y, ' ') : List<&2, String>}, ns: Laws.Spec.NoSpace(p)) -> {(p ++ h) <> t == String.split(p ++ y, ' ') : List<&2, String>}:
  match p:
    case SNil{}:
      e
    case SCon{c, pt}:
      (ec, nt) = ns
      %ec : {SCon{c, pt ++ h} <> t == String.split.fin(c, String.split(pt ++ y, ' '), _) : List<&2, String>}
      %split_prefix(pt, y, h, t, e, nt) : {SCon{c, pt ++ h} <> t == String.split.push(c, _) : List<&2, String>}
      {==}

# " " ++ x の分割は、空文字列を x の分割の前に付けたもの
def split_space(-x: String, -h: String, -t: List<&2, String>, e: {h <> t == String.split(x, ' ') : List<&2, String>}) -> {"" <> (h <> t) == String.split(" " ++ x, ' ') : List<&2, String>}:
  %e : {"" <> (h <> t) == "" <> _ : List<&2, String>}
  {==}

def Laws.path_of_request(m, p, r, nm, np):
  %split_prefix(m, " " ++ (p ++ (" " ++ r)), "", (p ++ "") <> String.split(r, ' '), split_space(p ++ (" " ++ r), p ++ "", String.split(r, ' '), split_prefix(p, " " ++ r, "", String.split(r, ' '), {==}, np)), nm) : {Srv.pick(List.get(&2, String, _, 1n)) == p : String}
  append_nil(p)

# ---- path_of と route をつなぐ ----

# "/hello/" の 7 文字はどれも空白ではないので、name が空白なしなら "/hello/" ++ name も空白なし
def nospace_hello(-name: String, nn: Laws.Spec.NoSpace(name)) -> Laws.Spec.NoSpace("/hello/" ++ name):
  ({==}, ({==}, ({==}, ({==}, ({==}, ({==}, ({==}, nn)))))))

# path_of_request で「取り出されるパス」を確定させ、hello_echo で「そのパスへの応答」を確定させて推移律でつなぐ
def Laws.hello_request(m, name, r, nm, nn):
  Equal.trans(String,
    Srv.route(Srv.path_of(m ++ (" " ++ (("/hello/" ++ name) ++ (" " ++ r))))),
    Srv.route("/hello/" ++ name),
    Srv.respond("200 OK", "Hello, " ++ name ++ "!\n"),
    Equal.cong(String, String, x => Srv.route(x),
      Srv.path_of(m ++ (" " ++ (("/hello/" ++ name) ++ (" " ++ r)))),
      "/hello/" ++ name,
      Laws.path_of_request(m, "/hello/" ++ name, r, nm, nospace_hello(name, nn))),
    Laws.hello_echo(name))
