# Decisões

Registro de cada decisão do projeto: data, escolha, alternativa descartada e motivo.
Detalhes e comparações completas em [`docs/PROPOSTA-M0.md`](docs/PROPOSTA-M0.md).

## Tomadas

### D001 · 2026-11-03 · Tecnologia: Godot 4.7 com GDScript, programa de desktop

- **Escolha:** Godot 4.7.2 (versão estável mais recente), GDScript com tipos, exportação para desktop.
- **Histórico:** a primeira proposta (mesmo dia) era Three.js + TypeScript no navegador, escolhida porque deixa o Claude Code ver o jogo rodando na nuvem. O usuário pediu **um programa de desktop desde o começo**, e a proposta foi refeita.
- **Descartadas:**
  - Three.js + TypeScript em Electron: daria um executável, mas com um navegador inteiro embutido (~150 MB) e sem editor; colisão e demais sistemas de motor seriam escritos por nós.
  - Unity + C#: editor pesado, licença com conta, testes que dependem do editor.
- **Motivo:** motor de jogo nativo para desktop, com editor visual, primeira pessoa, física, áudio e interface prontos, save em arquivo real e testes de lógica pela linha de comando (GUT).
- **Custo aceito:** a conferência visual na nuvem depende de rodar o Godot numa tela virtual com OpenGL por software, ainda não confirmada (pergunta 12 da proposta).

### D002 · 2026-11-03 · Renderizador: Compatibility

- **Escolha:** renderizador Compatibility (OpenGL 3.3), desenhando numa imagem de baixa resolução (padrão de 240 linhas) ampliada sem filtragem.
- **Descartados:** Forward+ e Mobile (Vulkan), mais pesados e com recursos que o visual PS1 não usa.
- **Motivo:** roda em quase qualquer placa de vídeo, inclusive gráficos integrados antigos. Os padrões serão calibrados quando o usuário informar o computador de jogo.

### D003 · 2026-11-03 · Save em `user://save.json`

- **Escolha:** save em JSON legível e versionado (`format_version`) no diretório de dados do usuário do Godot; opções gráficas separadas em `user://settings.cfg`.
- **Descartado:** save em `.tres` (formato do Godot), menos legível e capaz de carregar scripts, o que é arriscado num arquivo que o jogador pode editar.
- **Motivo:** a especificação pede arquivo local legível com número de versão.

### D004 · 2026-11-03 · Conteúdo em Resources do Godot (`.tres`)

- **Escolha:** cada tipo de conteúdo é uma classe `Resource` com campos tipados (o esquema), e cada item é um arquivo `.tres` em `data/`. Um `content_db.gd` valida tudo ao iniciar.
- **Descartado:** JSON para o conteúdo, que exigiria um validador escrito à mão e não teria formulário no editor.
- **Motivo:** o editor mostra cada item como formulário, os tipos são checados e as referências entre itens não quebram por erro de digitação. Os `.tres` continuam sendo texto, legíveis no git.

### D005 · 2026-11-03 · Física e colisão do próprio Godot

- **Escolha:** `CharacterBody3D` para o jogador e o inimigo; blocos CSG com colisão para o greybox das salas; raios para mira e escaneamento.
- **Descartada:** colisão escrita por nós.
- **Motivo:** já vem pronta e testada no motor.

### D006 · 2026-11-03 · Interface com os nós de UI do Godot

- **Escolha:** HUD, Livro de Pesquisa, Mesa e menus com nós `Control`, textos traduzidos por `tr()` a partir de `locales/*.csv`.
- **Descartada:** interface desenhada dentro da cena 3D.
- **Motivo:** sistema de interface e de tradução embutidos; trocar textos vira editar uma planilha CSV.

### D007 · 2026-11-03 · Camadas `core`, `game`, `ui` e `render`

- **Escolha:** `scripts/core` só tem `RefCounted` e `Resource`, sem nós nem árvore de cena; `game`, `ui` e `render` ligam a lógica ao mundo. Um teste falha se `core` usar algo proibido.
- **Descartada:** lógica dentro dos scripts dos nós.
- **Motivo:** a especificação exige lógica testável sem abrir o jogo.

### D008 · 2026-11-03 · Identificadores neutros; nomes exibidos em arquivo de tradução

- **Escolha:** identificadores internos em inglês e neutros (`fire`, `water`…); todo nome exibido vem de `locales/`, e os que remetem a outras obras ficam só em `locales/names.csv`.
- **Descartada:** usar os nomes latinos como identificadores.
- **Motivo:** trocar os nomes para uma versão distribuída vira a troca de um arquivo. A escolha dos nomes em si é a decisão 7, ainda pendente.

### D009 · 2026-11-03 · Dependências previstas

- **Escolha:** Godot 4.7.2 e GUT (Godot Unit Test) em `addons/gut`, com versões fixas, instalados no M1. Shader PS1 escrito por nós.
- **Descartados:** gdUnit4 (mais recursos do que o recorte precisa) e shaders PS1 prontos de terceiros (o nosso fica menor, comentado em português e com cada efeito ligável pelas opções).
- **Motivo:** o mínimo para o motor e os testes.

### D010 · 2026-11-03 · Decisões 2 a 9 da especificação: recomendações aprovadas

O usuário aprovou todas as recomendações da proposta ([`docs/PROPOSTA-M0.md`](docs/PROPOSTA-M0.md#c-decisões-em-aberto-seção-9-da-especificação), onde estão as alternativas descartadas e os motivos de cada uma).

| Nº | Decisão | Escolha |
| --- | --- | --- |
| 2 | Tipo da magia de fogo | Projétil com carga curta, que ilumina o caminho; soltar antes da carga cancela sem custo |
| 3 | Recarga fora da escola | Nenhuma; reserva finita por incursão |
| 4 | Morte | Renasce no Salão de Estudos com vida e reserva cheias; conhecimento salvo no momento da descoberta |
| 5 | Estudo vira poder | Árvore leve de páginas com pré-requisitos; combinação de aspectos depois |
| 6 | Instrumento de escaneamento | Lente Taxonômica na mão esquerda; não escaneia e lança ao mesmo tempo |
| 7 | Nomes | IDs neutros; nomes latinos durante o desenvolvimento em `locales/names.csv`; Lume, Maré, Barro, Sopro, Prumo e Ruína para distribuir; escola: Colégio do Astrolábio; jogo: Catálogo do Abismo; inimigo: Bedel Descarnado |
| 8 | Premissa | As Ruínas da Primeira Escola |
| 9 | Prioridade visual | Limite de luzes por sala; se preciso, cortar dithering → afim → resolução → névoa |

### D011 · 2026-11-03 · Godot executado no ambiente de desenvolvimento

- **Escolha:** o usuário autorizou executar o Godot 4.7.2 oficial na nuvem. Testes rodam em modo headless; capturas de tela, numa tela virtual (Xvfb) com OpenGL por software (Mesa llvmpipe). Confirmado: o renderizador Compatibility desenha, e o vertex snapping e a névoa do shader aparecem.
- **Descartado:** escrever o código sem testá-lo aqui.
- **Motivo:** cada marco é conferido rodando de verdade antes da entrega.

### D012 · 2026-11-03 · Greybox com `GreyboxBlock` em vez de CSG (revisa D005)

- **Escolha:** blocos `StaticBody3D` com o script `@tool` `GreyboxBlock`, que cria uma `BoxMesh` subdividida (cerca de 1 divisão por metro) e a colisão a partir de `size`.
- **Descartado:** nós CSG (previstos em D005).
- **Motivo:** CSG gera cada face como um único polígono. Com o mapeamento afim, a textura de um chão de 12 m deformaria demais, e a iluminação por vértice não teria onde variar. O bloco continua editável no editor como o CSG.

### D013 · 2026-11-03 · Baixa resolução com `SubViewport` + `TextureRect`

- **Escolha:** o mundo 3D é desenhado num `SubViewport` com a altura escolhida nas opções (largura conforme a proporção da janela). Uma `TextureRect` (`GameScreen`) o amplia sem filtragem e aplica o pós-processamento de cor limitada e dithering. A interface fica fora, em resolução da janela. Os eventos de entrada são repassados ao `SubViewport` com `push_input`.
- **Descartados:** modo de estiramento `viewport` da janela inteira (deixaria os menus em 240 linhas, ilegíveis); `scaling_3d_scale` (no renderizador Compatibility amplia com filtro bilinear, borrando os pixels); `SubViewportContainer` (só reduz por fatores inteiros, sem altura exata).
- **Motivo:** altura exata em linhas, pixels nítidos e textos legíveis.

### D014 · 2026-11-03 · Efeitos PS1 por parâmetros globais de shader

- **Escolha:** um único shader de superfície (`scripts/render/ps1.gdshader`) lê parâmetros globais (`ps1_vertex_snap`, `ps1_affine_mapping`, `ps1_fog`, cor e distâncias da névoa, grade do snapping). As opções e a atmosfera da sala mudam esses parâmetros, e todos os materiais mudam juntos. A névoa é calculada no shader (saída `FOG`), não pelo `Environment`. Iluminação por vértice (`render_mode vertex_lighting`).
- **Descartados:** um parâmetro por material (o menu teria de percorrer todos os materiais); a névoa do `Environment` (não segue o cálculo por vértice e não dá para desligar por material).
- **Motivo:** um ponto só para ligar e desligar cada efeito. Observação: parâmetros globais de cor não passam pela conversão sRGB → linear, então o shader faz essa conversão para a cor da névoa.

### D015 · 2026-11-03 · Autoloads `Content` e `Settings` em `scripts/autoload/`

- **Escolha:** `Content` carrega e valida `data/` uma vez (`Content.db`); `Settings` guarda as opções do jogador, grava `user://settings.cfg` e avisa mudanças pelo sinal `changed`. A lógica fica em `scripts/core` (`ContentDB`, `GameSettings`); os autoloads só fazem a ponte com o jogo.
- **Descartado:** autoload `graphics_settings.gd` em `scripts/render/` (previsto na proposta), que misturaria opções de mouse com gráficos.
- **Motivo:** pasta própria deixa claro o que é global.

### D016 · 2026-11-03 · Arquivo de opções separado do save, com versão

- **Escolha:** `user://settings.cfg` (formato `ConfigFile`, legível), com `[meta] format_version`. Valores inválidos ou fora dos limites são ignorados ao ler. Filtros visuais e limites (resoluções, sensibilidade, bits de cor) vêm de `data/settings/`.
- **Descartado:** guardar as opções no mesmo arquivo do save de conhecimento.
- **Motivo:** opções são por máquina; o conhecimento é do jogador (M2).

### D017 · 2026-11-03 · Texturas provisórias geradas por código

- **Escolha:** `tools/generate_textures.gd` gera texturas 32×32 (lajes, tijolos, madeira) com semente fixa. Os PNGs ficam no repositório e podem ser trocados por arte própria. Padrão de importação do projeto: sem mipmaps, sem compressão de vídeo.
- **Descartado:** baixar texturas livres agora.
- **Motivo:** a especificação permite formas e texturas geradas por código; evita depender de licenças no greybox.

### D018 · 2026-11-03 · Corrida e pulo incluídos

- **Escolha:** Shift corre e Espaço pula, com valores em `data/player/player.tres`.
- **Descartado:** deixar para depois.
- **Motivo:** a especificação pede "apenas se forem baratos": com `CharacterBody3D` são poucas linhas.

### D019 · 2026-11-03 · Arquivos gerados pela importação

- **Escolha:** os arquivos `.uid` e `.import` vão para o git (o Godot precisa deles para manter as referências e as opções de importação). As traduções compiladas (`*.translation`), geradas a partir de `locales/*.csv`, ficam fora do git e são recriadas pela importação.
- **Descartado:** versionar `*.translation`, que são binários derivados do CSV.
- **Motivo:** o CSV é a fonte; o editor reimporta ao abrir o projeto.

### D020 · 2026-11-03 · Marcos M2 a M5 sem aprovação intermediária

- **Escolha:** o usuário autorizou seguir do M2 ao M5 sem esperar aprovação entre os marcos ("pode seguir até o M5") e pesquisar na internet as referências visuais. Cada marco continua com testes, capturas, README, DECISIONS.md e commit próprio. Só paro para perguntar o que mudar o jogo, a tecnologia ou o escopo.
- **Descartado:** aprovação a cada marco (regra da seção 11 da especificação, suspensa pelo usuário até o M5).
- **Motivo:** pedido do usuário. A direção visual pesquisada está em [`docs/REFERENCIAS-VISUAIS.md`](docs/REFERENCIAS-VISUAIS.md).

### D021 · 2026-11-03 · A escola é uma única sala de dados com duas áreas

- **Escolha:** `data/rooms/school.tres` aponta para `scenes/rooms/school.tscn`, que contém o Salão de Estudos, o corredor e a Sala do Portal. O jogador anda entre elas sem carregamento. Entradas: `default` (Salão, também usada ao renascer) e `from_dungeon` (diante do portal).
- **Descartado:** uma sala de dados para cada área, com troca de sala na porta.
- **Motivo:** a especificação pede "uma porta ou corredor"; andar por ele é mais natural que uma tela de transição. As salas da Dungeon continuam sendo módulos separados.

### D022 · 2026-11-03 · Pontos de pesquisa: 1 por aspecto novo, 0 por alvo novo

- **Escolha:** `points_per_new_aspect = 1` (tabela da seção 6) e `points_per_new_target = 0`, ambos em `data/research/rules.tres`. Escanear de novo não rende nada.
- **Descartado:** dar pontos também por alvo novo, o que somaria 12 pontos só na escola contra 3 de custo da página.
- **Motivo:** segue a tabela e mantém a escala. O valor por alvo existe nos dados, para quando houver mais conteúdo.

### D023 · 2026-11-03 · Textos em três arquivos de tradução

- **Escolha:** `locales/ui.csv` (interface), `locales/content.csv` (objetos, páginas, significados) e `locales/names.csv` (só os nomes que remetem a outras obras: os seis aspectos e o termo "Focus"). Textos citam aspectos como `{fire}`, e `Text.expand()` troca pelo nome do arquivo de nomes. Assim, "Compreensão de Ignis" vira "Compreensão de Lume" só trocando `names.csv`.
- **Descartado:** nomes de aspecto escritos dentro dos outros textos.
- **Motivo:** decisão 7: tudo o que remete a outras obras em um único arquivo.

### D024 · 2026-11-03 · Valores padrão neutros nas classes de dados

- **Escolha:** as classes `Resource` de conteúdo têm padrões zerados ou vazios. Os valores reais ficam sempre nos arquivos `.tres`, e o `ContentDB` acusa valores faltando.
- **Descartado:** padrões com os valores do jogo nos scripts.
- **Motivo:** o Godot não grava num `.tres` o valor igual ao padrão do script. Com padrões "de jogo", o valor ficaria escondido no código, contra a regra "nada de conteúdo fixo no código".

### D025 · 2026-11-03 · Escaneamento e interação pela mira

- **Escolha:** a cada quadro de física, o jogador lança um raio do centro da câmera. O que ele atinge é procurado subindo pela árvore de nós: `Interactable` (E, até 2,5 m) e qualquer nó com `get_scannable()` (Lente, até 6 m). Objetos pequenos têm colisão maior que o desenho, para serem fáceis de mirar. A Lente sobe na frente da câmera com o botão direito; soltar ou mudar de alvo zera a barra. Depois de escanear, mirar o objeto mostra nome e aspectos no HUD.
- **Descartado:** áreas de proximidade (`Area3D`) para interação.
- **Motivo:** mirar é a mecânica central do jogo; o mesmo raio serve a escaneamento, interação e (no M3) magia.

### D026 · 2026-11-03 · Telas que pausam o jogo

- **Escolha:** pausa, Livro de Pesquisa (Tab) e Mesa de Pesquisa derivam de `MenuLayer`: abrem pausando o jogo e soltando o mouse; Esc fecha (Tab também fecha o Livro). O save é gravado a cada descoberta e a cada página estudada (decisão 4), em `user://save.json`. Um save inválido é copiado para `save.json.bak` e o jogo começa do zero.
- **Descartado:** Livro aberto com o jogo correndo.
- **Motivo:** ritmo lento e seguro para ler; evita morrer lendo na Dungeon.

## Pendentes (aguardando o usuário)

| Nº | Decisão | Estado |
| --- | --- | --- |
| 10 | Computador de jogo | Aguardando sistema, processador e vídeo. Até lá: 240 linhas e todos os efeitos ligados por padrão |
| 11 | Referências visuais | Aguardando imagens ou descrições. Até lá: greybox com o shader PS1 |
