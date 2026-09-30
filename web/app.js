// mandel.bend の escape を画素ごとに呼んで canvas に描く。クリックした点を中心に 4 倍に拡大する。
import M from "./mandel.bend";

// 開発者ツールのコンソールから bend.escape(256n, -0.5, 0) のように呼べるようにしておく
window.bend = M;

const canvas = document.getElementById("view");
const info = document.getElementById("info");
const ctx = canvas.getContext("2d");
const W = canvas.width;
const H = canvas.height;
let view = { x: -0.5, y: 0, span: 3 };  // 中心と、横幅（複素平面の単位）

function iters() {
  return Number(document.getElementById("iters").value);
}

function color(n, k) {
  if (n >= k) {
    return [12, 12, 20];
  }
  // 脱出の早い点が大半なので、回数を対数で 0〜1 に割り当てる
  const t = Math.log1p(n) / Math.log1p(k);
  return [Math.round(255 * t), Math.round(220 * t * t * t), Math.round(40 + 160 * t * (1 - t))];
}

function draw() {
  const k = iters();
  const kn = BigInt(k);
  const img = ctx.createImageData(W, H);
  const s = view.span / W;
  const t0 = performance.now();
  for (let py = 0; py < H; py++) {
    const cy = view.y + (py - H / 2) * s;
    for (let px = 0; px < W; px++) {
      const n = M.escape(kn, view.x + (px - W / 2) * s, cy);
      const [r, g, b] = color(n, k);
      const i = (py * W + px) * 4;
      img.data[i] = r;
      img.data[i + 1] = g;
      img.data[i + 2] = b;
      img.data[i + 3] = 255;
    }
  }
  const ms = performance.now() - t0;
  ctx.putImageData(img, 0, 0);
  info.textContent = `${W}×${H} 画素、反復 ${k} 回: ${ms.toFixed(0)} ms（中心 ${view.x.toPrecision(6)} ${view.y >= 0 ? "+" : "−"} ${Math.abs(view.y).toPrecision(6)}i、幅 ${view.span.toPrecision(3)}）`;
}

canvas.addEventListener("click", (e) => {
  const r = canvas.getBoundingClientRect();
  const s = view.span / r.width;
  view = {
    x: view.x + (e.clientX - r.left - r.width / 2) * s,
    y: view.y + (e.clientY - r.top - r.height / 2) * s,
    span: view.span / 4,
  };
  draw();
});
document.getElementById("iters").addEventListener("change", draw);
document.getElementById("reset").addEventListener("click", () => {
  view = { x: -0.5, y: 0, span: 3 };
  draw();
});
draw();
