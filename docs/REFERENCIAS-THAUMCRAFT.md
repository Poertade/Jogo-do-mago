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
| **Notas de pesquisa**: um quebra-cabeça hexagonal ligando aspectos para liberar pesquisas | páginas pagas diretamente com pontos de aspectos | simplificado |
| **Taumonomicon**: o livro com as pesquisas e receitas | Livro de Pesquisa (Tab) | parcial |
| **Aspectos**: 6 primais, ~40 compostos em camadas | 6 primais + 15 compostos (receitas da versão 4.2) | parcial |
| **Varinha**: núcleo (madeira, cana, sangue…) define a capacidade de Vis; ponteiras (ferro, ouro, taumium…) definem o desconto no custo | varinha com reserva por primal e eficiência (`data/wands/`); visual com núcleo + ponteiras | parcial (um tipo só) |
| **Focus**: encaixado na varinha, define a magia (Fogo, Gelo, Choque, Escavação, Portal…) | Focus de Fogo (projétil carregado) | um Focus |
| **Nódulos de aura**: esferas de Vis com aspectos; a varinha drena Vis segurando o botão; o nódulo se recarrega devagar | Nódulo de Vis no Salão de Estudos (segurar E) | feito (sem esgotar) |
| **Vis** primal (Aer, Terra, Ignis, Aqua, Ordo, Perditio), guardado em centésimos ("centi-Vis") | reserva inteira por primal | simplificado |
| **Pedestal de recarga / bancada arcana**: recarregam a varinha com Vis de uma rede de nódulos | — | ideia futura |

## Ideias para próximos marcos (precisam de aprovação)

1. **Mais Focus**, cada um gastando primais diferentes. Do Thaumcraft 4: Gelo (Aqua + Ordo, projétil que congela), Choque (Aer, raio em cadeia), Escavação (Terra/Ordo, quebra paredes frágeis e abre passagens secretas). Usam as outras reservas da varinha, que já existem.
2. **Núcleos e ponteiras de varinha** como dados: capacidade (núcleo) e desconto (ponteiras), montados numa bancada na escola.
3. **Mais aspectos compostos** e objetos que os contenham. A Dungeon pode trazer aspectos que a escola não tem, como Alienis, Tenebrae e Vitium; isso faz explorar valer pesquisa.
4. **Quebra-cabeça das notas de pesquisa** (versão simples): ligar dois aspectos-alvo por uma corrente de aspectos vizinhos numa grade, gastando pontos. É o coração da pesquisa do Thaumcraft 4.
5. **Nódulos na Dungeon** (raros), com reserva que se esgota e volta devagar. Hoje a decisão 3 diz "sem recarga fora da escola"; mudar isso pede aprovação.
6. **Alquimia (cadinho e essentia)**: jogar objetos no cadinho os derrete em aspectos; receitas pedem aspectos específicos.
7. **Distorção ("warp")**: conhecimento proibido com efeitos colaterais. Cabe na premissa das ruínas da Primeira Escola.
8. **Inimigos com aspectos coerentes**: cada um com uma fraqueza ligada aos aspectos que tem, que a Lente revela (pesquisar o inimigo ajuda a vencê-lo).
