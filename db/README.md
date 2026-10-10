# Banco de dados do WiFoot Manager

Banco montado só com **dados abertos**. Os arquivos com **nomes reais não ficam no GitHub**: são gerados pelos scripts de `tools/` e guardados no computador e no Google Drive (pasta "WiFoot Manager — dados", arquivo `wifoot-banco-nomes-reais.zip`). Para trabalhar em outro computador, descompacte esse zip na pasta do jogo.

| Arquivo | O que é | No GitHub? |
|---|---|---|
| `wifoot-db.json` | Banco completo com nomes reais: ligas, clubes (cidade, estádio, capacidade, fundação) e jogadores (posição, nascimento, nacionalidade, altura, força, valor, salário). | Não |
| `ligas.json`, `elencos.json`, `wikidata.json` | Etapas intermediárias da coleta. | Não |
| `cores.json` | Duas cores de cada clube, pelo código do Wikidata. | Sim |
| `cache/` | Respostas brutas das APIs. | Não |

## Fontes e licenças

- **Wikipédia em inglês**: participantes de cada liga (artigo da temporada) e elenco atual de cada clube (seção de elenco do artigo do clube). Texto sob [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/); ao redistribuir o banco, cite a Wikipédia.
- **Wikidata**: nascimento, posição, nacionalidade, altura, jogos pela seleção, cidade e estádio. Domínio público ([CC0](https://creativecommons.org/publicdomain/zero/1.0/)).

Nenhum dado do Sofascore, Transfermarkt, EA FC/SoFIFA, FBref ou APIs de uso não comercial é usado.

## Força, valor e salário

São **estimativas próprias do jogo**, calculadas em `tools/04_banco.pl`:

1. Cada liga tem um nível definido pelo jogo (média dos 11 melhores de um clube mediano e a distância entre o maior e o menor clube).
2. O clube é posicionado dentro da liga pela notoriedade do elenco: número de artigos na Wikipédia (em todas as línguas) e jogos pela seleção principal de cada jogador.
3. O jogador é posicionado dentro do elenco pelos mesmos sinais, com ajuste por idade.
4. Valor de mercado e salário saem da força e da idade, com as fórmulas do jogo.

## Versões de distribuição

- `data.js`: **nomes fictícios** de clubes, jogadores, estádios, ligas e copas continentais, com as mesmas forças, idades, posições, nacionalidades e capacidades. Os nomes lembram os reais sem repeti-los: clube com o mesmo começo e as mesmas duas cores (Cruzeiro vira "Cruzense Azul de Belo Horizonte"), jogador com as mesmas iniciais e outros nomes (Kaio Jorge vira algo como "Kiko Joabe"). É a versão para a loja de aplicativos.
- `data_real.js`: **nomes reais**, pacote opcional e gratuito, distribuído separado do aplicativo (fica fora do GitHub; há uma cópia no Google Drive). Se o arquivo estiver na pasta do jogo, ele é usado no lugar do fictício.

Nomes reais de jogadores e marcas de clubes e competições podem exigir autorização para uso comercial (direito de imagem e marcas registradas). Por isso a versão comercial usa só o `data.js`.

## Atualizar

Requer Perl e curl (já vêm com o Git para Windows):

```bash
cd tools
perl 01_ligas.pl      # participantes das ligas na temporada atual
perl 02_elencos.pl    # elencos atuais dos clubes
perl 03_wikidata.pl   # dados dos jogadores e clubes
perl 03b_cores.pl     # duas cores de cada clube (Wikidata e uniforme 1 da Wikipédia)
perl 04_banco.pl      # monta db/wifoot-db.json e estima força, valor e salário
perl 05_pacotes.pl    # gera data.js (fictício) e data_real.js (real)
```

Para uma nova temporada, troque os títulos dos artigos em `01_ligas.pl` (por exemplo, `2027–28 Premier League`) e apague a pasta `db/cache`.
