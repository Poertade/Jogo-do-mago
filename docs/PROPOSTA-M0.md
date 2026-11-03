# M0: proposta técnica

> **Status:** aguardando aprovação. Nenhum código do jogo foi escrito.
> Tecnologia (decisão 1): **Godot 4**. A primeira versão desta proposta usava Three.js no navegador; o usuário pediu um programa de desktop desde o começo, e a proposta foi refeita (registro em `DECISIONS.md`, D001).
> As decisões 2 a 9, o computador de jogo e as referências visuais aguardam resposta (seção (c)).

Especificação completa: [`ESPECIFICACAO.md`](ESPECIFICACAO.md).

---

## (a) Tecnologia

### Opções avaliadas para um programa de desktop

| Critério | **Godot 4 + GDScript** | Three.js + TypeScript em Electron | Unity 6 + C# |
| --- | --- | --- | --- |
| Programa de desktop | Nativo: Windows, Linux e macOS | Navegador embutido num executável (~150 MB, mais memória) | Nativo |
| Visual PS1 | Shader próprio pequeno; técnica conhecida, com exemplos livres; iluminação por vértice disponível | Shader próprio pequeno | Shaders de terceiros (vários pagos) ou próprios |
| Primeira pessoa e colisão | Prontas (`CharacterBody3D` e física embutida) | Escritas por nós | Prontas |
| Desempenho em PC modesto | Leve (renderizador Compatibility, OpenGL 3.3) | Leve | Mais pesado; editor com ~10 GB |
| Testar a lógica sem abrir o jogo | GUT em modo headless (linha de comando) | Vitest | Exige o editor |
| Conteúdo em dados | Resources (`.tres`): texto, com formulário no editor | JSON | ScriptableObjects |
| Editor visual de fases | Excelente; editor com ~80 MB, sem instalação | Não tem | Excelente, porém pesado |
| Save em arquivo | Arquivo real em disco (`user://`) | Arquivo real (via Node) | Arquivo real |
| Licença | MIT, sem conta | MIT, sem conta | Proprietária, exige conta |

### Escolha: Godot 4.7 com GDScript tipado

Motivos, do mais ao menos importante:

1. **É um motor de jogo de verdade para desktop.** Exporta executáveis leves para Windows, Linux e macOS, e o save é um arquivo comum em disco.
2. **Editor visual.** Salas, luzes, pontos de entrada e de spawn são montados e ajustados no editor, sem programar. Os dados (aspectos, varinhas, Focus, inimigos, páginas) aparecem como formulários no inspetor.
3. **Primeira pessoa, colisão, áudio, interface, navegação e animação já vêm prontos**, o que deixa o nosso código menor e mais fácil de estudar.
4. **Visual PS1 simples de fazer.** A técnica é conhecida e há exemplos livres para consultar. O Godot também tem iluminação por vértice, como o PS1 fazia.
5. **GDScript é fácil de ler**, e com tipos (`var vida: int`) o editor aponta erros antes de rodar.

Por que não as outras:

- **Three.js em Electron:** daria um executável, mas com um navegador inteiro embutido e sem editor; colisão e demais sistemas teriam de ser escritos por nós.
- **Unity:** editor pesado, licença com conta, e testes que dependem do editor.

**O que muda no meu trabalho na nuvem.** Os testes de lógica rodam no Godot em modo headless. Para ver o jogo rodando (capturas de tela), o Godot tem de desenhar numa tela virtual com OpenGL por software. O ambiente tem as bibliotecas para isso, mas ainda não confirmei, porque executar o Godot baixado precisa da sua autorização (pergunta 12).

### Renderizador

**Compatibility** (OpenGL 3.3), não Forward+ nem Mobile. É o mais leve e roda em quase qualquer placa de vídeo, inclusive gráficos integrados antigos. Os recursos que ele não tem (iluminação global, névoa volumétrica) não servem para o visual PS1.

O jogo é desenhado numa imagem pequena (padrão: 240 linhas de altura, por exemplo 427×240 em 16:9) e ampliado com pixels nítidos, sem filtragem nem mipmaps. A pergunta 10 (seu sistema e computador) serve para calibrar esses padrões.

### Dependências previstas

Cada uma entra com justificativa em `DECISIONS.md` no marco em que for instalada, com versão fixa.

| Item | Para quê |
| --- | --- |
| Godot 4.7.2 (versão estável mais recente) | motor e editor; exportação para desktop |
| GUT (Godot Unit Test), em `addons/gut` | testes da lógica pela linha de comando |

O shader PS1 é escrito por nós, sem dependência. Projetos livres que servirem de consulta entram em `CREDITS.md`.

### Como você vai rodar o jogo

- **Durante o desenvolvimento:** baixe o Godot 4.7.2 (um executável, sem instalação), abra a pasta do projeto e aperte F5.
- **Como programa:** a partir do M1 o README explica como exportar o executável. No fim do recorte entrego os executáveis prontos para o seu sistema.

---

## (b) Arquitetura em módulos

### Camadas

```text
data/*.tres, locales/*.csv    conteúdo e textos, sem lógica
        │ lidos por
        ▼
scripts/core     lógica pura: aspectos, conhecimento, pesquisa, varinha, magia,
                 combate, IA, save, aleatório com semente
        │ sinais                  ▲ comandos (lançar, escanear, estudar…)
        ▼                         │
scripts/game     nós da cena: jogador, inimigo, projétil, salas, portal, troca de salas
scripts/ui       HUD, Livro de Pesquisa, Mesa, menus
scripts/render   shader PS1, pós-processamento, opções gráficas
```

Regras:

- `scripts/core` só tem classes `RefCounted` e `Resource`: nada de nós, árvore de cena ou entrada. Assim roda nos testes sem abrir o jogo. Um teste falha se essa pasta usar algo proibido.
- `scripts/game` e `scripts/ui` usam o `core` e reagem aos sinais dele.
- Conteúdo (valores, textos, aspectos) só em `data/`, nas cenas de sala e em `locales/`.

### Pastas

```text
project.godot
addons/gut/                 testes (dependência)
data/                       conteúdo: um arquivo .tres por item
  aspects/  fire.tres, water.tres…
  scannables/  candle.tres, water_jug.tres…
  wands/  apprentice_wand.tres
  foci/  fire_focus.tres
  enemies/  bone_beadle.tres
  research/  fire_comprehension.tres
  rooms/  study_hall.tres, portal_room.tres, stone_chamber.tres
locales/
  ui.csv                    textos de interface (chave; pt_BR)
  names.csv                 ÚNICO arquivo com nomes que remetem a outras obras (decisão 7)
scenes/
  rooms/                    uma cena por sala (greybox com blocos CSG)
  player.tscn  enemy.tscn  projectile.tscn  main.tscn
scripts/
  core/
    data/                   o esquema: AspectData, ScannableData, WandData, FocusData,
                            EnemyData, ResearchPageData, RoomData (classes Resource)
    content_db.gd           carrega e valida todo o conteúdo de data/
    rng.gd                  aleatório com semente
    knowledge.gd            aspectos descobertos, alvos escaneados, pontos de pesquisa
    research.gd             páginas: custo, requisitos, estudo
    modifiers.gd            soma dos efeitos permanentes (ex.: +20% de dano de fogo)
    wand_state.gd           reservas por aspecto, eficiência, recarga
    spell_caster.gd         carga, intervalo, custo, dano final
    combat.gd               vida, dano por elemento, fraquezas
    enemy_brain.gd          máquina de estados: parado, perseguindo, atacando
    run_state.gd            estado da incursão (reiniciado ao morrer)
    save_game.gd            formato versionado, migrações, leitura e escrita
  game/
    player.gd  wand_view.gd  scanner.gd  projectile.gd  enemy.gd
    scannable.gd  interactable.gd  portal.gd  recharge_point.gd
    room.gd                 marcadores de entrada, saída e spawn da sala
    world.gd                (autoload) troca de salas, transições, morte → Salão de Estudos
  render/
    ps1.gdshader            vertex snapping, mapeamento afim, névoa
    ps1_post.gdshader       cor limitada e dithering
    graphics_settings.gd    (autoload) liga e desliga cada efeito; filtros; resolução
  ui/
    hud.gd  research_book.gd  research_table.gd  options_menu.gd
tests/
  unit/                     test_knowledge.gd, test_spell_caster.gd, test_save_game.gd…
```

### Um quadro do jogo

1. O jogador (`game/player.gd`) lê a entrada e move o `CharacterBody3D`.
2. Os nós de `game` transformam as ações em comandos para o `core` (por exemplo, `spell_caster.start_charge()` ou `knowledge.register_scan(alvo)`).
3. O `core` atualiza o estado e emite sinais (`aspect_discovered`, `spell_cast`, `enemy_died`, `player_died`).
4. `game` reage no mundo 3D (cria o projétil, abre a saída, troca de sala) e `ui` atualiza o HUD.
5. A cena é desenhada na imagem pequena, com o shader PS1, e ampliada com o pós-processamento.

A física roda em passo fixo, e toda aleatoriedade passa por um gerador com semente (`-- --seed=123` na linha de comando, ou fixa nos testes), para reproduzir erros.

### Salas como módulos

Cada sala é uma cena (`scenes/rooms/*.tscn`) montada no editor, com nós marcadores:

- `EntrancePoint`, com um identificador (por exemplo, `from_portal`);
- `ExitPoint`, com sala e entrada de destino e a condição para abrir (por exemplo, inimigos derrotados);
- `EnemySpawn`, apontando para um `EnemyData`;
- `Portal`, com sala e entrada de destino como dados.

Um `RoomData` (`data/rooms/*.tres`) liga o identificador da sala à cena e guarda a atmosfera (cor e distância da névoa, luz ambiente). Para gerar Dungeons no futuro, um gerador combina cenas de sala pelas entradas e saídas, e o destino do portal passa a apontar para ele.

### Formato dos dados (rascunho; o esquema final sai no M2)

Cada tipo de dado é uma classe `Resource` com campos tipados (`@export`); essa classe é o esquema. Os arquivos `.tres` são texto, e o editor mostra um formulário para cada um. Os identificadores internos são em inglês e neutros; o nome exibido vem de `locales/names.csv` (`ASPECT_FIRE;Ignis`).

| Tipo | Campos |
| --- | --- |
| `AspectData` | `id`, `kind` (primal ou composto), `parents` (dois aspectos, se composto), `color` |
| `ScannableData` | `id`, `aspects` (aspecto → quantidade) |
| `WandData` | `id`, `capacity` (aspecto → reserva máxima), `efficiency` (custo efetivo = custo ÷ eficiência) |
| `FocusData` | `id`, `spell_type` (projétil…), `element`, `cost` (aspecto → quantidade), `charge_time`, `cooldown`, `damage`, dados do projétil (velocidade, raio, cor da luz) |
| `EnemyData` | `id`, `health`, `damage`, `speed`, `sight_range`, `attack_range`, `attack_cooldown`, `aspects`, `weaknesses` (elemento → multiplicador) |
| `ResearchPageData` | `id`, `cost`, `required_pages`, `required_aspects`, `effects` (ex.: multiplicador de dano de fogo 1,2) |
| `RoomData` | `id`, `scene`, atmosfera (névoa, luz ambiente) |

Um conteúdo novo é um arquivo `.tres` novo, criado no editor (botão direito em `data/aspects` → Novo Recurso → `AspectData`), sem mexer no motor. O `content_db.gd` valida tudo ao iniciar (identificadores repetidos, referências quebradas, valores negativos) e mostra mensagens claras.

O save fica em `user://save.json` (no Windows, em `%APPDATA%`), em JSON legível e versionado, só com conhecimento. As opções gráficas ficam em `user://settings.cfg`, separadas.

```json
{
  "format_version": 1,
  "knowledge": {
    "discovered_aspects": ["fire"],
    "scanned_targets": ["candle"],
    "research_points": 1,
    "studied_pages": []
  }
}
```

---

## (c) Decisões em aberto (seção 9 da especificação)

### 1. Tecnologia: decidida

Godot 4.7 com GDScript, conforme (a), a partir da sua escolha por um programa de desktop desde o começo.

### 2. Tipo da magia de fogo

- **Recomendo: projétil com carga curta.** Segurar o botão esquerdo carrega por 0,6 s (a ponta da varinha acende e treme); soltar com a carga completa lança uma bola de fogo que **ilumina o caminho**; soltar antes cancela sem gastar Ignis. O custo é cobrado no disparo. Combina com Lunacid e com o pilar da atmosfera: o próprio fogo é uma das poucas luzes da Dungeon.
- Cone contínuo: gasta Ignis por segundo e combina mal com o tempo de carga da tabela.
- Híbrido: fica para outro Focus. O campo `spell_type` do Focus já permite tipos diferentes.

### 3. Recarga da varinha fora da escola

- **Recomendo: nenhuma; reserva finita por incursão.** Com os valores iniciais, 30 de Ignis dão 6 disparos e o inimigo morre com 2 acertos (15 × 1,5 = 22,5). Há folga agora, e isso vira tensão quando houver várias salas.
- Fontes de energia na Dungeon podem entrar depois como recompensa rara: o ponto de recarga será uma cena reutilizável que qualquer sala pode usar.
- Recarga lenta e contínua: tira a tensão de roguelike.

### 4. Morte

- **Recomendo: renascer no Salão de Estudos** com vida e reserva cheias, perdendo o que foi coletado na incursão (ainda não há itens).
- O conhecimento é salvo **no momento da descoberta**, não ao voltar: escanear o inimigo e morrer logo depois mantém a descoberta.
- Renascer na Sala do Portal deixaria a volta mais rápida, mas afastaria o jogador da Mesa e do braseiro.

### 5. Como o estudo vira poder

- **Recomendo: árvore leve.** Páginas com pré-requisitos (outras páginas e aspectos descobertos). Neste recorte existe só uma página; os campos de requisitos já existem nos dados, então a árvore cresce sem mudar código.
- A combinação de aspectos para descobrir compostos entra depois como uma das formas de liberar páginas, no espírito de Thaumcraft.

### 6. Instrumento de escaneamento

- **Recomendo:** **Lente Taxonômica** (nome provisório; alternativas: Monóculo de Aferição, Prisma Analítico). Uma lente de latão com aro graduado, na **mão esquerda**. Ao segurar o botão direito, ela sobe na frente da câmera e o aro se enche como barra de progresso.
- Não ocupa a mão da varinha, mas **escanear e lançar magia não acontecem ao mesmo tempo**. É simples de implementar e cria a escolha "estudar ou atacar" no combate.

### 7. Nomes

- **Recomendo:** identificadores internos neutros em inglês (`fire`, `water`, `earth`, `air`, `order`, `entropy`) e todos os nomes exibidos que remetem a outras obras num único arquivo, `locales/names.csv`.
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
- "Focus" também vai para `names.csv`; na versão distribuída, "Foco".
- **Inimigo:** Bedel Descarnado (`bone_beadle`), um morto-vivo ligado à escola e fraco a fogo.

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

Qual sistema operacional, processador e placa de vídeo (ou gráfico integrado) você vai usar para jogar? Serve para calibrar a resolução interna e os efeitos ligados por padrão, e para saber para qual sistema exportar primeiro.

### 11. Referências visuais (seção 4 da especificação)

Se tiver imagens ou descrições da escola de Wakfu e de Lunacid que quer como referência, me envie. Até lá, uso greybox (blocos simples) com o shader PS1.

### 12. Executar o Godot no ambiente de desenvolvimento

Para rodar os testes e tirar capturas de tela a cada marco, preciso executar aqui na nuvem o Godot 4.7.2 oficial, baixado de `github.com/godotengine/godot`. A primeira tentativa foi bloqueada pela regra de segurança do ambiente, que não deixa executar programas baixados sem a sua autorização. **Você autoriza?** Sem isso, eu escrevo o código mas não consigo testá-lo aqui; os testes e a conferência visual ficariam com você.

---

## Plano dos marcos com esta tecnologia

| Marco | O que entra |
| --- | --- |
| M1 | Projeto Godot no renderizador Compatibility, imagem de 240 linhas ampliada com pixels nítidos, shader PS1 (vertex snapping, afim, névoa), pós-processamento de cor limitada com dithering, sala de teste em greybox, primeira pessoa com colisão, menu de opções (cada efeito, filtros "Crocante" e "Limpo", resolução interna, sensibilidade; o volume entra no M5, junto com os sons). GUT instalado, com testes do gerador com semente e da regra de camadas. Captura de tela no README. |
| M2 | Escola (duas salas), interação, Lente, os seis escaneáveis, Livro de Pesquisa, Mesa com a página única, save em `user://save.json`. |
| M3 | Varinha e Focus de Fogo, projétil saindo da ponta, HUD de Ignis, braseiro. |
| M4 | Portal com transição, sala da Dungeon, Bedel Descarnado, morte e saída. |
| M5 | Sons provisórios, balanceamento, README de extensão, executáveis exportados. |

O M1 depende só da decisão 1 e da autorização da pergunta 12. Se você aprovar a proposta, começo por ele.
