# Jogo do Mago

Roguelike dungeon crawler em 3D e primeira pessoa, com visual de PS1 e fantasia sombria. Você é um cientista mágico: escaneia tudo o que encontra para descobrir seus aspectos, estuda na escola de magia e desce à Dungeon por um portal. Ao morrer, volta à escola com o conhecimento intacto.

"Jogo do Mago" é o nome provisório; o nome escolhido para distribuir é *Catálogo do Abismo* (decisão 7).

![Sala de teste com o filtro Crocante](docs/images/m1-sala-de-teste.png)

## Estado

**M1: esqueleto jogável.** Uma sala de teste em primeira pessoa com o visual PS1 e o menu de opções gráficas.

| Documento | Conteúdo |
| --- | --- |
| [`docs/ESPECIFICACAO.md`](docs/ESPECIFICACAO.md) | especificação completa do projeto |
| [`docs/PROPOSTA-M0.md`](docs/PROPOSTA-M0.md) | tecnologia, arquitetura e decisões da seção 9 |
| [`DECISIONS.md`](DECISIONS.md) | registro de todas as decisões |
| [`CREDITS.md`](CREDITS.md) | ferramentas e recursos de terceiros |

## Como executar

1. Baixe o [Godot 4.7.2](https://godotengine.org/download/) (versão padrão, não a .NET). É um executável, sem instalação.
2. Abra o Godot, clique em **Importar** e escolha o arquivo `project.godot` desta pasta. Na primeira vez ele importa as texturas e os textos, o que leva alguns segundos.
3. Aperte **F5** para jogar.

Os executáveis prontos (Windows, Linux, macOS) entram no fim do recorte (M5).

## Controles

| Tecla | Ação |
| --- | --- |
| Clique | prende o mouse na janela e começa a jogar |
| W A S D ou setas | andar |
| Mouse | olhar |
| Shift (segurar) | correr |
| Espaço | pular |
| Esc | pausa e opções (Esc de novo volta) |

## Opções gráficas

No menu de pausa, **Opções**:

- **Filtro visual:** *Crocante* (todos os efeitos, 240 linhas) ou *Limpo* (sem tremor, sem deformação, sem cor limitada, 480 linhas). Mexer em um efeito sozinho muda o filtro para *Personalizado*.
- **Resolução interna:** altura da imagem em que o mundo é desenhado antes de ser ampliado (180, 240, 360 ou 480 linhas).
- **Efeitos**, cada um com liga/desliga: vértices trêmulos (vertex snapping), texturas deformadas (mapeamento afim), névoa, cor limitada e dithering.
- **Sensibilidade do mouse.**

As opções ficam gravadas em `user://settings.cfg`. No Windows, a pasta `user://` é `%APPDATA%\Godot\app_userdata\Jogo do Mago`.

| Crocante | Limpo |
| --- | --- |
| ![Crocante](docs/images/m1-sala-de-teste.png) | ![Limpo](docs/images/m1-filtro-limpo.png) |

## Testes

A lógica do jogo (`scripts/core`) é testada com o [GUT](https://github.com/bitwes/Gut), sem abrir o jogo.

- **No editor:** painel **GUT**, na parte de baixo, botão **Run All**.
- **No terminal**, a partir desta pasta:

  ```sh
  godot --headless --path . --import            # só na primeira vez, ou depois de mudar arquivos fora do editor
  godot --headless --path . -s addons/gut/gut_cmdln.gd
  ```

  (`godot` é o caminho do executável do Godot.)

Os testes cobrem o gerador com semente, as opções (filtros, limites e gravação), o carregamento e a verificação dos dados e a regra de camadas (`scripts/core` não pode usar cena, entrada nem tela).

## Argumentos de desenvolvimento

Depois de `--` na linha de comando:

```sh
godot --path . -- --seed=123                  # semente do gerador aleatório (impressa ao abrir o jogo)
godot --path . -- --room=test_room            # sala inicial
godot --path . -- --screenshot=captura.png    # tira uma captura depois de 30 quadros e fecha
```

## Como o projeto está organizado

```text
data/              conteúdo do jogo, um arquivo .tres por item (editável no inspetor)
  player/          valores de movimento do jogador
  rooms/           salas: identificador, cena e atmosfera (névoa, luz ambiente)
  settings/        opções padrão e filtros visuais (presets/)
locales/           textos da interface (ui.csv: chave e texto em pt_BR)
scenes/            cenas: main, player, salas (rooms/) e interface (ui/)
scripts/
  core/            lógica pura, testável sem abrir o jogo (dados, opções, gerador com semente)
  autoload/        globais: Content (dados carregados) e Settings (opções do jogador)
  game/            jogador, mundo, salas, blocos de greybox, luzes
  render/          shaders PS1 e a tela de baixa resolução
  ui/              HUD e menus
assets/            texturas e materiais
tests/unit/        testes do GUT
tools/             ferramentas (gerar as texturas provisórias)
addons/gut/        GUT, a ferramenta de testes
```

### Como o visual PS1 funciona

- O mundo 3D é desenhado num `SubViewport` pequeno (por exemplo, 427×240), e a `GameScreen` o amplia para a janela sem filtragem: os pixels ficam grandes e nítidos.
- `scripts/render/ps1.gdshader` é o material de todas as superfícies. Ele faz o **vertex snapping** (prende os vértices a uma grade de pixels), o **mapeamento afim** (interpola a textura sem correção de perspectiva) e a **névoa** por distância. A iluminação é calculada por vértice, como no PS1.
- `scripts/render/ps1_post.gdshader` reduz as cores a 5 bits por canal e aplica o **dithering** com uma matriz de Bayer 4×4.
- Os efeitos são ligados e desligados por parâmetros globais de shader (Projeto > Configurações do Projeto > Shader Globals), que o menu de opções altera.

### Montar uma sala no editor

1. Crie uma cena com um `Node3D` raiz e o script `scripts/game/room.gd`.
2. Adicione blocos: nó `StaticBody3D` com o script `scripts/game/greybox_block.gd`. No inspetor, ajuste `size` e escolha um material de `assets/materials/`. A malha e a colisão se ajustam sozinhas.
3. Adicione luzes (`OmniLight3D`; para tremular, use o script `scripts/game/flicker_light.gd`).
4. Adicione pelo menos um `Marker3D` com o script `scripts/game/entrance_point.gd` (`id = default`): é onde o jogador aparece, olhando para a seta azul.
5. Em `data/rooms/`, crie um recurso `RoomData` com o identificador, a cena e a atmosfera.

O guia completo para adicionar aspectos, Focus, inimigos e salas entra no M5.

### Texturas provisórias

As texturas de `assets/textures/` são geradas por código (`tools/generate_textures.gd`), com semente fixa. Para trocá-las por arte própria, substitua o PNG mantendo o nome. Em texturas novas, desative mipmaps e compressão na aba **Importar** (o padrão do projeto já faz isso).
