# WiFoot Manager

Jogo de técnico de futebol no estilo Brasfoot, feito em HTML, CSS e JavaScript puro, sem instalação nem build.

## Como jogar

Abra o `index.html` no navegador (dois cliques). O progresso é salvo automaticamente no navegador (IndexedDB); também dá para exportar e importar o jogo salvo pela aba **Jogo**.

## Modos de jogo

- **Treinador:** comande um clube. Opção **Virar SAF?**: a cada início de temporada, investidores podem aportar até 15x o valor do clube.
- **Modo Carreira:** você é um jogador que começa na base aos 17 anos, recebe propostas de outros clubes e constrói a carreira até se aposentar. O dinheiro vai para investimentos, imóveis (aluguel toda semana), uma escolinha de futebol que revela e vende jovens, treino particular (com limites) ou a compra de clubes, onde você vira presidente e pode aportar dinheiro. Ao se aposentar, o mesmo personagem pode seguir como treinador no mesmo mundo, levando o patrimônio e os clubes.
- **Prêmios e troféus:** no fim de cada temporada saem o melhor jogador, a revelação, o artilheiro e o goleiro menos vazado de cada liga e do mundo, além do técnico do ano. A aba Troféus guarda tudo o que você conquistou pelo clube e individualmente, além de 16 conquistas permanentes.
- **Para jogar sem se perder:** três metas por temporada com prêmio, resumo da rodada em uma linha, dicas do auxiliar, gráfico da posição na liga (e da força e do patrimônio no Modo Carreira) e três espaços de jogo salvo.
- **Emoção:** clássicos contra o rival da cidade (moral e torcida em dobro), momentos decisivos no jogo ao vivo (pênaltis, faltas e reta final) e palestra no intervalo.
- **Modo Carreira:** convocação para a seleção, Mundial de Seleções a cada 4 anos, camisa 10 e braçadeira de capitão, e um rival pessoal (mesma posição e idade) comparado temporada a temporada.
- **Simular até... (⏩):** avança até o próximo jogo importante, a próxima janela de transferências ou o fim da temporada, parando quando algo pede decisão.
- **Treinador:** olheiros revelam o potencial escondido dos jogadores de outros clubes, e a torcida reage aos resultados e ao preço do ingresso.
- **Hall da Fama:** quem passa muitos anos num clube vira ídolo e entra na história dele.
- **Mundo que muda:** a cada ano surgem fenômenos nas bases e as lendas se despedem; clubes mal geridos entram em crise (vendem craques e podem perder pontos) e outros ganham donos bilionários ou ampliam o estádio.
- **Recordes:** maior goleada, mais gols numa temporada, maior artilheiro da história do jogo, maior transferência e mais pontos numa liga (aba Histórico e recordes).
- **Tema claro e escuro:** botão no topo (automático, claro ou escuro) e opção na aba Jogo.
- **Partidas:** motor calibrado com médias reais (≈2,6 gols por jogo, goleadas raras), notas de 0 a 10 com melhor em campo, seleção da rodada, Time do Ano da liga e do mundo, instruções táticas (pressão alta, toque de bola, contra-ataque, bola longa), árbitro de vídeo e modo de partida rápida (só os lances decisivos).
- **Jogadores com personalidade:** características como Artilheiro, Líder, Raçudo, Frágil, Cobrador, Decide clássico e Paredão; escalação num campinho.
- **Mercado:** propostas relâmpago no último dia da janela.
- **Praticidade:** tutorial no primeiro jogo, tamanho do texto ajustável e, na versão Apps Script, jogos salvos no Google Drive do dono do app.

## O que tem

- **Ligas:** 47 divisões em 35 países: 22 da Europa (com segunda divisão nas principais), os 10 países da América do Sul, México, Estados Unidos e Arábia Saudita, com os elencos da temporada 2026–27.
- **Copas nacionais** em mata-mata.
- **Competições internacionais:** Copa dos Campeões (Europa), copas sul-americanas no formato da Libertadores e da Sul-Americana, Mundial de Clubes (anual) e Super Mundial de Clubes (a cada 4 anos).
- **Ranking Mundial de Clubes:** últimas 4 temporadas com peso decrescente (100%, 75%, 50%, 25%); títulos internacionais valem muito mais que os nacionais.
- **Gestão:** escalação e táticas, partida ao vivo com substituições, energia, lesões, cartões e suspensões, mercado de transferências, finanças, patrocínio master, estádio, reputação, moral do time, diretoria e propostas de emprego.

## Arquivos

| Arquivo | Conteúdo |
|---|---|
| `index.html` | O jogo inteiro |
| `data.js` | Base com **nomes fictícios** (clubes, jogadores, estádios, ligas e copas). Versão para distribuição comercial. |
| `data_real.js` | Pacote opcional com **nomes reais**, gerado por `tools/05_pacotes.pl`. **Não fica no GitHub**: só no computador, no projeto Apps Script e na pasta "WiFoot Manager — dados" do Google Drive. Se estiver na pasta, é usado no lugar do `data.js`. |
| `loja/` | Material da Google Play: textos, respostas dos formulários, capturas e imagem de destaque ([loja/LEIA-ME.md](loja/LEIA-ME.md)) |
| `docs/privacidade.html` | Política de privacidade (exigida pela loja) |
| `db/` | Banco de dados completo e documentação das fontes ([db/README.md](db/README.md)) |
| `tools/` | Scripts que coletam e atualizam o banco |

## Fontes dos dados

Elencos e clubes vêm da **Wikipédia** (CC BY-SA 4.0) e do **Wikidata** (CC0). Força, valor de mercado e salário dos jogadores são estimativas próprias do jogo. Detalhes em [db/README.md](db/README.md).

Nomes reais de jogadores e marcas de clubes e competições podem exigir autorização para uso comercial; por isso a versão comercial usa só o `data.js` (nomes fictícios).

## Versão no Google Apps Script

A pasta `appsscript/` tem o projeto para publicar o jogo como app da Web do Google:

1. `perl tools/06_appsscript.pl` gera `appsscript/Index.html` (o jogo) e `appsscript/Dados.html` (os dados; usa `data_real.js` se existir).
2. No projeto do Apps Script, copie `Code.gs`, `Index.html` e `Dados.html` (mesmos nomes).
3. **Implantar → Nova implantação → App da Web**. Para atualizar, use **Gerenciar implantações → editar → Nova versão** (o link continua o mesmo).

## App instalável (GitHub Pages)

A pasta `docs/` é o jogo pronto para instalar no celular ou no computador (PWA), com **nomes fictícios** e funcionamento offline. É gerada por:

```bash
powershell -ExecutionPolicy Bypass -File tools/icones.ps1 -Out docs   # ícones (só quando mudar o visual)
perl tools/07_pwa.pl                                                  # jogo, dados, manifesto e service worker
```

O GitHub Pages publica essa pasta (Settings → Pages → branch `main`, pasta `/docs`). Para instalar: abra o site no Chrome (Android/computador) e use **Instalar app**; no iPhone, Safari → Compartilhar → **Adicionar à Tela de Início**.
