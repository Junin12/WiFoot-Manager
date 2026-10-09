# WiFoot Manager

Jogo de técnico de futebol no estilo Brasfoot, feito em HTML, CSS e JavaScript puro, sem instalação nem build.

## Como jogar

Abra o `index.html` no navegador (dois cliques). O progresso é salvo automaticamente no navegador (IndexedDB); também dá para exportar e importar o jogo salvo pela aba **Jogo**.

## Modos de jogo

- **Treinador:** comande um clube. Opção **Virar SAF?**: a cada início de temporada, investidores podem aportar até 15x o valor do clube.
- **Modo Carreira:** você é um jogador que começa na base aos 17 anos, recebe propostas de outros clubes e constrói a carreira até se aposentar.

## O que tem

- **Ligas:** 47 divisões em 35 países: 22 da Europa (com segunda divisão nas principais), os 10 países da América do Sul, México, Estados Unidos e Arábia Saudita, com os elencos da temporada 2026–27.
- **Copas nacionais** em mata-mata.
- **Competições internacionais:** Copa dos Campeões (Europa), copas sul-americanas no formato da Libertadores e da Sul-Americana, Mundial de Clubes (anual) e Super Mundial de Clubes (a cada 4 anos).
- **Ranking Mundial de Clubes:** pontuação das últimas 4 temporadas, com peso maior para as competições mais importantes.
- **Gestão:** escalação e táticas, partida ao vivo com substituições, energia, lesões, cartões e suspensões, mercado de transferências, finanças, patrocínio master, estádio, reputação, moral do time, diretoria e propostas de emprego.

## Arquivos

| Arquivo | Conteúdo |
|---|---|
| `index.html` | O jogo inteiro |
| `data.js` | Base com **nomes fictícios** (clubes, jogadores, estádios, ligas e copas). Versão para distribuição comercial. |
| `data_real.js` | Pacote opcional com **nomes reais**. Se estiver na pasta, é usado no lugar do `data.js`. Distribuição gratuita, separada do aplicativo. |
| `db/` | Banco de dados completo e documentação das fontes ([db/README.md](db/README.md)) |
| `tools/` | Scripts que coletam e atualizam o banco |

## Fontes dos dados

Elencos e clubes vêm da **Wikipédia** (CC BY-SA 4.0) e do **Wikidata** (CC0). Força, valor de mercado e salário dos jogadores são estimativas próprias do jogo. Detalhes em [db/README.md](db/README.md).

Nomes reais de jogadores e marcas de clubes e competições podem exigir autorização para uso comercial; por isso a versão comercial usa só o `data.js` (nomes fictícios).
