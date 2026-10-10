# Passo 7: gera o app instalável (PWA) na pasta docs/, publicada pelo GitHub Pages.
# Usa só a base com nomes fictícios (data.js); o pacote com nomes reais não vai para o site.
#   docs/index.html, docs/data.js, docs/manifest.webmanifest, docs/sw.js (+ ícones gerados por tools/icones.ps1)
use strict; use warnings; use FindBin; use POSIX qw(strftime);
my $root = "$FindBin::Bin/..";
sub slurp { open my $h, '<:raw', $_[0] or die "$_[0]: $!"; local $/; my $s = <$h>; $s }
sub put { open my $h, '>:raw', $_[0] or die "$_[0]: $!"; print $h $_[1]; close $h; printf "%s: %.0f KB\n", $_[0] =~ s/.*\///r, length($_[1]) / 1024 }
my $ver = strftime('%Y%m%d%H%M', localtime);

my $html = slurp("$root/index.html");
$html =~ s{<script src="data_real\.js"></script>\n}{} or die 'tag data_real.js não encontrada';
$html =~ s{(<meta name="viewport"[^>]*>)}{$1
<meta name="theme-color" content="#1f8a4c">
<meta name="description" content="Jogo de técnico de futebol no estilo Brasfoot.">
<link rel="manifest" href="manifest.webmanifest">
<link rel="icon" type="image/png" href="icon-192.png">
<link rel="apple-touch-icon" href="icon-192.png">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-title" content="WiFoot">} or die 'viewport não encontrado';
$html =~ s{</body>}{<script>if ('serviceWorker' in navigator) addEventListener('load', () => navigator.serviceWorker.register('sw.js').catch(() => {}));</script>
</body>} or die '</body> não encontrado';
put("$root/docs/index.html", $html);
put("$root/docs/data.js", slurp("$root/data.js"));
put("$root/docs/manifest.webmanifest", <<'JSON');
{
  "name": "WiFoot Manager",
  "short_name": "WiFoot",
  "description": "Jogo de técnico de futebol no estilo Brasfoot.",
  "lang": "pt-BR",
  "start_url": "./",
  "scope": "./",
  "display": "standalone",
  "orientation": "any",
  "background_color": "#e4f1e7",
  "theme_color": "#1f8a4c",
  "icons": [
    {"src": "icon-192.png", "sizes": "192x192", "type": "image/png"},
    {"src": "icon-512.png", "sizes": "512x512", "type": "image/png"},
    {"src": "icon-maskable-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable"}
  ]
}
JSON
# Service worker: guarda o jogo para abrir sem internet; uma versão nova substitui o cache antigo
put("$root/docs/sw.js", <<"JS");
const CACHE = 'wifoot-$ver';
const FILES = ['./', 'index.html', 'data.js', 'manifest.webmanifest', 'icon-192.png', 'icon-512.png', 'icon-maskable-512.png'];
self.addEventListener('install', e => { e.waitUntil(caches.open(CACHE).then(c => c.addAll(FILES))); self.skipWaiting(); });
self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k)))));
  self.clients.claim();
});
// Rede primeiro (pega atualizações); sem internet, usa o que está guardado
self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  e.respondWith(fetch(e.request).then(r => {
    if (r.ok && new URL(e.request.url).origin === location.origin) { const copy = r.clone(); caches.open(CACHE).then(c => c.put(e.request, copy)); }
    return r;
  }).catch(() => caches.match(e.request).then(r => r || caches.match('index.html'))));
});
JS
