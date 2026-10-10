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
