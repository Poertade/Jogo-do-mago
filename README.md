# Jogo do Mago

Roguelike dungeon crawler em 3D e primeira pessoa, com visual de PS1 e fantasia sombria. Você é um cientista mágico: escaneia tudo o que encontra para descobrir seus aspectos, estuda na escola de magia e desce à Dungeon por um portal. Ao morrer, volta à escola com o conhecimento intacto.

"Jogo do Mago" é o nome provisório; o nome escolhido para distribuir é *Catálogo do Abismo* (decisão 7).

![Bola de fogo acertando o Bedel Descarnado na Dungeon](docs/images/bedel-combate.png)

![Mesa de Pesquisa: aspectos e combinação à esquerda, nota de pesquisa resolvida no pergaminho à direita](docs/images/mesa-de-pesquisa.png)

| Livro de Pesquisa | Nódulo de Vis | Conhecimento insuficiente |
| --- | --- | --- |
| ![Livro](docs/images/livro-de-pesquisa.png) | ![Nódulo](docs/images/nodulo-de-vis.png) | ![Bloqueado](docs/images/escaneamento-bloqueado.png) |

## Estado

**M5: primeiro recorte completo.** O ciclo inteiro funciona:

1. Na escola, você escaneia objetos, estuda e recarrega a varinha.
2. Atravessa o portal e enfrenta o Bedel Descarnado na Dungeon.
3. Vencendo, volta à escola pela saída; morrendo, desperta no Salão de Estudos sem perder o conhecimento.

Depois do M5, a pesquisa passou a seguir o Thaumcraft 4. Agora:
- Tudo é escaneável, e os aspectos compostos são descobertos na Mesa de Pesquisa, combinando os dois pais.
- O braseiro virou um Nódulo de Vis.
- O Bedel Descarnado ganhou um corpo articulado e animado.
- As páginas de pesquisa são estudadas resolvendo **notas de pesquisa**: uma grade de hexágonos no pergaminho da Mesa.
- A varinha guarda uma **reserva única de Vis**, de onde saem todas as magias.
- Os menus parecem **pergaminho** (com moldura de madeira na Mesa) e cada aspecto tem um **ícone**.

| Documento | Conteúdo |
| --- | --- |
| [`docs/ESPECIFICACAO.md`](docs/ESPECIFICACAO.md) | especificação completa do projeto |
| [`docs/PROPOSTA-M0.md`](docs/PROPOSTA-M0.md) | tecnologia, arquitetura e decisões da seção 9 |
| [`docs/REFERENCIAS-VISUAIS.md`](docs/REFERENCIAS-VISUAIS.md) | direção de arte, paleta e inimigos (Lunacid) |
| [`docs/REFERENCIAS-THAUMCRAFT.md`](docs/REFERENCIAS-THAUMCRAFT.md) | mecânicas do Thaumcraft 3 e 4 usadas como base, e as que podem entrar depois |
| [`DECISIONS.md`](DECISIONS.md) | registro de todas as decisões |
| [`CREDITS.md`](CREDITS.md) | ferramentas e recursos de terceiros |

## Como executar

**Pelo editor** (para jogar e modificar):

1. Baixe o [Godot 4.7.2](https://godotengine.org/download/) (versão padrão, não a .NET). É um executável, sem instalação.
2. Abra o Godot, clique em **Importar** e escolha o arquivo `project.godot` desta pasta. Na primeira vez ele importa texturas, sons e textos, o que leva alguns segundos.
3. Aperte **F5**.

**Como programa:** veja [Exportar executáveis](#exportar-executáveis).

## Controles

| Tecla | Ação |
| --- | --- |
| Clique | prende o mouse na janela e começa a jogar |
| W A S D ou setas | andar |
| Mouse | olhar |
| Shift (segurar) | correr |
| Espaço | pular |
| Botão esquerdo (segurar e soltar) | carregar e lançar a magia de fogo |
| Botão direito (segurar) | escanear com a Lente Taxonômica |
| E | interagir (Mesa, ler, atravessar o portal, sair) |
| E (segurar) | drenar Vis do Nódulo para a varinha |
| Tab | Livro de Pesquisa |
| Esc | pausa e opções; fecha qualquer tela |

## Como se joga

**Pesquisa (escola), no estilo do Thaumcraft 4:**
1. Você começa no **Salão de Estudos**. Tudo pode ser escaneado: objetos, paredes, piso, estantes, a janela, o portal, o inimigo. Mire e **segure o botão direito**: a Lente sobe e a barra enche em 1,5 s.
2. O primeiro escaneamento de cada coisa rende **pontos de pesquisa de cada aspecto** dela: 2 por unidade, então a vela (Ignis 3) rende 6 de Ignis. Escanear de novo não rende nada, mas mirar algo já escaneado mostra seus aspectos.
3. Aspectos **primais** (Ignis, Aqua, Terra, Aer, Ordo, Perditio) são descobertos escaneando. Os seis objetos iniciais da escola só têm primais.
4. Aspectos **compostos** só se descobrem na **Mesa de Pesquisa** (E), combinando os dois pais. Por exemplo, Aqua + Terra dá Victus, e cada combinação gasta 1 ponto de cada pai e rende 1 do composto. Quem tem um composto ainda desconhecido não pode ser escaneado: a Lente avisa "conhecimento insuficiente" e mostra "?" no que falta. Para as tábuas do piso (Arbor), por exemplo, é preciso descobrir Victus, depois Herba, depois Arbor.
5. **A Mesa**, no estilo do Thaumcraft 4:
   - **À esquerda**, a grade com os aspectos que você conhece e quantos pontos tem de cada. Clique num para escolhê-lo.
   - **Combinar:** com um aspecto escolhido, clique num dos dois espaços de baixo para colocá-lo (botão direito esvazia). O terceiro espaço mostra o resultado ("?" se ainda não foi descoberto, "×" se os dois não formam nada). **Combinar** gasta os pontos.
   - **À direita**, no pergaminho, a **nota de pesquisa** da página escolhida (abas no alto): uma grade de hexágonos com alguns aspectos já marcados. Escolha um aspecto e clique num círculo vazio para escrevê-lo (1 ponto dele); o botão direito apaga e devolve o ponto.
   - Dois vizinhos **se ligam** (linha roxa) quando um é parte do outro: Ignis liga com Potentia (Ordo + Ignis) e com Lux (Aer + Ignis), mas Ignis não liga com Ignis nem com Ordo. Quando todos os aspectos marcados estão ligados, a página é estudada na hora e a solução fica no pergaminho.
6. **Compreensão de Ignis** marca Ignis, Potentia e Lux: descubra Potentia e Lux na Mesa, ligue os três e o dano de fogo sobe 20%, para sempre.
7. O **Livro de Pesquisa** (Tab) lista aspectos (com ícone, pontos e receita), alvos escaneados e páginas estudadas.

**Magia:**
8. Segure o botão esquerdo por 0,6 s (a ponta da varinha acende e treme) e solte para lançar a bola de fogo. Soltar antes cancela sem gastar nada.
9. A varinha guarda **uma reserva única de Vis** (30, a barra roxa do HUD), e cada disparo gasta 5. No **Nódulo de Vis** do Salão (as bolinhas laranja), segure E: o Vis voa até a varinha e enche a reserva. Fora da escola não há recarga.
10. A Lente e a varinha não funcionam ao mesmo tempo: ou você estuda, ou você ataca.

**Dungeon:**
11. O corredor ao norte leva à **Sala do Portal**. A placa de bronze (E) conta por que a escola e o portal existem.
12. O **portal** (E) leva à câmara de pedra, onde o **Bedel Descarnado** espera.
   - Ele é lento e persegue quando vê você.
   - Antes de golpear, ergue o braço com um sopro: recue para esquivar.
   - É fraco a fogo: três disparos o derrubam, ou dois com a página estudada.
   - Pode ser escaneado depois que você descobrir Mortuus e Exanimis na Mesa.
13. Vencer abre a grade ao norte. **Voltar à escola** (E) leva à Sala do Portal e restaura a vida; o Vis só volta no Nódulo de Vis.
14. Se a vida chegar a zero, você desperta no Salão de Estudos com vida e Vis cheios. O conhecimento (aspectos, pontos, escaneamentos, notas e páginas) continua.

O conhecimento é gravado em `user://save.json`, um JSON legível, a cada descoberta. Para começar do zero, apague esse arquivo. A pasta `user://` fica em:
- **Windows:** `%APPDATA%\Godot\app_userdata\Jogo do Mago`
- **Linux:** `~/.local/share/godot/app_userdata/Jogo do Mago`

## Opções

No menu de pausa, **Opções**:

- **Filtro visual:** *Crocante* (todos os efeitos, 240 linhas) ou *Limpo* (sem tremor, sem deformação, sem cor limitada, 480 linhas). Mexer num efeito sozinho muda o filtro para *Personalizado*.
- **Resolução interna:** altura da imagem em que o mundo é desenhado antes de ser ampliado (180, 240, 360 ou 480 linhas).
- **Efeitos**, cada um com liga/desliga: vértices trêmulos (vertex snapping), texturas deformadas (mapeamento afim), névoa, cor limitada e dithering.
- **Sensibilidade do mouse** e **volume**.

As opções ficam em `user://settings.cfg`.

| Crocante | Limpo |
| --- | --- |
| ![Crocante](docs/images/m1-sala-de-teste.png) | ![Limpo](docs/images/m1-filtro-limpo.png) |

## Testes

A lógica do jogo (`scripts/core`) é testada com o [GUT](https://github.com/bitwes/Gut), sem abrir o jogo.

- **No editor:** painel **GUT**, na parte de baixo, botão **Run All**.
- **No terminal**, a partir desta pasta (`godot` é o caminho do executável do Godot):

  ```sh
  godot --headless --path . --import            # na primeira vez, ou depois de mudar arquivos fora do editor
  godot --headless --path . -s addons/gut/gut_cmdln.gd
  ```

**O que os testes cobrem:**
- **Pesquisa:** escaneamento bloqueado por composto desconhecido, pontos por aspecto, combinação na Mesa, notas de pesquisa (grade, ligações, escrever e apagar, nota completa), estudo de páginas, andamento do escaneamento, efeitos das páginas, economia da pesquisa (tudo pode ser escaneado com os pontos disponíveis).
- **Magia:** reserva única de Vis, custo, carga, intervalo e recarga da magia, eficiência da varinha, dano com páginas e fraquezas, vida, reinício da incursão.
- **Inimigo:** IA (estados, esquiva, intervalo, reação ao dano, morte).
- **Sistema:** persistência (save), gerador com semente, opções.
- **Dados:** carregamento e verificação de todo o conteúdo, inclusive os valores da especificação e o balanceamento.
- **Arquitetura:** a regra de camadas e os arquivos de cena (parâmetros de shader com casa decimal).

## Ferramentas

| Comando | O que faz |
| --- | --- |
| `godot --headless --path . -s tools/balance_report.gd` | relatório de balanceamento: disparos por reserva, acertos para derrubar cada inimigo (com e sem páginas), golpes para derrubar o jogador, pontos de pesquisa |
| `godot --headless --path . -s tools/generate_textures.gd` | gera de novo as texturas provisórias |
| `godot --headless --path . -s tools/generate_sounds.gd` | gera de novo os sons provisórios |
| `godot --headless --path . -s tools/generate_icons.gd` | gera de novo os ícones dos aspectos (`assets/icons/aspects/`) |
| `godot --headless --path . -s tools/generate_ui_theme.gd` | gera de novo o pergaminho, a moldura de madeira e o tema dos menus (`assets/ui/`); rode duas vezes, com `--import` no meio, para o tema usar as texturas novas |
| `godot --path . -- --seed=123` | escolhe a semente do gerador aleatório (impressa ao abrir o jogo) |
| `godot --path . -- --room=stone_chamber` | começa direto numa sala (`school` é o padrão; `test_room` é a sala do M1) |
| `godot --path . -- --screenshot=captura.png` | tira uma captura depois de 30 quadros e fecha |

## Como o projeto está organizado

```text
data/              conteúdo do jogo, um arquivo .tres por item (editável no inspetor do Godot)
  aspects/         aspectos (primais; compostos têm dois pais)
  scannables/      objetos escaneáveis e seus aspectos
  enemies/         inimigos (também escaneáveis)
  wands/  foci/    varinhas e Focus
  research/        regras de escaneamento e pontos (rules.tres) e páginas (pages/)
  player/          vida, equipamento inicial e movimento do jogador
  rooms/           salas: identificador, cena, atmosfera e som de ambiente
  settings/        opções padrão e filtros visuais (presets/)
  audio/           banco de sons: qual arquivo toca em cada evento
locales/           textos: ui.csv (interface), content.csv (conteúdo), names.csv (nomes de outras obras)
scenes/            cenas: main, player, salas (rooms/), objetos (props/), inimigos, efeitos e interface (ui/)
scripts/
  core/            lógica pura, testável sem abrir o jogo: conhecimento, pesquisa, magia, combate, IA, save…
  autoload/        globais: Content (dados), Settings (opções), Game (conhecimento, incursão) e Audio (sons)
  game/            nós do mundo: jogador, Lente, varinha, projétil, inimigo, salas, portal, saída…
  render/          shaders PS1 e a tela de baixa resolução
  ui/              HUD e telas (pausa, opções, Livro, Mesa, leitura)
assets/            texturas, materiais, sons, ícones dos aspectos (icons/), tema dos menus (ui/) e fonte (fonts/)
tests/unit/        testes do GUT
tools/             ferramentas (texturas, sons, ícones, tema, relatório de balanceamento)
addons/gut/        GUT, a ferramenta de testes
```

**Regra de camadas:** `scripts/core` só tem classes `RefCounted` e `Resource`, sem nós, cena, entrada ou tela; o teste `test_core_purity.gd` garante isso. O resto do jogo usa o núcleo e reage aos sinais dele. Todo valor e todo texto ficam em `data/`, nas cenas de sala e em `locales/`, nunca fixos no código.

## Como estender o jogo (sem mexer no motor)

Tudo abaixo é feito no editor do Godot (ou editando os arquivos de texto) e não exige programar.

**Antes de começar:**
- **Duplicar é o caminho mais curto:** no painel **Sistema de Arquivos**, clique com o botão direito num arquivo existente → **Duplicar…**, e depois edite a cópia no **Inspetor**.
- **Identificadores (`id`):** em inglês, sem espaços, únicos no tipo. Objetos e inimigos dividem o mesmo espaço de identificadores.
- **Textos novos:** acrescente uma linha `CHAVE,texto` no CSV indicado. O Godot reimporta ao salvar.
- **Para conferir:** rode os testes (painel GUT → **Run All**). O teste `test_real_content_loads_without_errors` aponta em português qualquer erro: identificador repetido, aspecto inexistente, cena faltando, valor zerado. Ao abrir o jogo, os mesmos erros aparecem no painel **Saída**.

### Adicionar um aspecto

1. Duplique `data/aspects/light.tres` como, por exemplo, `data/aspects/darkness.tres`.
2. No Inspetor, preencha:

   | Campo | Valor |
   | --- | --- |
   | `id` | `darkness` |
   | `name_key` | `ASPECT_DARKNESS` |
   | `meaning_key` | `ASPECT_DARKNESS_MEANING` |
   | `color` | a cor do aspecto |
   | `icon` | o ícone (16×16, em `assets/icons/aspects/`) |
   | `kind` | `primal` (básico) ou `compound` (composto) |
   | `parents` | os dois aspectos pais, se composto (ex.: `void` e `light`) |

3. **Ícone:** desenhe um PNG de 16×16 em `assets/icons/aspects/darkness.png` e escolha-o em `icon`. Sem desenho próprio, `tools/generate_icons.gd` gera uma bolinha na cor do aspecto (ou um símbolo, se você escrever a função `_glyph_darkness` nele).
4. Em `locales/names.csv`, acrescente o nome: `ASPECT_DARKNESS,Tenebrae`. Em `locales/content.csv`, o significado: `ASPECT_DARKNESS_MEANING,escuridão`.
5. Para que ele apareça no jogo, coloque-o nos aspectos de um objeto ou inimigo (próximas seções).
   - **Composto:** a Mesa de Pesquisa passa a oferecer a combinação dos pais sozinha. Tudo o que o contém só pode ser escaneado depois dessa descoberta.
   - **Primal:** é descoberto escaneando.
6. Rode os testes. O `test_research_economy.gd` confere se há pontos suficientes no jogo para descobrir tudo; se falhar, acrescente objetos que rendam os aspectos que faltam.

### Adicionar um objeto escaneável

1. Duplique `data/scannables/candle.tres` (ex.: `lantern.tres`). Preencha `id` (`lantern`), `name_key` (`OBJ_LANTERN`) e `aspects` (aspecto → quantidade, ex.: `light` = 2, `fire` = 1).
2. Em `locales/content.csv`: `OBJ_LANTERN,Lanterna`.
3. Para colocá-lo numa sala, duplique `scenes/props/candle.tscn` e, no nó raiz, troque `data` pelo novo `.tres`. Ajuste as malhas como quiser, mantendo uma `CollisionShape3D` (é ela que recebe a mira). Depois arraste a cena para a sala.

### Adicionar um inimigo

1. Duplique `data/enemies/bone_beadle.tres` (ex.: `ash_wraith.tres`) e preencha:

   | Grupo | Campos |
   | --- | --- |
   | Identificação | `id` (`ash_wraith`), `name_key` (`ENEMY_ASH_WRAITH`) |
   | Escaneamento | `aspects`: o que a Lente revela |
   | Combate | `max_health`, `damage`, `weaknesses` (elemento → multiplicador, ex.: `water` = 2.0) |
   | Comportamento | `move_speed`, `sight_range`, `attack_range`, `attack_windup`, `attack_cooldown`, `hurt_stun` |
   | Aparência | `scene_path` (pode ser a mesma cena do Bedel) |

2. Em `locales/content.csv`: `ENEMY_ASH_WRAITH,Espectro de Cinzas`.
3. Para colocá-lo numa sala, abra a cena da sala (ex.: `scenes/rooms/stone_chamber.tscn`):
   - Adicione um `Marker3D`, anexe o script `scripts/game/enemy_spawn.gd` e, em `enemy`, escolha o novo `.tres`.
   - A seta azul indica para onde ele começa olhando.
   - A sala conta os inimigos sozinha: a saída só abre quando todos caem.
4. **Aparência própria (opcional):** duplique `scenes/enemies/bone_beadle.tscn` e troque as peças (malhas) e os materiais.
   - **O que manter:** o script `Enemy` na raiz e o nó `Rig` (script `EnemyRig`), com as juntas `Hips`, `Hips/ThighL/KneeL`, `Hips/ThighR/KneeR`, `Hips/Spine`, `Hips/Spine/Neck/Head` (com `Jaw` e `Eyes`) e `Hips/Spine/ShoulderL/ElbowL` e `ShoulderR/ElbowR`. As peças são filhas das juntas; a animação só gira as juntas.
   - **Ajustes no Inspetor do `Rig`:** `hunch_degrees` (corcunda), `stride_degrees` (passada), `hip_height` e `animation_fps`.
   - Aponte `scene_path` para a cópia.
5. Rode os testes e `tools/balance_report.gd`, que mostra quantos disparos o novo inimigo aguenta.

### Tornar algo escaneável

Tudo no jogo deve ter dados de escaneamento (`data/scannables/`):

| O que é | Onde ficam os dados |
| --- | --- |
| Blocos de sala (`GreyboxBlock`) | campo `scannable` |
| Objetos interagíveis (mesa, portal, placa, nódulo) | campo `scannable` do nó raiz |
| Objeto de uma peça (vela, jarro) | raiz com o script `scannable_prop.gd` (campo `data`) |
| Objeto feito de vários blocos (estante) | raiz com o script `scannable_group.gd`, deixando o `scannable` dos blocos vazio |
| Decoração fina, sem colisão própria (janela, círculo no chão) | `StaticBody3D` com `scannable_prop.gd` na **camada 2** de colisão: a mira enxerga, o jogador atravessa |

Ao escanear, a busca sobe dos blocos até o primeiro nó que tenha dados.

### Adicionar um Focus

1. Duplique `data/foci/fire_focus.tres`. Mude `id`, `name_key`, `element`, `cost`, `charge_time`, `cooldown`, `damage` e os valores do projétil (velocidade, duração, cor e força da luz).
2. Para equipá-lo, abra `data/player/player.tres` e troque `starting_focus`. Neste recorte não há troca de Focus durante o jogo.
3. `cost` é quanto Vis cada disparo gasta da reserva única da varinha. A varinha precisa guardar pelo menos isso (`capacity` em `data/wands/`); os testes avisam se não guardar.

O único `spell_type` existente é `projectile`. Um tipo novo de magia (cone, raio…) é código novo no motor.

### Adicionar uma varinha

Duplique `data/wands/apprentice_wand.tres`, ajuste `capacity` (reserva máxima de Vis) e `efficiency` (o custo é dividido por ela) e equipe-a em `data/player/player.tres` (`starting_wand`).

### Adicionar uma página de pesquisa

1. Duplique `data/research/pages/fire_comprehension.tres`. Preencha `id`, `name_key` e `description_key`.
2. Monte a **nota de pesquisa**:
   - `note_aspects`: os aspectos já marcados na nota (pelo menos dois). Eles ficam espalhados pela borda da grade. Escolha aspectos que dê para ligar por parentesco: um primal e um composto dele ligam direto; dois primais precisam de compostos no meio.
   - `note_radius`: o tamanho da grade (1 = 7 hexágonos, 2 = 19, 3 = 37). Grade maior pede correntes mais longas, isto é, mais pontos.
   - O teste `test_research_economy.gd` resolve cada nota com os pontos do jogo e avisa se alguma for impossível.
3. Preencha os requisitos: `required_pages` (outras páginas) e `required_aspects`. É isso que forma a árvore de pesquisa.
4. Preencha `effects`. Hoje existe o efeito `damage_multiplier`: `element` e `value`, por exemplo 1.2 para +20%.
5. Textos em `locales/content.csv`. Nos textos, `{fire}` vira o nome do aspecto. A Mesa de Pesquisa mostra a página sozinha, numa aba nova.

### Adicionar uma sala da Dungeon

1. Duplique `scenes/rooms/stone_chamber.tscn` (ou crie uma cena com raiz `Node3D` e o script `scripts/game/room.gd`) e monte a sala:

   | Elemento | Como montar |
   | --- | --- |
   | Paredes, chão, teto | nós `StaticBody3D` com o script `scripts/game/greybox_block.gd`; ajuste `size` e escolha um material de `assets/materials/`. A malha e a colisão se refazem sozinhas. |
   | Luzes | `OmniLight3D`; o script `flicker_light.gd` faz tremular |
   | Entradas | `Marker3D` com `entrance_point.gd` e um `id` (ex.: `from_portal`) |
   | Inimigos | `Marker3D` com `enemy_spawn.gd` |
   | Saída | `Node3D` com `exit_point.gd`: destino em `target_room` e `target_entrance`; `requires_clear` para só abrir depois da vitória; `barrier` aponta para a grade que afunda |

2. Crie o recurso da sala: duplique `data/rooms/stone_chamber.tres`, mude `id` e `scene_path`, e ajuste a atmosfera (cor e distâncias da névoa, luz ambiente) e o som de `ambience`.
3. Ligue a sala ao portal: abra `scenes/rooms/school.tscn`, selecione `PortalRoom/Portal` e mude `target_room` e `target_entrance`.
4. Teste direto: `godot --path . -- --room=<id da sala>`.

### Trocar textos, nomes, sons e texturas

- **Textos:** `locales/ui.csv` (interface) e `locales/content.csv` (conteúdo).
- **Nomes que remetem a outras obras:** só em `locales/names.csv`. Para uma versão distribuída, troque pelos nomes próprios da decisão 7 (Lume, Maré, Barro, Sopro, Prumo, Ruína; "Foco" no lugar de "Focus").
- **Sons:** substitua o arquivo em `assets/sounds/` mantendo o nome, ou aponte o evento para outro arquivo em `data/audio/sound_bank.tres`, onde também fica o volume de cada som. Sons que repetem precisam de **Loop Mode: Forward** na aba Importar.
- **Menus:** a aparência de pergaminho fica em `assets/ui/parchment_theme.tres` (abrir no editor mostra o editor de temas) e nas texturas `parchment.png` e `wood_frame.png`. A fonte é a Pixelify Sans (`assets/fonts/`). Variações do tema: `WoodPanel` (moldura de madeira), `WoodLabel` (texto claro sobre madeira) e `TitleLabel` (títulos em tinta vermelha).
- **Ícones dos aspectos:** substitua o PNG em `assets/icons/aspects/` mantendo o nome (16×16).
- **Texturas:** substitua o PNG em `assets/textures/` mantendo o nome. Texturas novas já entram sem mipmaps e sem compressão (padrão do projeto). Mantenha-as pequenas (32×32 ou 64×64) para o visual PS1.

## Exportar executáveis

1. No Godot: **Editor → Gerenciar Modelos de Exportação → Baixar e Instalar** (uma vez).
2. **Projeto → Exportar…**: os perfis *Windows Desktop* e *Linux* já estão configurados, sem os testes, as ferramentas e os documentos. Escolha um e clique em **Exportar Projeto**.

Pelo terminal:

```sh
godot --headless --path . --export-release "Windows Desktop" export/windows/JogoDoMago.exe
godot --headless --path . --export-release "Linux" export/linux/JogoDoMago.x86_64
```

O executável já leva o jogo dentro (um arquivo só). A pasta `export/` fica fora do git.

## Como o visual PS1 funciona

- O mundo 3D é desenhado num `SubViewport` pequeno (por exemplo, 427×240), e a `GameScreen` o amplia para a janela sem filtragem: os pixels ficam grandes e nítidos.
- `scripts/render/ps1.gdshader` é o material de todas as superfícies. Ele faz:
  - o **vertex snapping**, que prende os vértices a uma grade de pixels;
  - o **mapeamento afim**, que interpola a textura sem correção de perspectiva;
  - a **névoa** por distância;
  - o **brilho próprio** de chamas, cristais e portal.

  A iluminação é calculada por vértice, como no PS1.
- `scripts/render/ps1_cutout.gdshader` é a mesma coisa com **recorte**: pixels transparentes da textura somem (pano rasgado, o rosto da caveira). O código comum aos dois fica em `ps1_common.gdshaderinc`.
- `scripts/render/ps1_post.gdshader` reduz as cores a 5 bits por canal, aplica o **dithering** com uma matriz de Bayer 4×4 e faz a transição entre salas, que dissolve os pixels na ordem da mesma matriz.
- Os efeitos são ligados e desligados por parâmetros globais de shader (**Projeto → Configurações do Projeto → Shader Globals**), que o menu de opções altera.
