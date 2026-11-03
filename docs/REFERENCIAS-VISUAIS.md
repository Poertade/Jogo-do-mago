# Referências visuais e direção de arte

> Pesquisa feita em 2026-11-03, a pedido do usuário, enquanto as imagens de referência não chegam.
> As obras citadas **inspiram, não fornecem conteúdo**: nada de nomes, mapas, texturas ou personagens copiados.

## O que a pesquisa encontrou

**Lunacid.** Resenhas e resumos descrevem um estilo poligonal "áspero", de baixa resolução, na linha PS1/Dreamcast, que cria sensação de pavor; a combinação desse visual com uma trilha hipnótica deixa o Grande Poço inquietante, e cada área tem identidade própria ("cada parte parece habitada"). Fontes: [RPG Site](https://www.rpgsite.net/review/15221-lunacid-review), [Superjump](https://www.superjumpmagazine.com/lunacid-is-old-school-to-a-t/), [Vaporlens](https://vaporlens.app/app/1745510/lunacid), [OpenCritic](https://opencritic.com/game/15836/lunacid).

**Escola de Huppermagia (Wakfu).** A busca não encontrou descrições da escola nem da arquitetura dela, só páginas sobre a classe Huppermage ([Wakfu Wiki](https://wakfu.wiki.gg/wiki/Huppermage)). Fica valendo o que a especificação lista: salão de entrada, dormitórios, estufa, andar superior e passagens secretas.

## Direção adotada (original)

**Princípios**, tirados das descrições acima e da especificação:

1. Pouca geometria, texturas pequenas e "ásperas", sem suavização.
2. Escuridão como regra; a luz é rara e sempre tem uma fonte visível (vela, braseiro, cristal, a própria magia).
3. Cada sala com uma cor dominante, para ser reconhecida de longe.
4. Névoa que esconde o fim das salas grandes.

**Escola (Colégio do Astrolábio): estudo e abrigo, mas ainda sombrio.**

| Elemento | Cor | Uso |
| --- | --- | --- |
| Luz de vela e braseiro | âmbar `#ffa860` | única luz quente do jogo |
| Madeira escura | `#3b2a1e` | piso, mesas, estantes |
| Pedra | cinza amarronzado `#5c5650` | paredes |
| Ambiente | azul frio fraco `#4a5468` | o que a vela não alcança |
| Névoa | marrom quase preto `#0e0b0a` | fundo das salas |
| Latão | `#b08a3c` | instrumentos: Lente, astrolábio, ferragens |

**Sala do Portal:** pedra mais fria e alta, com a luz violeta e verde-água do portal como cor dominante.

**Dungeon (ruínas da Primeira Escola): frio, úmido, abandonado.**

| Elemento | Cor | Uso |
| --- | --- | --- |
| Pedra | azul-esverdeado dessaturado `#3a4246` | paredes e piso |
| Névoa | `#05070a`, densa (some a ~11 m) | limitar a visão |
| Tochas | poucas, laranja pálido | — |
| Inimigos | verde pálido `#9fd8a0` | brilho nos olhos e nas fendas |

**Magia:**
- O fogo do jogador é laranja vivo `#ff8a3a` e ilumina o caminho, por isso é o momento mais brilhante da tela.
- A Lente usa verde-água `#5fd3c6`.

## Inimigos (referência: Lunacid)

Pedido do usuário depois do M5: o primeiro inimigo estava feio; usar os de Lunacid como base. As buscas não trouxeram um bestiário nem imagens (só textos, como os que falam do visual "áspero" de PS1/Dreamcast e do sistema de desmembrar partes do corpo dos inimigos — [TV Tropes](https://tvtropes.org/pmwiki/pmwiki.php/VideoGame/Lunacid)). Princípios adotados:

1. **Silhueta antes de detalhe.** Cada inimigo precisa ser reconhecível de longe, no escuro, só pelo contorno e pelo brilho dos olhos.
2. **O detalhe mora na textura**, não na geometria: osso rachado, pano rasgado (com recorte), rosto pintado. Poucos polígonos.
3. **Animação aos trancos**, em poucos quadros por segundo (12), como no PS1.
4. **Corpo articulado** (juntas e peças), para gestos inquietantes: cabeça que pende de lado, mandíbula que bate, braço que se estica para o jogador.
5. **Ligado ao lugar:** os mortos-vivos da Primeira Escola usam restos de uniforme (manto, barrete de bedel, chaves).

O Bedel Descarnado segue esses princípios (`scenes/enemies/bone_beadle.tscn`, `scripts/game/enemy_rig.gd`). Próximos inimigos humanoides podem reaproveitar o esqueleto; criaturas de outro formato (como o desmembramento por partes) pedem um esqueleto próprio.

**Nódulo de Vis:** núcleo e bolinhas na cor do aspecto (Ignis: laranja `#e0602a`), centro quase branco, luz da mesma cor. É a fonte de luz quente principal do Salão de Estudos.

## Interface (menus e HUD)

Pedido do usuário depois da rodada do pergaminho: os menus estavam "destoantes, como se fossem de outro jogo". Princípios adotados (D052):

1. **Mesmo tamanho de pixel do mundo**, ou perto dele: a interface é desenhada em 640×360 e ampliada 2× (o mundo, em 240 linhas, fica 3×).
2. **Mesmo filtro:** cor limitada e dithering iguais aos do mundo.
3. **Papel visto à luz de vela:** pergaminho apagado e sujo (`#8f7650`), bordas queimadas, tinta quase preta (`#1c120a`) e títulos em vermelho escuro (`#5c120a`). A Mesa de Pesquisa tem moldura de madeira escura (`#30200f`).
4. **O jogo continua visível** atrás dos menus, escurecido.
5. **HUD:** texto claro (`#dbcdad`) com contorno preto de 1 pixel; o mostrador de Vis segue o do Thaumcraft 4 (orbe do Focus e frascos em leque), em desenho próprio.

## Dungeon do M6

- **Aprendiz Esquecido:** o mesmo esqueleto do Bedel, menor e mais curvado, com uniforme cinza-azulado desbotado (`assets/textures/uniform.png`), capuz, gola clara, livro e pena. Olhos azul-claros.
- **Lodo de Tinta:** gosma quase preta, com veios azulados e letras borradas na textura (`assets/textures/ink.png`), quatro olhos amarelo-pálidos desiguais e um braço de tinta. Silhueta baixa e larga, oposta à dos esqueletos.
- **Salas:** cada uma com uma cor de luz própria, para ser reconhecida (princípio 3):

| Sala | Luz |
| --- | --- |
| Dormitório alagado | azul fria, com poças de tinta |
| Biblioteca desabada | lamparinas verde-água e um feixe pálido do alto |
| Corredor do ossuário | tochas e lamparinas |
| Fonte de Vis | lilás, com a cor dos Nódulos |
