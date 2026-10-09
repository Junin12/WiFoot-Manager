# WiFoot Manager

Jogo de técnico de futebol no estilo Brasfoot, feito em HTML, CSS e JavaScript puro, sem instalação nem build.

## Como jogar

Abra o `index.html` no navegador (dois cliques). O progresso é salvo automaticamente no navegador; também dá para exportar e importar o jogo salvo pela aba **Jogo**.

## O que tem

- **Ligas:** 14 ligas europeias, Brasileirão Séries A e B, Liga Profesional argentina (1ª e 2ª), com acesso e rebaixamento.
- **Copas nacionais** em mata-mata (Copa do Brasil, Copa Argentina etc.).
- **Competições internacionais:** Copa dos Campeões (Europa), Copa Libertadores, Copa Sul-Americana, Mundial de Clubes (anual) e Super Mundial de Clubes (a cada 4 anos).
- **Ranking Mundial de Clubes:** pontuação das últimas 4 temporadas, com peso maior para as competições mais importantes.
- **Gestão:** escalação e táticas, partida ao vivo com substituições, energia, lesões, cartões e suspensões, mercado de transferências, finanças, patrocínio master, estádio, reputação, moral do time, diretoria e propostas de emprego.

## Arquivos

| Arquivo | Conteúdo |
|---|---|
| `index.html` | O jogo inteiro |
| `data.js` | Clubes e jogadores europeus |

### Dados sul-americanos (fora do repositório)

Brasil, Argentina e os demais clubes da Libertadores e da Sul-Americana **não são versionados** (estão no `.gitignore`) e ficam guardados à parte.

Para jogar com eles, coloque na pasta do jogo, ao lado do `index.html`:

- `data_sa.js` — Brasileirão Séries A e B e liga argentina 2026
- `data_pool.js` — outros sul-americanos e participantes reais das copas de 2026

Sem esses arquivos o jogo funciona normalmente, só com as ligas europeias (sem Libertadores, Sul-Americana nem Mundiais).

## Fontes dos dados

Os dados de clubes e jogadores são usados apenas para fins pessoais e de estudo. Confira os termos de uso dessas fontes antes de redistribuir.
