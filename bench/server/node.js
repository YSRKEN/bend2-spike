// 比較用の最小の HTTP サーバー。concurrency/stall.bend の / と同じ本文を返し、要求ごとに接続を閉じる
const http = require("http");
http.createServer((req, res) => {
  res.writeHead(200, { "Content-Type": "text/plain", "Connection": "close" });
  res.end("fast\n");
}).listen(8080, "127.0.0.1");
