// 公式の pong（demos/app_pong_game_2d、Apache-2.0）を、そのままブラウザで動かす。
// main.bend は bash web/pong/fetch.sh で取ってくる。ゲームの中身には手を入れていない。
import M from "./main.bend";
import { runApp } from "../app/host.js";

const canvas = document.getElementById("field");
const info = document.getElementById("info");
let game = null;

function start() {
  game?.stop();
  canvas.focus();
  game = runApp(canvas, {
    init: M["Pong.init"](),
    view: M["Pong.view"],
    tick: M["Pong.tick"],
    onFrame: ({ frames, leaves, ms }) => {
      if (frames % 30 === 0) info.textContent = `${frames} コマ目、画像の葉 ${leaves} 枚、1 コマ ${ms.toFixed(2)} ms`;
    },
    onQuit: () => { info.textContent = "Esc で終わった。「もう一度」で始め直す"; },
  });
}

window.bend = M;
document.getElementById("restart").addEventListener("click", start);
start();
