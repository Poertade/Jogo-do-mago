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
| **Aspectos**: 6 primais, ~40 compostos em camadas | 6 primais + 20 compostos (receitas da versão 4.2), com Gelum, Tenebrae, Limus, Vitium e Alienis; só as receitas de nível 1 vêm sabidas, as outras vêm dos livros | parcial |
| **Pesquisa achada no mundo** (fragmentos de conhecimento, notas em masmorras) | livros perdidos na Dungeon, lidos no atril da escola: cada um ensina uma receita sorteada que o jogador ainda não tem | feito |
| **Potes protegidos** (guardam essentia) | potes de Vis no cinto: guardam o que sobra dos Nódulos e recarregam a varinha (R). O jogador começa sem nenhum: compra no Almoxarife ou fabrica na bancada de vidraria (D069) | adaptado |
| **Varinha**: núcleo (madeira, cana, sangue…) define a capacidade de Vis; ponteiras (ferro, ouro, taumium…) definem o desconto no custo | varinha com um recipiente por primal e limite total. Núcleos (madeira, osso, cristal) dão os limites; ponteiras (ferro, latão, prata), a eficiência. Cada peça é liberada por uma página e feita na Bancada Arcana com materiais da Dungeon e Vis da varinha (`data/wands/`, D071) | adaptado |
| **Focus**: encaixado na varinha, define a magia (Fogo, Gelo, Choque, Escavação, Portal…) | Fogo, Gelo (lentidão), Choque (raio em corrente, Aer) e Escavação (Terra: derruba paredes rachadas e arranca cristal dos veios), trocados com Q; os três últimos liberados por pesquisa (D060, D073) | quatro Focus |
| **Nódulos de aura**: esferas de Vis com aspectos; a varinha drena Vis segurando o botão; o nódulo se recarrega devagar | Nódulos de Ignis e de Aqua (com Ordo) na escola, que não acabam; na Dungeon, nódulos que se esgotam | feito (sem recarga lenta) |
| **Vis**: a varinha guarda os seis primais (Aer, Terra, Ignis, Aqua, Ordo, Perditio), cada um com sua reserva; no 4, em centésimos ("centi-Vis") | um recipiente por primal (até 10) e, a pedido do usuário, um limite total (30) (D051) | feito (valores inteiros) |
| **Bancada arcana** (receitas que gastam Vis da varinha) | bancada de vidraria: um pote de Vis custa cacos de vidro e Ignis e Ordo da varinha (D069) | adaptado |
| **Cadinho** (alquimia): objetos jogados nele se desfazem em essentia dos seus aspectos; receitas alquímicas pedem essentia de aspectos certos e um catalisador | cadinho no laboratório da escola: materiais da Dungeon viram essência; a essência é anotada como pontos de pesquisa ou paga receitas (Elixir de Victus, Vis destilado em potes), sem catalisador (D072) | adaptado |
| **Pedestal de recarga**: recarrega a varinha com Vis de uma rede de nódulos | — | ideia futura |

## Ideias para próximos marcos (precisam de aprovação)

1. ~~**Mais Focus**~~: Gelo (M7), Choque e Escavação (M10). Ainda faltam, por exemplo, o de Portal (Iter) e o de Escudo.
2. ~~**Núcleos e ponteiras de varinha**~~: feito no M8 (D071).
3. **Mais aspectos compostos** e objetos que os contenham. A Dungeon pode trazer aspectos que a escola não tem, como Alienis, Tenebrae e Vitium; isso faz explorar valer pesquisa.
4. **Notas de pesquisa mais ricas** (a versão simples já existe): tinta e penas como recurso, notas que pedem aspectos raros da Dungeon, copiar uma nota resolvida.
5. **Nódulos na Dungeon** (raros), com reserva que se esgota e volta devagar. Hoje a decisão 3 diz "sem recarga fora da escola"; mudar isso pede aprovação.
6. ~~**Alquimia (cadinho e essentia)**~~: feito no M9 (D072). Ainda daria para trazer o fluxo (essência que sobra polui) e os alambiques.
7. **Distorção ("warp")**: conhecimento proibido com efeitos colaterais. Cabe na premissa das ruínas da Primeira Escola.
8. **Inimigos com aspectos coerentes**: cada um com uma fraqueza ligada aos aspectos que tem, que a Lente revela (pesquisar o inimigo ajuda a vencê-lo).
