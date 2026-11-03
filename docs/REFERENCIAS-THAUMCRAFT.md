# Thaumcraft como base do jogo

> O usuário definiu o Thaumcraft (versões 3 e 4) como base de quase tudo no jogo. Este documento
> resume as mecânicas, o que já foi adotado e o que pode entrar depois.
> **As obras inspiram, não fornecem conteúdo:** nada de texturas, modelos ou textos copiados. Os nomes
> que remetem ao Thaumcraft ficam só em `locales/names.csv`, para serem trocados numa versão distribuída.
>
> **Fontes:** buscas na web em 2026-11-03 (resumos de wikis e fóruns da comunidade) e conhecimento geral
> do mod. A wiki do Thaumcraft 4 recusa acesso automático deste ambiente (erro 403), então detalhes
> numéricos podem divergir da versão exata.

## O ciclo do Thaumcraft 4 (e como ele aparece aqui)

| Thaumcraft 4 | Neste jogo | Estado |
| --- | --- | --- |
| **Taumômetro**: segurar sobre algo revela seus aspectos e dá pontos de pesquisa de cada um | **Lente Taxonômica** (botão direito, 1,5 s) | feito |
| Escanear algo com aspecto desconhecido, sem saber os componentes, **falha** ("conhecimento insuficiente") | igual; o HUD mostra "?" no que falta | feito |
| **Mesa de Pesquisa**: combinar dois aspectos conhecidos descobre o composto e rende pontos dele | igual (1 ponto de cada pai → 1 do composto) | feito |
| **Notas de pesquisa**: um quebra-cabeça hexagonal ligando aspectos para liberar pesquisas | nota hexagonal no pergaminho da Mesa: escrever um aspecto gasta 1 ponto dele; vizinhos se ligam quando um é pai do outro; ligar todos os alvos estuda a página | feito (sem tinta, sem cópia de notas) |
| **Taumonomicon**: o livro com as pesquisas e receitas | Livro de Pesquisa (Tab) | parcial |
| **Aspectos**: 6 primais, ~40 compostos em camadas | 6 primais + 16 compostos (receitas da versão 4.2), com Gelum (Ignis + Perditio) | parcial |
| **Varinha**: núcleo (madeira, cana, sangue…) define a capacidade de Vis; ponteiras (ferro, ouro, taumium…) definem o desconto no custo | varinha com um recipiente por primal, limite por recipiente e limite total, e eficiência (`data/wands/`); visual com núcleo + ponteiras; mostrador de frascos no HUD | parcial (um tipo só) |
| **Focus**: encaixado na varinha, define a magia (Fogo, Gelo, Choque, Escavação, Portal…) | Focus de Fogo e Focus de Gelo (lentidão), trocados com Q; o de Gelo é liberado por pesquisa | dois Focus |
| **Nódulos de aura**: esferas de Vis com aspectos; a varinha drena Vis segurando o botão; o nódulo se recarrega devagar | Nódulos de Ignis e de Aqua (com Ordo) na escola, que não acabam; na Dungeon, nódulos que se esgotam | feito (sem recarga lenta) |
| **Vis**: a varinha guarda os seis primais (Aer, Terra, Ignis, Aqua, Ordo, Perditio), cada um com sua reserva; no 4, em centésimos ("centi-Vis") | um recipiente por primal (até 10) e, a pedido do usuário, um limite total (30) (D051) | feito (valores inteiros) |
| **Pedestal de recarga / bancada arcana**: recarregam a varinha com Vis de uma rede de nódulos | — | ideia futura |

## Ideias para próximos marcos (precisam de aprovação)

1. **Mais Focus**, cada um gastando primais diferentes. O de Gelo já existe (M7). Do Thaumcraft 4 ainda faltam Choque (Aer, raio em cadeia) e Escavação (Terra/Ordo, quebra paredes frágeis e abre passagens secretas).
2. **Núcleos e ponteiras de varinha** como dados: capacidade (núcleo) e desconto (ponteiras), montados numa bancada na escola.
3. **Mais aspectos compostos** e objetos que os contenham. A Dungeon pode trazer aspectos que a escola não tem, como Alienis, Tenebrae e Vitium; isso faz explorar valer pesquisa.
4. **Notas de pesquisa mais ricas** (a versão simples já existe): tinta e penas como recurso, notas que pedem aspectos raros da Dungeon, copiar uma nota resolvida.
5. **Nódulos na Dungeon** (raros), com reserva que se esgota e volta devagar. Hoje a decisão 3 diz "sem recarga fora da escola"; mudar isso pede aprovação.
6. **Alquimia (cadinho e essentia)**: jogar objetos no cadinho os derrete em aspectos; receitas pedem aspectos específicos.
7. **Distorção ("warp")**: conhecimento proibido com efeitos colaterais. Cabe na premissa das ruínas da Primeira Escola.
8. **Inimigos com aspectos coerentes**: cada um com uma fraqueza ligada aos aspectos que tem, que a Lente revela (pesquisar o inimigo ajuda a vencê-lo).
