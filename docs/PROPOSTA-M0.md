# M0: proposta técnica

> **Status:** aguardando aprovação. Nenhum código do jogo foi escrito.
> A decisão 1 (tecnologia) foi delegada a mim pelo usuário e está registrada em `DECISIONS.md`.
> As decisões 2 a 9, o computador de jogo e as referências visuais aguardam resposta (seção (c)).

Especificação completa: [`ESPECIFICACAO.md`](ESPECIFICACAO.md).

---

## (a) Tecnologia

### Opções avaliadas

| Critério | **Three.js + TypeScript** (navegador) | Godot 4 + GDScript | Unity 6 + C# |
| --- | --- | --- | --- |
| Visual PS1 | Shader próprio e pequeno, cada efeito com liga/desliga | Shaders PS1 livres prontos | Shaders de terceiros (vários pagos) ou próprios |
| Primeira pessoa e colisão | Escritos por nós; simples, porque as salas são blocos | Prontos (`CharacterBody3D`) | Prontos (`CharacterController`) |
| Desempenho em PC modesto | Muito leve em 240 linhas (WebGL2) | Leve (renderizador Compatibility) | Mais pesado; editor com ~10 GB |
| Testar a lógica sem abrir o jogo | Vitest, em Node, em segundos | GUT ou gdUnit4 em modo headless | Unity Test Framework, exige o editor |
| Conteúdo em dados | JSON validado por esquema | JSON ou Resources (`.tres`) | ScriptableObjects ou JSON |
| Editor visual de fases | Não tem (salas em JSON; depois Blender + glTF) | Excelente | Excelente |
| Para jogar | Navegador em qualquer sistema (link ou `npm run dev`) | Executável por sistema | Executável por sistema |
| Desenvolvimento pelo Claude Code na nuvem | Compila, testa **e roda o jogo** com captura de tela (testado neste ambiente: WebGL2 funciona no Chromium headless) | Compila e testa a lógica, mas o modo headless não renderiza: não vejo a tela | Não roda neste ambiente: não compila nem testa |
| Save em arquivo | Armazenamento local (JSON legível) + exportar/importar `.json` | Arquivo real (`user://`) | Arquivo real |
| Licença | MIT, sem conta | MIT, sem conta | Proprietária, exige conta |

### Escolha: Three.js + TypeScript + Vite, no navegador (WebGL2)

Motivos, do mais ao menos importante:

1. **Cada marco verificado de verdade antes da entrega.** O projeto é desenvolvido pelo Claude Code na nuvem. Com a pilha web eu rodo o jogo aqui, tiro capturas de tela e testo o ciclo escola → portal → combate automaticamente. Com Godot eu só rodaria os testes de lógica, sem ver a tela; com Unity, nada.
2. **Roda em qualquer computador, sem instalar.** Basta um navegador atual (Windows, Linux ou macOS), e o jogo pode ser publicado num link (GitHub Pages). Isso também reduz o risco enquanto não sei qual é o seu computador.
3. **Separação entre lógica e renderização fácil de garantir.** A lógica fica em TypeScript puro (`src/core`), sem Three.js nem navegador, testada com Vitest. Um teste falha se essa pasta importar a parte gráfica.
4. **O efeito PS1 é nosso e pequeno.** Vertex snapping, mapeamento afim e névoa num material; cor limitada e dithering num passe final. Sem dependência de terceiros e bom de estudar.
5. **Tudo é texto.** Código e dados em JSON: fáceis de ler, comparar no git e modificar, por você ou pelo Claude.

O que se perde, e como compensar:

- **Editor visual de fases**, o ponto mais forte do Godot. As salas serão descritas em JSON (blocos de greybox, luzes e pontos de entrada, saída e spawn). Quando houver arte, entram modelos glTF feitos no Blender, com objetos vazios nomeados marcando entradas, saídas e spawns.
- **Recursos prontos de motor** (física, navegação, animação). Escrevemos versões pequenas, só quando precisar: colisão de cilindro contra caixas agora; busca de caminho em grade quando houver várias salas.
- **Save como arquivo em disco.** No navegador o save fica no armazenamento local, em JSON legível e versionado, com os botões "Exportar save" e "Importar save" nas opções. Se você quiser o arquivo direto no disco, o jogo pode ser empacotado depois como aplicativo desktop (Tauri ou Electron) sem mudar a lógica: o save passa por uma interface de armazenamento.

**Se o editor visual for mais importante para você do que esses pontos, a troca é Godot 4, e precisa ser decidida antes do M1.**

### Renderizador

`WebGLRenderer` do Three.js (WebGL2), não WebGPU: funciona em praticamente qualquer placa de vídeo recente, inclusive gráficos integrados. O jogo desenha numa imagem pequena (padrão: 240 linhas de altura, por exemplo 427×240 em 16:9 ou 320×240 em 4:3) e amplia com pixels nítidos, sem filtragem nem mipmaps. A pergunta 10 (seu sistema e computador) serve para calibrar esses padrões.

### Dependências previstas

Cada uma entra com justificativa em `DECISIONS.md` no marco em que for instalada, com versão fixa.

| Pacote | Para quê |
| --- | --- |
| `three` | renderização 3D |
| `typescript` | tipos: erros aparecem no editor e os dados têm formato conhecido |
| `vite` | servidor de desenvolvimento com recarga instantânea, e o build |
| `vitest` | testes da lógica, com a mesma configuração do Vite |
| `zod` | valida os JSON de conteúdo e dá mensagens claras quando um campo está errado |

Para os testes de fumaça e as capturas de tela uso o Playwright que já existe no ambiente de desenvolvimento; ele não é necessário para jogar.

---

## (b) Arquitetura em módulos

### Camadas

```text
data/*.json, locales/*.json   conteúdo e textos, sem código
        │ validados ao carregar
        ▼
src/core     lógica pura: aspectos, conhecimento, pesquisa, varinha, magia,
             combate, IA, save, aleatório com semente
        │ estado e eventos           ▲ comandos (lançar, escanear, estudar…)
        ▼                            │
src/game     entidades, salas e sistemas: liga a lógica ao mundo 3D
src/ui       HUD, Livro de Pesquisa, Mesa, menus (HTML/CSS sobre o jogo)
        │
        ▼
src/engine   Three.js e navegador: render PS1, entrada, colisão, áudio, laço
```

Regras:

- `core` não importa `three`, o navegador nem outras pastas. Um teste garante isso.
- `engine` não conhece regras do jogo e poderia servir a outro jogo.
- `game` e `ui` usam `core` e `engine`.
- Conteúdo (valores, textos, aspectos) só em `data/` e `locales/`.

### Pastas

```text
data/
  aspects.json          aspectos (primais agora; compostos no futuro)
  scannables.json       objetos escaneáveis e seus aspectos
  wands.json            varinhas
  foci.json             Focus
  enemies.json          inimigos
  research-pages.json   páginas de pesquisa
  rooms/                uma sala por arquivo
locales/pt-BR/
  ui.json               textos de interface
  names.json            ÚNICO arquivo com nomes que remetem a outras obras (decisão 7)
src/
  core/
    rng.ts              aleatório com semente
    content/            esquemas, carregamento, checagem de referências entre arquivos
    aspects.ts          aspectos e composição (pais)
    knowledge.ts        aspectos descobertos, alvos escaneados, pontos de pesquisa
    research.ts         páginas: custo, requisitos, estudo
    modifiers.ts        soma dos efeitos permanentes (ex.: +20% de dano de fogo)
    wand.ts             reservas por aspecto, eficiência, recarga
    spell.ts            carga, intervalo, custo, dano final
    combat.ts           vida, dano por elemento, fraquezas
    enemy-ai.ts         máquina de estados: parado, perseguindo, atacando
    run.ts              estado da incursão (reiniciado ao morrer)
    save.ts             formato versionado, migrações, interface de armazenamento
    events.ts           eventos tipados (core → game/ui)
  engine/
    renderer.ts         alvo de baixa resolução e ampliação nítida
    ps1/                material PS1 e passe final (cor limitada, dithering)
    input.ts            teclado, mouse, captura do ponteiro, ações
    collision.ts        cilindro contra caixas; raio de mira
    audio.ts            sons (M5)
    loop.ts             simulação em passo fixo (60 Hz) e render livre
  game/
    room-builder.ts     monta uma sala a partir do JSON
    scene-manager.ts    troca de sala, transições, morte → Salão de Estudos
    entities/           jogador, varinha, projétil, inimigo, escaneável, interagível
    systems/            escaneamento, magia, interação
  ui/
    i18n.ts  hud.ts  research-book.ts  research-table.ts  options-menu.ts
  main.ts
```

Os testes ficam ao lado do código (`*.test.ts`).

### Um quadro do jogo

1. `engine/input` lê teclado e mouse e produz ações (mover, interagir, carregar, escanear).
2. `game/systems` transformam as ações em comandos para o `core` (por exemplo, `spell.startCharge()` ou `scanner.tick(dt, alvo)`).
3. O `core` atualiza o estado e emite eventos (`aspectDiscovered`, `spellCast`, `enemyDied`, `playerDied`).
4. `game` reage no mundo 3D (cria o projétil, abre a saída, troca de sala) e `ui` atualiza o HUD.
5. `engine/renderer` desenha com os efeitos PS1.

A simulação roda em passo fixo, e toda aleatoriedade passa por um gerador com semente (`?seed=123` na URL, ou fixa nos testes), para reproduzir erros.

### Formato dos dados (rascunho; o esquema final sai no M1/M2)

Identificadores internos em inglês e neutros. O nome exibido vem de `locales/pt-BR/names.json` (por exemplo, `"aspect.fire": "Ignis"`).

```jsonc
// data/aspects.json — um primal e um composto futuro
{ "id": "fire",  "kind": "primal",   "parents": [],              "color": "#d9622b" }
{ "id": "light", "kind": "compound", "parents": ["fire", "air"], "color": "#f2e6a0" }

// data/scannables.json
{ "id": "candle", "aspects": { "fire": 3 } }

// data/wands.json — custo efetivo = custo do Focus ÷ eficiência
{ "id": "apprentice-wand", "capacity": { "fire": 30 }, "efficiency": 1.0 }

// data/foci.json
{ "id": "fire-focus", "spell": "projectile", "element": "fire", "cost": { "fire": 5 },
  "chargeTime": 0.6, "cooldown": 0.4, "damage": 15,
  "projectile": { "speed": 12, "radius": 0.15, "light": "#ff8a3a" } }

// data/enemies.json
{ "id": "bone-beadle", "health": 40, "damage": 10, "speed": 1.4,
  "sightRange": 10, "attackRange": 1.6, "attackCooldown": 1.5,
  "aspects": { "entropy": 3, "earth": 1, "order": 1 }, "weaknesses": { "fire": 1.5 } }

// data/research-pages.json
{ "id": "fire-comprehension", "cost": 3,
  "requires": { "pages": [], "aspects": ["fire"] },
  "effects": [{ "type": "damageMultiplier", "element": "fire", "value": 1.2 }] }

// data/rooms/dungeon-stone-chamber.json
{ "id": "dungeon-stone-chamber",
  "atmosphere": { "fogColor": "#07080c", "fogNear": 1.5, "fogFar": 12, "ambient": 0.06 },
  "blocks":    [{ "min": [-5, -0.2, -5], "max": [5, 0, 5], "texture": "stone-floor" }],
  "lights":    [{ "position": [0, 2.2, 0], "color": "#ff9a4a", "intensity": 1.0, "flicker": true }],
  "entrances": { "from-portal": { "position": [0, 0, 4], "yaw": 180 } },
  "exits":     [{ "position": [0, 0, -5], "opensWhen": "enemiesDefeated",
                  "to": { "room": "school-study-hall", "entrance": "from-dungeon" } }],
  "spawns":    [{ "enemy": "bone-beadle", "position": [0, 0, -2] }],
  "props":     [] }
```

O portal da escola é um prop interagível com destino em dados:
`{ "type": "portal", "position": [0, 0, -4], "to": { "room": "dungeon-stone-chamber", "entrance": "from-portal" } }`.
No futuro, `room` poderá apontar para um gerador em vez de uma sala fixa.

O save (só conhecimento; as opções gráficas ficam num registro separado, por máquina):

```json
{
  "formatVersion": 1,
  "knowledge": {
    "discoveredAspects": ["fire"],
    "scannedTargets": ["candle"],
    "researchPoints": 1,
    "studiedPages": []
  }
}
```

---

## (c) Decisões em aberto (seção 9 da especificação)

### 1. Tecnologia: decidida

Three.js + TypeScript + Vite (WebGL2), conforme (a). Delegada a mim; registrada em `DECISIONS.md`.

### 2. Tipo da magia de fogo

- **Recomendo: projétil com carga curta.** Segurar o botão esquerdo carrega por 0,6 s (a ponta da varinha acende e treme); soltar com a carga completa lança uma bola de fogo que **ilumina o caminho**; soltar antes cancela sem gastar Ignis. O custo é cobrado no disparo. Combina com Lunacid e com o pilar da atmosfera: o próprio fogo é uma das poucas luzes da Dungeon.
- Cone contínuo: gasta Ignis por segundo e combina mal com o tempo de carga da tabela.
- Híbrido: fica para outro Focus. O campo `spell` do Focus já permite tipos diferentes.

### 3. Recarga da varinha fora da escola

- **Recomendo: nenhuma; reserva finita por incursão.** Com os valores iniciais, 30 de Ignis dão 6 disparos e o inimigo morre com 2 acertos (15 × 1,5 = 22,5). Há folga agora, e isso vira tensão quando houver várias salas.
- Fontes de energia na Dungeon podem entrar depois como recompensa rara: o ponto de recarga já será um prop de dados que qualquer sala pode usar.
- Recarga lenta e contínua: tira a tensão de roguelike.

### 4. Morte

- **Recomendo: renascer no Salão de Estudos** com vida e reserva cheias, perdendo o que foi coletado na incursão (ainda não há itens).
- O conhecimento é salvo **no momento da descoberta**, não ao voltar: escanear o inimigo e morrer logo depois mantém a descoberta.
- Renascer na Sala do Portal deixaria a volta mais rápida, mas afastaria o jogador da Mesa e do braseiro.

### 5. Como o estudo vira poder

- **Recomendo: árvore leve.** Páginas com pré-requisitos (outras páginas e aspectos descobertos). Neste recorte existe só uma página; o campo `requires` já existe nos dados, então a árvore cresce sem mudar código.
- A combinação de aspectos para descobrir compostos entra depois como uma das formas de liberar páginas, no espírito de Thaumcraft.

### 6. Instrumento de escaneamento

- **Recomendo:** **Lente Taxonômica** (nome provisório; alternativas: Monóculo de Aferição, Prisma Analítico). Uma lente de latão com aro graduado, na **mão esquerda**. Ao segurar o botão direito, ela sobe na frente da câmera e o aro se enche como barra de progresso.
- Não ocupa a mão da varinha, mas **escanear e lançar magia não acontecem ao mesmo tempo**. É simples de implementar e cria a escolha "estudar ou atacar" no combate.

### 7. Nomes

- **Recomendo:** identificadores internos neutros em inglês (`fire`, `water`, `earth`, `air`, `order`, `entropy`) e todos os nomes exibidos que remetem a outras obras num único arquivo, `locales/pt-BR/names.json`.
- **Durante o desenvolvimento:** nomes latinos (Ignis, Aqua, Terra, Aer, Ordo, Perditio) nesse arquivo.
- **Para uma versão distribuída** (proposta original):

  | Aspecto | Nome próprio |
  | --- | --- |
  | Ignis | Lume |
  | Aqua | Maré |
  | Terra | Barro |
  | Aer | Sopro |
  | Ordo | Prumo |
  | Perditio | Ruína |

- **Escola:** Colégio do Astrolábio (alternativas: Academia da Vela Funda, Escola Vigília).
- **Jogo:** Catálogo do Abismo (alternativas: Lume e Ruína, Aspecta). Até você decidir, uso "Jogo do Mago", o nome do repositório.
- "Focus" também vai para `names.json`; na versão distribuída, "Foco".
- **Inimigo:** Bedel Descarnado (`bone-beadle`), um morto-vivo ligado à escola e fraco a fogo.

### 8. Premissa narrativa

1. **A Escola sobre o Poço.** A escola foi erguida para vigiar um poço sem fundo de onde sobem coisas sem nome. O portal selado pelos fundadores só abre para quem estuda e, por um juramento antigo, devolve ao Salão de Estudos quem morre lá embaixo. Catalogar o que vive no poço é a única forma conhecida de mantê-lo fechado.
2. **As Ruínas da Primeira Escola.** A primeira escola afundou na terra há séculos, com mestres, alunos e biblioteca. A escola atual foi construída por cima, e o portal ancorado no Salão de Estudos é a única passagem estável até as ruínas, onde o saber apodrecido ganhou corpo e os antigos alunos ainda vagam. Cada aspecto recuperado reconstrói um pouco do que se perdeu.
3. **O Laboratório do Fundador.** O fundador quis um laboratório onde tudo pudesse ser medido e criou, do outro lado do portal, um lugar que se reorganiza a cada visita. Ele desapareceu lá dentro, mas o laboratório continua gerando salas, criaturas e matéria para quem tiver coragem de estudar. A escola existe para formar quem o encontre ou termine o trabalho dele.

**Recomendo a 2:** explica o inimigo morto-vivo ligado à escola, dá sentido ao conhecimento permanente ("reconstruir o que se perdeu") e justifica a volta ao Salão de Estudos ao morrer. Neste recorte: uma placa na Sala do Portal e uma linha na tela de morte.

### 9. Prioridade visual

Em 240 linhas de altura nenhum desses efeitos pesa de verdade; o que mais custa é o número de luzes dinâmicas, então o jogo terá um limite de luzes por sala antes de qualquer corte. Se mesmo assim for preciso cortar, **recomendo esta ordem**:

1. **Dithering:** é um passe de tela inteira e a perda estética é pequena.
2. **Mapeamento afim:** para não deformar demais, exige dividir os polígonos grandes em mais vértices; desligado, dá para usar menos vértices.
3. **Resolução interna:** cair para 180 linhas.
4. **Névoa, por último:** é barata e ainda ajuda o desempenho, porque esconde o que está longe e permite não desenhá-lo.

### 10. Seu sistema e computador (seção 8 da especificação)

Qual sistema operacional, processador, placa de vídeo (ou gráfico integrado) e navegador você vai usar para jogar? Serve para calibrar a resolução interna e os efeitos ligados por padrão.

### 11. Referências visuais (seção 4 da especificação)

Se tiver imagens ou descrições da escola de Wakfu e de Lunacid que quer como referência, me envie. Até lá, uso greybox (blocos simples) com o shader PS1.

---

## Plano dos marcos com esta tecnologia

| Marco | O que entra |
| --- | --- |
| M1 | Projeto Vite + TypeScript, renderização em baixa resolução com ampliação nítida, material PS1 (vertex snapping, afim, névoa), passe de cor limitada com dithering, sala de teste descrita em JSON, primeira pessoa com colisão, menu de opções (cada efeito, filtros "Crocante" e "Limpo", resolução interna, sensibilidade; o volume entra no M5, junto com os sons). Testes: gerador com semente, validação de dados, colisão e regra de camadas. Captura de tela no README. |
| M2 | Escola (duas salas), interação, Lente, os seis escaneáveis, Livro de Pesquisa, Mesa com a página única, save com exportar/importar. |
| M3 | Varinha e Focus de Fogo, projétil saindo da ponta, HUD de Ignis, braseiro. |
| M4 | Portal com transição, sala da Dungeon, Bedel Descarnado, morte e saída. |
| M5 | Sons provisórios, balanceamento, README de extensão, publicação opcional em link. |

O M1 depende só da decisão 1. Se você aprovar a proposta, começo por ele.
