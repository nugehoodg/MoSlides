import 'dart:convert';

/// Generates self-contained HTML for MARP-style slide preview and PDF export.
/// JavaScript markdown parsing is done entirely inline (no CDN required).
class MarpService {
  // ─── Public API ────────────────────────────────────────────────────────────

  static String generateHtml(String markdown, String theme, {String size = '1360x768', String fontSize = 'Medium'}) {
    final sizeArr = _parseSize(size);
    final fontScale = _parseFontScale(fontSize);
    final jsonMd = jsonEncode(markdown);
    final css = _previewCss(theme, sizeArr[0], sizeArr[1], fontScale);
    return [
      '<!DOCTYPE html><html lang="en">',
      '<head><meta charset="UTF-8">',
      '<meta name="viewport" content="width=device-width,initial-scale=1.0">',
      '<style>',
      css,
      '</style></head>',
      '<body><div id="wrapper"><div id="slides"></div></div>',
      '<div id="nav">',
      '  <button id="p" onclick="go(cur-1)">&#9664;</button>',
      '  <span id="c">1 / 1</span>',
      '  <button id="n" onclick="go(cur+1)">&#9654;</button>',
      '</div>',
      '<script>',
      'const MD = $jsonMd;',
      'const SW = ${sizeArr[0]};',
      'const SH = ${sizeArr[1]};',
      _previewJs,
      '</script></body></html>',
    ].join('\n');
  }

  static String generatePdfHtml(String staticSlidesHtml, String theme, {String size = '1360x768', String fontSize = 'Medium'}) {
    final sizeArr = _parseSize(size);
    final fontScale = _parseFontScale(fontSize);
    final css = _pdfCss(theme, sizeArr[0], sizeArr[1], fontScale);
    return [
      '<!DOCTYPE html><html lang="en">',
      '<head><meta charset="UTF-8">',
      '<meta name="viewport" content="width=device-width,initial-scale=1.0">',
      '<style>',
      css,
      '</style></head>',
      '<body>',
      '<div id="pdf-root">',
      staticSlidesHtml,
      '</div>',
      '</body></html>',
    ].join('\n');
  }

  static List<int> _parseSize(String sizeStr) {
    final parts = sizeStr.split('x');
    if (parts.length == 2) {
      return [int.tryParse(parts[0]) ?? 1360, int.tryParse(parts[1]) ?? 768];
    }
    return [1360, 768];
  }

  static double _parseFontScale(String fontSize) {
    switch (fontSize) {
      case 'Small': return 0.85;
      case 'Large': return 1.20;
      case 'Extra Large': return 1.50;
      case 'Medium':
      default: return 1.0;
    }
  }

  static const String defaultMarkdown = '''---
marp: true
theme: uncover
---

::: center
# Welcome to MoSlides ✨
*Your next-generation editorial slide tool*
:::

> Drag and drop to re-order this slide deck and get started!

---

::: center
# Stunning Layouts
Create beautiful presentations using **Markdown**
:::

- Separate your slides effortlessly with `---`
- Emphasize with **bold**, *italic*, and `code`
- Pick a stunning theme from the toolbar above
- Wrap your content with `::: center` ... `:::` for alignments!

---

# Focus on Content

> Stop dragging shapes. Start typing ideas.

```javascript
function makeImpact() {
  const thoughts = ignite();
  return MoSlides.present(thoughts);
}
```

---

# Fully Featured

## What's Inside?
1. Live Markdown preview
2. MARP-compatible themes
3. **High Fidelity PDF Export** (Preserves Colors!)
4. **Drag & Drop** Reordering
5. Auto-saving pipeline

---

::: center
# Thank You! 🎉

*Export this deck to PDF and see the magic*
[Visit MoSlides](https://example.com)
:::
''';

  // ─── JavaScript (raw strings – no Dart escape issues) ─────────────────────

  /// Interactive preview JS: parses markdown, navigates slides.
  static const String _previewJs = r'''
let cur = 0, allSlides = [];

function esc(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function parseSlide(text) {
  const codeBlocks = [];
  const inlineCodes = [];

  // 1. Protect fenced code blocks
  let s = text.replace(/```(\w*)\n([\s\S]*?)```/gm, function(_, lang, code) {
    const i = codeBlocks.length;
    codeBlocks.push('<pre><code class="lang-' + (lang||'text') + '">' + esc(code) + '</code></pre>');
    return '\x01CB' + i + '\x01';
  });

  // 2. Protect inline code
  s = s.replace(/`([^`]+)`/g, function(_, code) {
    const i = inlineCodes.length;
    inlineCodes.push('<code>' + esc(code) + '</code>');
    return '\x01IC' + i + '\x01';
  });

  // 3. Line-by-line processing
  const lines = s.split('\n');
  const out = [];
  let inUl = false, inOl = false;

  function closeList() {
    if (inUl) { out.push('</ul>'); inUl = false; }
    if (inOl) { out.push('</ol>'); inOl = false; }
  }

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    let m;

    if (/^\x01CB\d+\x01$/.test(line.trim())) {
      closeList();
      out.push(line.trim());
    } else if ((m = line.match(/^:::\s*(left|center|right|justify)/))) {
      closeList();
      out.push('<div style="text-align: ' + m[1] + ';">');
    } else if (line.trim() === ':::') {
      closeList();
      out.push('</div>');
    } else if ((m = line.match(/^(#{1,6})\s+(.*)/))) {
      closeList();
      const lv = m[1].length;
      out.push('<h' + lv + '>' + applyInline(m[2]) + '</h' + lv + '>');
    } else if ((m = line.match(/^[-*+]\s+(.*)/))) {
      if (inOl) { out.push('</ol>'); inOl = false; }
      if (!inUl) { out.push('<ul>'); inUl = true; }
      out.push('<li>' + applyInline(m[1]) + '</li>');
    } else if ((m = line.match(/^\d+\.\s+(.*)/))) {
      if (inUl) { out.push('</ul>'); inUl = false; }
      if (!inOl) { out.push('<ol>'); inOl = true; }
      out.push('<li>' + applyInline(m[1]) + '</li>');
    } else if ((m = line.match(/^>\s*(.*)/))) {
      closeList();
      out.push('<blockquote>' + applyInline(m[1]) + '</blockquote>');
    } else if (line.trim() === '') {
      closeList();
    } else {
      closeList();
      out.push('<p>' + applyInline(line) + '</p>');
    }
  }
  closeList();

  let html = out.join('\n');
  html = html.replace(/\x01IC(\d+)\x01/g, function(_, i) { return inlineCodes[+i]; });
  html = html.replace(/\x01CB(\d+)\x01/g, function(_, i) { return codeBlocks[+i]; });
  return html;
}

function applyInline(text) {
  text = text.replace(/!\[([^\]]*)\]\(([^)]+)\)/g,
    '<img src="$2" alt="$1" style="max-width:100%;max-height:45vh;object-fit:contain;border-radius:8px;">');
  text = text.replace(/\[([^\]]+)\]\(([^)]+)\)/g,
    '<a href="$2" style="color:inherit;text-decoration:underline;" target="_blank">$1</a>');
  text = text.replace(/\*\*\*(.+?)\*\*\*/g, '<strong><em>$1</em></strong>');
  text = text.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>');
  text = text.replace(/\*(.+?)\*/g, '<em>$1</em>');
  text = text.replace(/__(.+?)__/g, '<strong>$1</strong>');
  text = text.replace(/_(.+?)_/g, '<em>$1</em>');
  text = text.replace(/~~(.+?)~~/g, '<del>$1</del>');
  text = text.replace(/\x01IC(\d+)\x01/g, function(_, i) { return '<code>' + i + '</code>'; });
  return text;
}

function stripFrontMatter(md) {
  md = md.trim();
  if (!md.startsWith('---')) return md;
  const idx = md.indexOf('\n---', 3);
  if (idx < 0) return md;
  let rest = md.slice(idx + 4);
  if (rest.startsWith('\n')) rest = rest.slice(1);
  return rest.trim();
}

function init() {
  const body = stripFrontMatter(MD);
  const raw = body.split(/\n---\n|\n---$/m);
  allSlides = raw.filter(function(s) { return s.trim().length > 0; });
  if (allSlides.length === 0) allSlides = ['# No slides\n\nStart editing to add content.'];

  const container = document.getElementById('slides');
  container.innerHTML = '';
  allSlides.forEach(function(text, i) {
    const div = document.createElement('div');
    div.className = 'slide';
    div.innerHTML = parseSlide(text.trim());
    container.appendChild(div);
  });
  go(0);
}

function go(n) {
  cur = Math.max(0, Math.min(n, allSlides.length - 1));
  document.querySelectorAll('.slide').forEach(function(s, i) {
    s.style.display = i === cur ? 'flex' : 'none';
  });
  document.getElementById('c').textContent = (cur + 1) + ' / ' + allSlides.length;
  document.getElementById('p').disabled = cur === 0;
  document.getElementById('n').disabled = cur === allSlides.length - 1;
}

function resizeSlides() {
  const wrap = document.getElementById('wrapper');
  if (!wrap) return;
  // Calculate scale factor relative to container
  const scale = Math.min(wrap.clientWidth / SW, wrap.clientHeight / SH) * 0.98; // 0.98 for safe padding
  document.querySelectorAll('.slide').forEach(function(s) {
    s.style.transform = 'translate(-50%, -50%) scale(' + scale + ')';
  });
}

window.addEventListener('resize', resizeSlides);

document.addEventListener('keydown', function(e) {
  if (e.key === 'ArrowRight' || e.key === ' ') go(cur + 1);
  if (e.key === 'ArrowLeft') go(cur - 1);
});

var tx = 0;
document.addEventListener('touchstart', function(e) { tx = e.touches[0].clientX; }, {passive: true});
document.addEventListener('touchend', function(e) {
  var dx = tx - e.changedTouches[0].clientX;
  if (Math.abs(dx) > 50) go(dx > 0 ? cur + 1 : cur - 1);
}, {passive: true});

document.addEventListener('DOMContentLoaded', function() { init(); resizeSlides(); });
if (document.readyState !== 'loading') { init(); resizeSlides(); }
''';



  // ─── CSS (theme-aware) ──────────────────────────────────────────────────────

  static String _baseCss(int w, int h, double fs) => '''
:root { --fs: $fs; }
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
html, body { width: 100%; height: 100%; overflow: hidden; background: #000; }
#wrapper { width: 100vw; height: calc(100vh - 56px); overflow: hidden; display: flex; align-items: center; justify-content: center; }
#slides { width: 100%; height: 100%; position: relative; }
.slide {
  position: absolute; left: 50%; top: 50%;
  width: ${w}px; height: ${h}px;
  transform: translate(-50%, -50%);
  transform-origin: center;
  display: flex; flex-direction: column; justify-content: center;
  padding: ${h * 0.08}px ${w * 0.08}px; overflow: hidden;
}
.slide h1 { font-size: calc(clamp(1.8rem,4.5vw,3.2rem) * var(--fs)); font-weight: 800; margin-bottom: 0.5em; line-height: 1.15; }
.slide h2 { font-size: calc(clamp(1.4rem,3.5vw,2.4rem) * var(--fs)); font-weight: 700; margin-bottom: 0.45em; }
.slide h3 { font-size: calc(clamp(1.1rem,2.5vw,1.8rem) * var(--fs)); font-weight: 600; margin-bottom: 0.4em; }
.slide p  { font-size: calc(clamp(0.9rem,2vw,1.25rem) * var(--fs)); line-height: 1.75; margin-bottom: 0.6em; }
.slide ul, .slide ol { font-size: calc(clamp(0.9rem,2vw,1.25rem) * var(--fs)); padding-left: 1.6em; margin-bottom: 0.6em; }
.slide li { line-height: 1.7; margin-bottom: 0.3em; }
.slide blockquote { border-left: 4px solid; padding: 8px 20px; margin: 0.6em 0; font-style: italic; border-radius: 0 8px 8px 0; }
.slide code { font-family: 'Courier New', Courier, monospace; padding: 2px 6px; border-radius: 4px; font-size: 0.88em; }
.slide pre { padding: 18px 22px; border-radius: 10px; overflow-x: auto; margin-bottom: 0.6em; }
.slide pre code { padding: 0; background: none !important; font-size: calc(clamp(0.7rem,1.4vw,0.95rem) * var(--fs)); }
.slide img { max-width: 100%; max-height: 50vh; object-fit: contain; border-radius: 8px; display: block; margin: 8px auto; }
.slide strong { font-weight: 700; }
.slide em { font-style: italic; }
.slide del { text-decoration: line-through; opacity: 0.7; }
.slide a { text-decoration: underline; }
.slide table { border-collapse: collapse; width: 100%; margin-bottom: 0.6em; font-size: calc(0.9em * var(--fs)); }
.slide th, .slide td { padding: 8px 14px; text-align: left; }
#nav { position: fixed; bottom: 0; left: 0; right: 0; height: 56px; display: flex; align-items: center; justify-content: center; gap: 20px; z-index: 100; }
#nav button { border: none; border-radius: 50%; width: 38px; height: 38px; font-size: 16px; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: opacity 0.2s, transform 0.1s; }
#nav button:disabled { opacity: 0.3; cursor: default; }
#nav button:not(:disabled):hover { transform: scale(1.1); }
#c { font-size: 13px; font-weight: 600; min-width: 64px; text-align: center; letter-spacing: 0.5px; }
''';

  static String _previewCss(String theme, int w, int h, double fs) {
    switch (theme) {
      case 'gaia':
        return _baseCss(w, h, fs) + '''
body { background: #1e1b4b; font-family: 'Segoe UI', sans-serif; }
.slide { background: #1e1b4b; color: #e0e7ff; }
.slide h1 { color: #a5b4fc; }
.slide h2 { color: #c7d2fe; }
.slide h3 { color: #ddd6fe; }
.slide code { background: rgba(165,180,252,0.15); color: #c7d2fe; }
.slide pre { background: rgba(0,0,0,0.35); color: #e0e7ff; border-left: 3px solid #6366f1; }
.slide blockquote { border-color: #a5b4fc; background: rgba(165,180,252,0.1); color: #c7d2fe; }
.slide th { background: rgba(165,180,252,0.2); border-color: rgba(165,180,252,0.25); color: #e0e7ff; }
.slide td { border-color: rgba(165,180,252,0.15); color: #d4d7f5; }
.slide a { color: #818cf8; }
#nav { background: rgba(15,10,50,0.85); backdrop-filter: blur(12px); border-top: 1px solid rgba(99,102,241,0.25); }
#nav button { background: #4f46e5; color: white; }
#c { color: #a5b4fc; }
''';
      case 'uncover':
        return _baseCss(w, h, fs) + '''
body { background: #0f172a; font-family: 'Segoe UI', sans-serif; }
.slide { background: #0f172a; color: #f8fafc; justify-content: flex-end; padding: 72px 96px; }
.slide h1 { color: #f8fafc; font-size: clamp(2rem,5.5vw,4rem); font-weight: 900; padding-bottom: 14px; border-bottom: 3px solid #38bdf8; margin-bottom: 0.5em; }
.slide h2 { color: #7dd3fc; }
.slide h3 { color: #93c5fd; }
.slide p  { color: #cbd5e1; }
.slide li { color: #cbd5e1; }
.slide code { background: rgba(56,189,248,0.12); color: #38bdf8; }
.slide pre { background: rgba(0,0,0,0.5); color: #e2e8f0; border-left: 3px solid #38bdf8; }
.slide blockquote { border-color: #38bdf8; background: rgba(56,189,248,0.07); color: #94a3b8; }
.slide th { background: rgba(56,189,248,0.18); border-color: rgba(56,189,248,0.3); color: #f8fafc; }
.slide td { border-color: rgba(56,189,248,0.18); color: #cbd5e1; }
.slide a { color: #38bdf8; }
#nav { background: rgba(15,23,42,0.9); backdrop-filter: blur(12px); border-top: 1px solid rgba(56,189,248,0.2); }
#nav button { background: #0ea5e9; color: white; }
#c { color: #7dd3fc; }
''';
      default: // 'default'
        return _baseCss(w, h, fs) + '''
body { background: #f0f4f8; font-family: 'Segoe UI', sans-serif; }
.slide { background: #ffffff; color: #1e293b; box-shadow: 0 4px 32px rgba(0,0,0,0.1); border-radius: 4px; }
.slide h1 { color: #1d4ed8; }
.slide h2 { color: #2563eb; }
.slide h3 { color: #3b82f6; }
.slide code { background: #eff6ff; color: #1d4ed8; }
.slide pre { background: #1e293b; color: #e2e8f0; }
.slide blockquote { border-color: #3b82f6; background: #eff6ff; color: #475569; }
.slide th { background: #dbeafe; border-color: #bfdbfe; color: #1e3a8a; }
.slide td { border-color: #e2e8f0; color: #334155; }
.slide a { color: #2563eb; }
#nav { background: rgba(255,255,255,0.92); backdrop-filter: blur(12px); border-top: 1px solid #e2e8f0; box-shadow: 0 -4px 16px rgba(0,0,0,0.07); }
#nav button { background: #2563eb; color: white; }
#c { color: #475569; }
''';
    }
  }

  static String _pdfCss(String theme, int w, int h, double fs) {
    final base = '''
:root { --fs: $fs; }
@page { size: ${w}px ${h}px; margin: 0; }
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: 'Segoe UI', sans-serif; -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; }
#pdf-root {}
.slide {
  width: ${w}px; height: ${h}px;
  display: flex; flex-direction: column; justify-content: center;
  padding: ${h * 0.08}px ${w * 0.08}px; page-break-after: always; overflow: hidden;
  -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important;
}
.slide h1 { font-size: calc(2.8rem * var(--fs)); font-weight: 800; margin-bottom: 0.5em; line-height: 1.2; }
.slide h2 { font-size: calc(2.2rem * var(--fs)); font-weight: 700; margin-bottom: 0.45em; }
.slide h3 { font-size: calc(1.7rem * var(--fs)); font-weight: 600; margin-bottom: 0.4em; }
.slide p  { font-size: calc(1.2rem * var(--fs)); line-height: 1.7; margin-bottom: 0.5em; }
.slide ul, .slide ol { font-size: calc(1.2rem * var(--fs)); padding-left: 1.6em; margin-bottom: 0.5em; }
.slide li { line-height: 1.7; margin-bottom: 0.3em; }
.slide blockquote { border-left: 4px solid; padding: 8px 20px; margin: 0.5em 0; font-style: italic; }
.slide code { font-family: monospace; padding: 2px 6px; border-radius: 4px; font-size: 0.88em; }
.slide pre { padding: 16px 20px; border-radius: 8px; margin-bottom: 0.5em; }
.slide pre code { padding: 0; background: none !important; font-size: calc(0.9rem * var(--fs)); }
.slide img { max-width: 100%; max-height: 35vh; object-fit: contain; display: block; margin: 8px auto; }
.slide strong { font-weight: 700; }
.slide em { font-style: italic; }
.slide table { border-collapse: collapse; width: 100%; margin-bottom: 0.5em; font-size: calc(0.9rem * var(--fs)); }
.slide th, .slide td { padding: 8px 12px; text-align: left; }
''';
    switch (theme) {
      case 'gaia':
        return base + '''
.slide { background: #1e1b4b; color: #e0e7ff; }
.slide h1, .slide h2, .slide h3 { color: #a5b4fc; }
.slide code { background: rgba(165,180,252,0.15); color: #c7d2fe; }
.slide pre { background: #0c0a2e; color: #e0e7ff; }
.slide blockquote { border-color: #a5b4fc; background: rgba(165,180,252,0.1); }
.slide th { background: rgba(165,180,252,0.2); border-color: rgba(165,180,252,0.3); }
.slide td { border-color: rgba(165,180,252,0.15); }
''';
      case 'uncover':
        return base + '''
.slide { background: #0f172a; color: #f8fafc; justify-content: flex-end; }
.slide h1 { color: #f8fafc; border-bottom: 3px solid #38bdf8; padding-bottom: 12px; }
.slide h2 { color: #7dd3fc; }
.slide p, .slide li { color: #cbd5e1; }
.slide code { background: rgba(56,189,248,0.12); color: #38bdf8; }
.slide pre { background: rgba(0,0,0,0.5); color: #e2e8f0; }
.slide th { background: rgba(56,189,248,0.18); border-color: rgba(56,189,248,0.3); }
''';
      default:
        return base + '''
.slide { background: #ffffff; color: #1e293b; }
.slide h1 { color: #1d4ed8; }
.slide h2 { color: #2563eb; }
.slide code { background: #eff6ff; color: #1d4ed8; }
.slide pre { background: #1e293b; color: #e2e8f0; }
.slide blockquote { border-color: #3b82f6; background: #eff6ff; }
.slide th { background: #dbeafe; border-color: #bfdbfe; }
.slide td { border-color: #e2e8f0; }
''';
    }
  }
}
