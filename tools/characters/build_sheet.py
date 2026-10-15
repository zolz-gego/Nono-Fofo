#!/usr/bin/env python3
"""Build design/character-sheet.html from the processed pose PNGs.

Run after process_poses.py:  tools/.venv/bin/python tools/characters/build_sheet.py
"""
import base64
import io
import os

from PIL import Image

from generate import POSE_ORDER, ROOT

PNG_DIR = os.path.join(ROOT, "app", "assets", "characters")
OUT = os.path.join(ROOT, "design", "character-sheet.html")
FONT = os.path.join(ROOT, "app", "assets", "fonts", "Avva_Shenouda.ttf")

POSES = {
    "idle": ("Idle", "مستني", "Waiting on any screen", "مستني على أي شاشة"),
    "cheer": ("Cheer", "برافو", "Correct answer", "إجابة صح"),
    "wrong": ("Oops", "أوبس", "Wrong answer", "إجابة غلط"),
    "hint": ("Hint", "تلميح", "Hint button", "زرار التلميح"),
    "celebrate": ("Celebrate", "احتفال", "Lesson done, 3 stars", "خلّص الدرس بـ٣ نجوم"),
    "encourage": ("You can do it", "تقدر!", "Try again after a mistake", "حاول تاني بعد غلطة"),
    "run": ("Run", "بيجري", "Screen changes, Ice Tower", "تنقّل بين الشاشات"),
    "wave": ("Hello", "أهلاً", "Welcome, pick your buddy", "الترحيب واختيار الصاحب"),
    "write": ("Write", "بيكتب", "Tracing a letter", "كتابة الحروف"),
    "read": ("Read", "بيقرا", "New letter, reading words", "حرف جديد وقراءة"),
    "sleep": ("Sleep", "نايم", "No touch for a while", "مفيش لعب لفترة"),
    "surprised": ("Surprised", "متفاجئ", "New letter found on the map", "حرف جديد على الخريطة"),
}

NOTES = {
    "nono": {
        "idle": "Mid-step, never still",
        "wrong": "Rushed it, scratches his head",
        "hint": "Points straight at the answer",
        "write": "Tongue out, giant pencil",
    },
    "fofo": {
        "idle": "Hands behind his back, curious",
        "wrong": "Stops and wonders why",
        "hint": "Gets the idea first",
        "write": "Slow, careful strokes",
    },
}


def img(name, pose, height, cls="", show_scale=None):
    """Inline a pose as a WebP data URI. show_scale fixes its on-page size (for the lineup)."""
    im = Image.open(os.path.join(PNG_DIR, name, f"{pose}.png"))
    w = round(im.width * height / im.height)
    buf = io.BytesIO()
    im.resize((w, height), Image.LANCZOS).save(buf, "WEBP", quality=86, method=6)
    uri = "data:image/webp;base64," + base64.b64encode(buf.getvalue()).decode()
    style = ""
    if show_scale:
        style = f' style="width:{round(im.width * show_scale)}px"'
    label = f"{name.capitalize()}, {POSES[pose][0].lower()} pose"
    return f'<img class="{cls}" src="{uri}" alt="{label}" width="{w}" height="{height}"{style}>'


def swatch(hexv, name, role):
    return (f'<li class="sw"><span class="chip" style="background:{hexv}"></span>'
            f'<span class="sw-name">{name}</span><span class="sw-hex">{hexv}</span>'
            f'<span class="sw-role">{role}</span></li>')



def pose_grid(name):
    cards = []
    for p in POSE_ORDER:
        en, ar, use_en, use_ar = POSES[p]
        note = NOTES[name].get(p)
        note_html = f'<span class="pc-note">{note}</span>' if note else ""
        cards.append(
            f'<figure class="pc">{img(name, p, 360)}<figcaption>'
            f'<span class="pc-name"><b>{en}</b><span lang="ar" dir="rtl">{ar}</span></span>'
            f'<span class="pc-use">{use_en} · <span lang="ar" dir="rtl">{use_ar}</span></span>{note_html}'
            f'</figcaption></figure>')
    return "".join(cards)


def main():
    font_b64 = base64.b64encode(open(FONT, "rb").read()).decode()
    page = TEMPLATE
    repl = {
        "{{FONT}}": font_b64,
        "{{NONO_IDLE}}": img("nono", "idle", 720, "bob-nono", 0.36),
        "{{FOFO_IDLE}}": img("fofo", "idle", 560, "bob-fofo", 0.36),
        "{{NONO_RUN}}": img("nono", "wave", 360),
        "{{FOFO_HINT}}": img("fofo", "hint", 360),
        "{{NONO_GRID}}": pose_grid("nono"),
        "{{FOFO_GRID}}": pose_grid("fofo"),
        "{{BRAND}}": "".join([
            swatch("#0F4C5C", "Deep Ocean Teal", "Nono's shirt, headings, dark surfaces"),
            swatch("#A8DADC", "Seafoam Blue", "Fofo's shirt, soft panels"),
            swatch("#EFE6D8", "Soft Sand Beige", "Page and app background"),
            swatch("#4F7C82", "Harbor Mist", "Fofo's shorts, secondary buttons"),
            swatch("#5B4B3A", "Driftwood Brown", "Nono's shorts, body text on sand"),
        ]),
        "{{ACCENTS}}": "".join([
            swatch("#FFC93C", "Sunny Yellow", "Stars, Nono's bolt, Fofo's sneakers"),
            swatch("#FF6B5B", "Coral Pop", "Nono's sneakers, wrong-answer feedback"),
            swatch("#6BCB77", "Leaf Green", "Fofo's pocket, right-answer feedback"),
        ]),
        "{{BODY}}": "".join([
            swatch("#F09A56", "Skin", "Warm Egyptian tan, both brothers"),
            swatch("#4A2B1A", "Nono's hair", "Dark-brown curls"),
            swatch("#8E4C24", "Fofo's hair", "Light-brown caramel curls"),
        ]),
    }
    for k, v in repl.items():
        page = page.replace(k, v)
    with open(OUT, "w") as fh:
        fh.write(page)
    print(f"wrote {OUT} ({len(page) // 1024} KB)")


TEMPLATE = r"""<title>Nono &amp; Fofo Character Sheet</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Baloo+Bhaijaan+2:wght@500;700;800&family=Rubik:wght@400;500;600&display=swap">
<style>
@font-face { font-family: "Avva Shenouda"; src: url(data:font/ttf;base64,{{FONT}}) format("truetype"); font-display: block; }
/* Layout: a model-sheet board — sand paper, a lineup on a ground line, then palette and pose library */
:root {
  --paper: #EFE6D8;
  --card: #FFFBF4;
  --ink: #12333B;
  --muted: #4F6A6E;
  --teal: #0F4C5C;
  --seafoam: #A8DADC;
  --rule: #D9CCB8;
  --yellow: #FFC93C;
  --coral: #E4574A;
  --stage: #F7F1E6;
  --display: "Baloo Bhaijaan 2", "Arial Rounded MT Bold", system-ui, sans-serif;
  --body: "Rubik", "Segoe UI", Tahoma, system-ui, sans-serif;
  --coptic: "Avva Shenouda", serif;
}
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) {
  --paper: #0B2A32; --card: #12404C; --ink: #F3EADB; --muted: #A9C4C6; --teal: #A8DADC;
  --seafoam: #2D6670; --rule: #23545F; --stage: #EFE6D8; --coral: #FF8A7A; color-scheme: dark; } }
:root[data-theme="dark"] {
  --paper: #0B2A32; --card: #12404C; --ink: #F3EADB; --muted: #A9C4C6; --teal: #A8DADC;
  --seafoam: #2D6670; --rule: #23545F; --stage: #EFE6D8; --coral: #FF8A7A; color-scheme: dark; }

* { box-sizing: border-box; }
body { background: var(--paper); color: var(--ink); font-family: var(--body); font-size: 16px; line-height: 1.55; }
.wrap { max-width: 1120px; margin: 0 auto; padding-inline: 20px; padding-block: 28px 64px; display: grid; gap: 56px; }
h1, h2, h3 { font-family: var(--display); line-height: 1.1; margin: 0; text-wrap: balance; }
h2 { font-size: clamp(26px, 3.4vw, 34px); color: var(--teal); }
.eyebrow { font: 600 12px/1 var(--body); letter-spacing: .14em; text-transform: uppercase; color: var(--muted); }
p { margin: 0; max-width: 65ch; }
[lang="ar"] { font-family: "Baloo Bhaijaan 2", var(--body); }

/* header */
header { display: grid; gap: 10px; }
.title { display: flex; flex-wrap: wrap; align-items: baseline; gap: 6px 22px; }
.title h1 { font-size: clamp(40px, 7vw, 72px); font-weight: 800; color: var(--teal); }
.title .ar { font-family: "Baloo Bhaijaan 2"; font-size: clamp(34px, 6vw, 60px); font-weight: 800; color: var(--coral); }
.coptic-name { font-family: var(--coptic); font-size: clamp(26px, 4vw, 38px); color: var(--muted); letter-spacing: .04em; }
header p { color: var(--muted); }

/* lineup */
.lineup { position: relative; background: var(--stage); border-radius: 28px; padding: 64px 12px 0; overflow: hidden;
  display: grid; grid-template-columns: 1fr auto 1fr; align-items: end; }
.lineup .fig { display: grid; justify-items: center; }
.lineup img { max-width: 100%; height: auto; display: block; }
.lineup .gap { width: clamp(8px, 6vw, 72px); }
.ground { grid-column: 1 / -1; height: 18px; background: #D9C7AA; margin-inline: -12px; }
.tag { position: absolute; top: 18px; font: 700 15px/1 var(--display); padding: 8px 12px; border-radius: 999px; }
.tag.nono { left: 18px; background: #0F4C5C; color: #FFC93C; }
.tag.fofo { right: 18px; background: #A8DADC; color: #0F4C5C; }
@media (prefers-reduced-motion: no-preference) {
  .bob-nono { animation: bounce .55s ease-in-out infinite alternate; transform-origin: 50% 100%; }
  .bob-fofo { animation: sway 2.6s ease-in-out infinite alternate; transform-origin: 50% 100%; }
}
@keyframes bounce { from { transform: translateY(0) scaleY(1); } to { transform: translateY(-10px) scaleY(1.02); } }
@keyframes sway { from { transform: rotate(-1.5deg); } to { transform: rotate(1.5deg); } }

/* profiles */
.profiles { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
.profile { background: var(--card); border-radius: 24px; padding: 22px; display: grid; grid-template-columns: 120px 1fr; gap: 18px; align-items: start; }
.profile .mini { background: var(--stage); border-radius: 18px; }
.profile .mini img { width: 100%; height: auto; aspect-ratio: 3 / 4; object-fit: contain; object-position: 50% 100%; padding: 8px; display: block; }
.profile h3 { font-size: 30px; display: flex; gap: 12px; align-items: baseline; flex-wrap: wrap; }
.profile h3 .ar { color: var(--coral); }
.profile.nono h3 .en { color: var(--teal); }
.facts { display: grid; grid-template-columns: auto 1fr; gap: 6px 14px; margin: 12px 0 0; font-size: 15px; }
.facts dt { color: var(--muted); font-weight: 500; }
.facts dd { margin: 0; min-width: 0; }
.traits { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 12px; padding: 0; list-style: none; }
.traits li { font-size: 13px; font-weight: 500; padding: 4px 10px; border-radius: 999px; background: var(--paper); }
@media (max-width: 460px) { .profile { grid-template-columns: 1fr; } .profile .mini { max-width: 160px; } }

/* palette */
.palette { display: grid; gap: 22px; }
.pal-group { display: grid; gap: 10px; }
.pal-group h3 { font: 600 13px/1 var(--body); letter-spacing: .12em; text-transform: uppercase; color: var(--muted); }
.sws { list-style: none; margin: 0; padding: 0; display: grid; grid-template-columns: repeat(auto-fill, minmax(190px, 1fr)); gap: 12px; }
.sw { background: var(--card); border-radius: 18px; padding: 10px 10px 14px; display: grid; gap: 2px; align-content: start; }
.chip { height: 64px; border-radius: 12px; margin-bottom: 8px; box-shadow: inset 0 0 0 1.5px rgba(0,0,0,.08); }
.sw-name { font-weight: 600; }
.sw-hex { font-family: ui-monospace, "SF Mono", Menlo, monospace; font-size: 13px; color: var(--muted); }
.sw-role { font-size: 13px; color: var(--muted); }

/* poses */
.poses { display: grid; gap: 18px; }
.switch { display: inline-flex; background: var(--card); border-radius: 999px; padding: 4px; gap: 4px; justify-self: start; }
.switch button { font: 700 16px/1 var(--display); border: 0; border-radius: 999px; padding: 10px 18px; cursor: pointer; background: transparent; color: var(--ink); }
.switch button[aria-pressed="true"] { background: var(--teal); color: var(--paper); }
.switch button:focus-visible { outline: 3px solid var(--yellow); outline-offset: 2px; }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(168px, 1fr)); gap: 14px; }
.pc { margin: 0; background: var(--card); border-radius: 20px; overflow: hidden; display: grid; grid-template-rows: auto 1fr; transition: transform .15s ease; }
.pc img { width: 100%; height: auto; aspect-ratio: 4 / 5; object-fit: contain; object-position: 50% 100%; padding: 12px 10px 8px; display: block; background: var(--stage); }
.pc:hover { transform: translateY(-3px); }
.pc figcaption { padding: 10px 12px 14px; display: grid; gap: 4px; align-content: start; }
.pc-name { display: flex; justify-content: space-between; gap: 8px; font-size: 16px; }
.pc-name [lang="ar"] { color: var(--coral); font-weight: 700; }
.pc-use { font-size: 12.5px; color: var(--muted); line-height: 1.4; }
.pc-note { font-size: 12.5px; font-weight: 500; color: var(--teal); }

footer { color: var(--muted); font-size: 14px; display: grid; gap: 6px; }
code { font-family: ui-monospace, "SF Mono", Menlo, monospace; font-size: 13px; background: var(--card); padding: 2px 6px; border-radius: 6px; }
</style>

<div class="wrap">
  <header>
    <span class="eyebrow">Character sheet · draft 2</span>
    <div class="title"><h1>Nono &amp; Fofo</h1><span class="ar" lang="ar" dir="rtl">نونو وفوفو</span></div>
    <span class="coptic-name" title="Nono nem Fofo, written in the Avva Shenouda Coptic font">nono nem fofo</span>
    <p>Two Coptic Egyptian brothers who guide kids through the Coptic letters. Nono rushes in, Fofo thinks it through, and together they show that slowing down helps and mistakes are fine.</p>
  </header>

  <section class="lineup" aria-label="Height lineup">
    <span class="tag nono">Nono · 9</span><span class="tag fofo">Fofo · 6</span>
    <div class="fig">{{NONO_IDLE}}</div>
    <div class="gap" aria-hidden="true"></div>
    <div class="fig">{{FOFO_IDLE}}</div>
    <div class="ground"></div>
  </section>

  <section class="profiles">
    <article class="profile nono">
      <div class="mini">{{NONO_RUN}}</div>
      <div>
        <h3><span class="en">Nono</span><span class="ar" lang="ar" dir="rtl">نونو</span></h3>
        <dl class="facts">
          <dt>Full name</dt><dd>Nolan · <span lang="ar" dir="rtl">نولان</span></dd>
          <dt>Age</dt><dd>9, the big brother</dd>
          <dt>Look</dt><dd>Tall and slim, big dark-brown curls, wide grin</dd>
          <dt>Wears</dt><dd>Teal tee with a yellow bolt, brown shorts, coral sneakers</dd>
          <dt>Sounds</dt><dd>“Woohoo!”, fast footsteps, a quick “oops”</dd>
        </dl>
        <ul class="traits"><li>Energetic</li><li lang="ar">مندفع</li><li>Always running</li><li>Answers first</li><li>Funny mistakes</li></ul>
      </div>
    </article>
    <article class="profile fofo">
      <div class="mini">{{FOFO_HINT}}</div>
      <div>
        <h3><span class="en">Fofo</span><span class="ar" lang="ar" dir="rtl">فوفو</span></h3>
        <dl class="facts">
          <dt>Full name</dt><dd>Rafy · <span lang="ar" dir="rtl">رافي</span></dd>
          <dt>Age</dt><dd>6, the little brother</dd>
          <dt>Look</dt><dd>Smaller and slim, light-brown caramel curls, a missing front tooth</dd>
          <dt>Wears</dt><dd>Seafoam tee with a green pocket, blue-grey shorts, yellow sneakers</dd>
          <dt>Sounds</dt><dd>“Hmm…”, a soft giggle, a “ding!” for ideas</dd>
        </dl>
        <ul class="traits"><li>Calm</li><li>Thinks first</li><li>Notices details</li><li>Has the ideas</li><li>Kind helper</li></ul>
      </div>
    </article>
  </section>

  <section class="palette" aria-labelledby="pal-h">
    <div><span class="eyebrow">Color sheet</span><h2 id="pal-h">Colors</h2></div>
    <div class="pal-group"><h3>Brand palette</h3><ul class="sws">{{BRAND}}</ul></div>
    <div class="pal-group"><h3>Playful accents</h3><ul class="sws">{{ACCENTS}}</ul></div>
    <div class="pal-group"><h3>Skin, hair and lines</h3><ul class="sws">{{BODY}}</ul></div>
  </section>

  <section class="poses" aria-labelledby="poses-h">
    <div><span class="eyebrow">Pose library · 12 each</span><h2 id="poses-h">Poses and when they appear</h2></div>
    <div class="switch" role="group" aria-label="Show poses for">
      <button id="btn-nono" aria-pressed="true" data-who="nono">Nono</button>
      <button id="btn-fofo" aria-pressed="false" data-who="fofo">Fofo</button>
    </div>
    <div class="grid" id="grid-nono">{{NONO_GRID}}</div>
    <div class="grid" id="grid-fofo" hidden>{{FOFO_GRID}}</div>
  </section>

  <footer>
    <span>Art made in Gemini from the approved reference. Each pose is a transparent PNG in <code>assets/characters/&lt;name&gt;/&lt;pose&gt;.png</code>, made by <code>tools/characters/process_poses.py</code>.</span>
    <span>Fofo is drawn at 75% of Nono's height in every pose, so both can share one screen.</span>
  </footer>
</div>

<script>
(function () {
  var btns = document.querySelectorAll('.switch button');
  function show(who) {
    btns.forEach(function (b) { b.setAttribute('aria-pressed', String(b.dataset.who === who)); });
    document.getElementById('grid-nono').hidden = who !== 'nono';
    document.getElementById('grid-fofo').hidden = who !== 'fofo';
    try { localStorage.setItem('nf-who', who); } catch (e) {}
  }
  btns.forEach(function (b) { b.addEventListener('click', function () { show(b.dataset.who); }); });
  try { var saved = localStorage.getItem('nf-who'); if (saved === 'fofo') show('fofo'); } catch (e) {}
})();
</script>
"""

if __name__ == "__main__":
    main()
