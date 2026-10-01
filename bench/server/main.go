// 比較用の最小の HTTP サーバー。concurrency/stall.bend の / と同じ本文を返し、要求ごとに接続を閉じる
package main

import "net/http"

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/plain")
		w.Header().Set("Connection", "close")
		w.Write([]byte("fast\n"))
	})
	http.ListenAndServe("127.0.0.1:8080", nil)
}
