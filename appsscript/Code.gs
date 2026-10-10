// WiFoot Manager como app da Web do Google Apps Script.
// O jogo (Index.html) e os dados (Dados.html) são gerados por tools/06_appsscript.pl.
function doGet() {
  return HtmlService.createTemplateFromFile('Index').evaluate()
    .setTitle('WiFoot Manager')
    .setFaviconUrl('https://junin12.github.io/WiFoot-Manager/icon-192.png') // ícone do app (publicado no GitHub Pages)
    .addMetaTag('viewport', 'width=device-width, initial-scale=1');
}

// Insere o conteúdo de outro arquivo HTML do projeto (usado para os dados)
function include(name) {
  return HtmlService.createHtmlOutputFromFile(name).getContent();
}

// ---------- Nuvem: jogos salvos no Google Drive do dono do app ----------
// O app roda com a conta do dono; para ninguém mais gravar no Drive dele, só o próprio dono (conectado) usa a nuvem.
var PASTA = 'WiFoot Manager - jogos salvos';
function dono_() {
  var quem = Session.getActiveUser().getEmail(), dono = Session.getEffectiveUser().getEmail();
  if (!quem || quem !== dono) throw new Error('A nuvem só funciona para o dono do app, conectado à própria conta Google.');
}
function pasta_() {
  var it = DriveApp.getFoldersByName(PASTA);
  return it.hasNext() ? it.next() : DriveApp.createFolder(PASTA);
}
function arquivo_(n) {
  n = Number(n);
  if ([1, 2, 3].indexOf(n) < 0) throw new Error('Espaço inválido.');
  var it = pasta_().getFilesByName('espaco-' + n + '.wifoot');
  return it.hasNext() ? it.next() : null;
}
// dados: jogo compactado (gzip em base64); meta: nome, ano e modo, para a lista
function cloudSave(n, dados, meta) {
  dono_();
  if (typeof dados !== 'string' || dados.length > 40e6) throw new Error('Arquivo de jogo inválido.');
  var f = arquivo_(n);
  if (f) f.setContent(dados); else f = pasta_().createFile('espaco-' + Number(n) + '.wifoot', dados, 'text/plain');
  f.setDescription(String(meta || '').slice(0, 500));
  return 'Jogo salvo na nuvem (Espaço ' + Number(n) + ').';
}
function cloudLoad(n) {
  dono_();
  var f = arquivo_(n);
  if (!f) throw new Error('Nada salvo neste espaço da nuvem.');
  return f.getBlob().getDataAsString();
}
function cloudList() {
  dono_();
  return [1, 2, 3].map(function (n) {
    var f = arquivo_(n), meta = null;
    if (!f) return {n: n};
    try { meta = JSON.parse(f.getDescription() || 'null'); } catch (e) {}
    return {n: n, meta: meta || {name: 'Jogo salvo', year: ''}, date: f.getLastUpdated().toISOString()};
  });
}
