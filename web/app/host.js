// Bend の App（view と tick の組）をブラウザの canvas で動かす受け皿。
// bend の JS 出力には画面が無い（Window.open が「no display」で失敗する）ので、App.run の代わりをここで書く。
//
//   import M from "./main.bend";
//   import { runApp } from "../app/host.js";
//   runApp(canvas, { init: M["Pong.init"](), view: M["Pong.view"], tick: M["Pong.tick"] });
//
// 前提（公開された約束ではなく、bend 2.0.34 の JS 出力を読んで確かめたこと）:
// - view(state) は {$: "Tuple", fst: 次の状態, snd: 画像} を返す
// - tick(events, state) は IO を返す。IO は「結果を受け取る関数」を渡すと結果を返す関数になっている。
//   tick が IO.pure だけで書かれていれば、Some{次の状態} か None（終了）が返る。音や sleep などの入出力を使う tick は動かない
// - 画像は Pix{color}（0xRRGGBB で正方形を塗る）と Qua{tl, tr, bl, br} の 4 分木。根は幅と高さを覆う 2 の累乗の正方形

// キーの番号は、ネイティブ版（effs/window.c）と同じく Mac の決まりに合わせる
const NAMED = {
  Escape: 27, Enter: 13, Tab: 9, Backspace: 127,
  ArrowUp: 63232, ArrowDown: 63233, ArrowLeft: 63234, ArrowRight: 63235,
  Insert: 63271, Delete: 63272, Home: 63273, End: 63275, PageUp: 63276, PageDown: 63277,
};
const MODIFIERS = {
  MetaRight: 65590, MetaLeft: 65591, ShiftLeft: 65592, CapsLock: 65593, AltLeft: 65594,
  ControlLeft: 65595, ShiftRight: 65596, AltRight: 65597, ControlRight: 65598,
};

export function keyCode(e) {
  if (e.code in MODIFIERS) return MODIFIERS[e.code];
  if (e.key in NAMED) return NAMED[e.key];
  const f = /^F([1-9]|1[0-2])$/.exec(e.key);
  if (f) return 63235 + Number(f[1]);
  if (e.key.length === 1) return e.key.toLowerCase().codePointAt(0);
  return null;
}

function list(xs) {
  return xs.reduceRight((tail, head) => ({ $: "Con", head, tail }), { $: "Nil" });
}

function draw(ctx, img, x, y, size) {
  if (img.$ === "Pix") {
    ctx.fillStyle = "#" + (img.color & 0xffffff).toString(16).padStart(6, "0");
    ctx.fillRect(x, y, size, size);
    return 1;
  }
  const h = size / 2;
  return draw(ctx, img.tl, x, y, h) + draw(ctx, img.tr, x + h, y, h)
    + draw(ctx, img.bl, x, y + h, h) + draw(ctx, img.br, x + h, y + h, h);
}

// canvas の上で App を動かす。onFrame(情報) はコマごとに呼ばれる。止めるには返り値の stop() を呼ぶ
export function runApp(canvas, { init, view, tick, onFrame = () => {}, onQuit = () => {} }) {
  const ctx = canvas.getContext("2d");
  const W = canvas.width, H = canvas.height;
  let root = 1;
  while (root < Math.max(W, H)) root *= 2;
  let state = init;
  let pending = [];
  let running = true;
  let frames = 0;

  const scale = (e) => {
    const r = canvas.getBoundingClientRect();
    const x = Math.min(W - 1, Math.max(0, Math.floor(((e.clientX - r.left) * W) / r.width)));
    const y = Math.min(H - 1, Math.max(0, Math.floor(((e.clientY - r.top) * H) / r.height)));
    return [x, y];
  };
  const onKey = (down) => (e) => {
    if (e.repeat) return;
    const code = keyCode(e);
    if (code === null) return;
    e.preventDefault();
    pending.push({ $: "Key", code, down });
  };
  const onMouse = (down) => (e) => {
    const [x, y] = scale(e);
    pending.push({ $: "Mouse", x, y, button: e.button + 1, down });
  };
  const onMove = (e) => {
    const [x, y] = scale(e);
    pending.push({ $: "Move", x, y });
  };
  const keyDown = onKey(true), keyUp = onKey(false);
  const mouseDown = onMouse(true), mouseUp = onMouse(false);
  canvas.addEventListener("keydown", keyDown);
  canvas.addEventListener("keyup", keyUp);
  canvas.addEventListener("mousedown", mouseDown);
  canvas.addEventListener("mouseup", mouseUp);
  canvas.addEventListener("mousemove", onMove);

  function stop() {
    running = false;
    canvas.removeEventListener("keydown", keyDown);
    canvas.removeEventListener("keyup", keyUp);
    canvas.removeEventListener("mousedown", mouseDown);
    canvas.removeEventListener("mouseup", mouseUp);
    canvas.removeEventListener("mousemove", onMove);
  }

  function frame() {
    if (!running) return;
    const t0 = performance.now();
    const shown = view(state);
    ctx.clearRect(0, 0, W, H);
    const leaves = draw(ctx, shown.snd, 0, 0, root);
    const events = pending;
    pending = [];
    const next = tick(list(events), shown.fst)((v) => v);
    frames += 1;
    onFrame({ frames, leaves, events: events.length, ms: performance.now() - t0 });
    if (next.$ === "None") {
      stop();
      onQuit();
      return;
    }
    state = next.value;
    requestAnimationFrame(frame);
  }
  requestAnimationFrame(frame);
  return { stop };
}
