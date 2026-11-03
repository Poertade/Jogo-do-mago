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

### D027 · 2026-11-03 · Magia de fogo: carga, custo e disparo

- **Escolha:** segurar o botão esquerdo carrega por `charge_time`; soltar com a carga completa lança e só então gasta o custo (dividido pela eficiência da varinha, arredondado para cima); soltar antes cancela sem custo; depois do disparo vale o intervalo `cooldown`. Sem energia, a carga nem começa e o HUD avisa. A Lente e a varinha se excluem (decisão 6). Dano = dano do Focus × efeitos das páginas × fraqueza do alvo. O projétil sai da ponta da varinha em direção ao ponto sob a mira, leva uma luz que ilumina o caminho e testa colisão com um raio a cada quadro.
- **Descartados:** cobrar ao começar a carga (pune quem desiste); colisão por `Area3D` (pode atravessar paredes finas em alta velocidade).
- **Motivo:** decisão 2 aprovada (projétil com carga curta) e valores da seção 6 em `data/foci/fire_focus.tres`.

### D028 · 2026-11-03 · Estado da incursão separado do conhecimento

- **Escolha:** `RunState` (vida, reservas da varinha, magia) fica no autoload `Game` e é reiniciado ao morrer (M4). A varinha de aprendiz tem reserva de 30 para cada um dos seis primais, mas o HUD só mostra os aspectos que o Focus equipado gasta. O braseiro (`RechargePoint`) enche a reserva de Ignis; não há recarga fora da escola (decisão 3).
- **Descartado:** reserva só de Ignis na varinha.
- **Motivo:** a especificação pede "reserva de energia por aspecto primal"; outros Focus poderão usar as outras reservas sem mudar a varinha.

### D029 · 2026-11-03 · IA do inimigo: cérebro no núcleo, corpo no jogo

- **Escolha:**
  - **Separação:** `EnemyBrain` (lógica pura, testada) decide o estado; o nó `Enemy` move, anima e aplica dano.
  - **Estados:** parado → perseguindo (ao ver o jogador a até `sight_range`, por um raio de visão) → atacando (preparação de `attack_windup` com o braço erguido; o golpe só acerta se o jogador ainda estiver ao alcance, então dá para recuar e esquivar).
  - **Reação ao dano e morte:** o dano interrompe o golpe e faz o inimigo parar por `hurt_stun`, com um clarão branco; também o desperta, se estava parado. Na morte, ele desmorona.
  - **Movimento:** perseguição em linha reta, sem navegação.
- **Descartados:** navegação com `NavigationAgent3D` agora (a sala é aberta, não precisa); acerto imediato ao entrar no alcance (sem chance de reação).
- **Motivo:** especificação 5.6 (inimigo lento, três estados, reação ao dano, morte) com espaço para o combate ter leitura.

### D030 · 2026-11-03 · Sala da Dungeon como módulo de marcadores e dados

- **Escolha:** a câmara de pedra é uma cena com `EntrancePoint` (`from_portal`), `EnemySpawn` (aponta para um `EnemyData`) e `ExitPoint` (destino em dados, fechado por uma grade até a sala ser limpa). O `Room` cria os inimigos dos marcadores, conta os vivos e emite `cleared`. `EnemyData` herda de `ScannableData`: todo inimigo é escaneável, com o mesmo espaço de identificadores dos objetos. O portal da escola também tem o destino em dados (`stone_chamber` / `from_portal`).
- **Descartado:** inimigos e saídas colocados direto na cena, com lógica própria por sala.
- **Motivo:** especificação 5.6: pontos de entrada, saída e spawns definidos por dados, pensando em gerar Dungeons combinando salas.

### D031 · 2026-11-03 · Viagem, morte e transição

- **Escolha:**
  - **Transição:** portal e saída pedem a viagem ao `Game`; a cena principal pausa o jogo e "dissolve" a imagem pixel a pixel na ordem da matriz de Bayer (violeta na viagem, vermelho na morte), troca a sala e dissolve de volta.
  - **Chegada à escola:** restaura a vida (a escola é segura), mas não a reserva (só o braseiro recarrega).
  - **Morte:** reinicia a incursão (vida e reserva cheias, sala recriada com o inimigo) e leva ao Salão de Estudos. O conhecimento não é tocado, porque já foi salvo na descoberta (decisão 4).
- **Descartados:** corte seco entre salas; recarregar a reserva ao voltar vitorioso (tiraria o sentido do braseiro).
- **Motivo:** especificação 5.5 e 5.7 (transição curta no estilo do jogo; estado da incursão reiniciado na morte).

### D032 · 2026-11-03 · Premissa em texto mínimo

- **Escolha:** a premissa "As Ruínas da Primeira Escola" (decisão 8) aparece numa placa de bronze na Sala do Portal (E para ler) e numa linha ao despertar depois da morte. Os textos ficam em `locales/content.csv`.
- **Descartado:** introdução em tela cheia.
- **Motivo:** a especificação pede só texto mínimo neste marco.

### D033 · 2026-11-03 · Sons provisórios gerados por código

- **Escolha:**
  - **Geração:** `tools/generate_sounds.gd` sintetiza 17 sons (ondas e ruído, WAV mono 22 kHz, 16 bits, com o som abafado do PS1), com semente fixa.
  - **Dados:** `data/audio/sound_bank.tres` liga cada evento do jogo a um arquivo e a um volume. Cada sala tem um som de ambiente em `RoomData.ambience` (estalos de braseiro na escola; vento, zumbido e gotas na Dungeon), em vez de música, como pede a especificação.
  - **Reprodução:** o autoload `Audio` toca sons sem posição (interface, jogador) e sons 3D (impacto, inimigo).
  - **Aviso de golpe:** o sopro do golpe do inimigo toca no início da preparação, servindo de aviso para esquivar.
  - **Opções:** volume geral no menu.
- **Descartados:** sons de bancos livres (exigiriam curadoria e créditos agora); música constante.
- **Motivo:** especificação M5 ("sons provisórios") e seção 4 ("sons de ambiente em vez de música constante").

### D034 · 2026-11-03 · Balanceamento: vida do Bedel de 40 para 50

- **Escolha:** a vida do Bedel Descarnado subiu de 40 (tabela da seção 6) para 50. Os outros valores da tabela ficam como estão.
  - **Sem a página:** 3 acertos de 22,5.
  - **Com "Compreensão de Ignis":** 2 acertos de 27.
  - **Reserva:** a varinha (6 disparos) ainda dá folga para errar.
  - **Confirmação:** um teste e o novo `tools/balance_report.gd` garantem essa relação; a diferença foi confirmada rodando o jogo.
- **Descartado:** manter 40, com o qual o inimigo cai com 2 acertos com ou sem a página e o benefício da pesquisa fica invisível (a especificação pede um benefício "permanente e perceptível").
- **Motivo:** M5 pede ajuste de balanceamento; todos os valores seguem nos dados.

### D035 · 2026-11-03 · Exportação para Windows e Linux

- **Escolha:** `export_presets.cfg` com os perfis *Windows Desktop* e *Linux* (x86_64). O pacote do jogo vai embutido no executável. Ficam de fora os testes, as ferramentas, a documentação e o GUT. Os dois executáveis foram gerados e o de Linux foi conferido rodando aqui.
- **Descartado:** macOS por enquanto: exige assinatura e notarização para abrir sem alertas, e o sistema do usuário ainda não foi informado (pergunta 10).
- **Motivo:** o usuário pediu um programa de desktop; Windows e Linux cobrem a maioria dos computadores.

### D036 · 2026-11-03 · Lista de resoluções como `Array[int]`

- **Escolha:** `SettingsDefaults.internal_heights` passou de `PackedInt32Array` para `Array[int]`.
- **Descartado:** manter `PackedInt32Array`.
- **Motivo:** no executável exportado a lista chegava vazia, porque o valor se perdia na conversão dos recursos de texto para binário. O erro só apareceu ao rodar a exportação; os demais campos (dicionários e listas tipadas) passaram.

### D037 · 2026-11-03 · Fechar o jogo para os sons primeiro

- **Escolha:** fechar pelo menu ou pela janela passa por `Main.quit_game()`, que para todos os sons e espera 0,15 s antes de sair.
- **Descartado:** fechar no mesmo quadro.
- **Motivo:** com um som de ambiente tocando, a saída imediata deixava o som "preso" na memória (aviso de vazamento ao sair).

### D038 · 2026-11-03 · Testes de conteúdo aceitam conteúdo novo

- **Escolha:** o teste do conteúdo exige os seis primais e os seis objetos da especificação, mas não proíbe conteúdo a mais.
- **Descartado:** contar exatamente 6 aspectos e 6 objetos.
- **Motivo:** o guia "Como estender" manda rodar os testes depois de adicionar conteúdo. Seguindo o guia numa cópia do projeto (aspecto composto "Lux", objeto "Lanterna", inimigo "Espectro de Cinzas" na câmara de pedra), tudo funcionou, mas a contagem exata falhava sem motivo real.

## Depois do M5 (pedidos do usuário)

### D039 · 2026-11-03 · Pesquisa no estilo do Thaumcraft 4 (substitui D022 e amplia a decisão 5)

- **Pedido:** "quero que dê para escanear absolutamente tudo, mas que para aspectos mais complexos seja feito igual ao Thaumcraft: você precisa descobrir eles na mesa antes."
- **Escolha:**
  - **Tudo escaneável:** blocos de sala, objetos, decorações e o inimigo; são 28 escaneáveis.
  - **Primais:** descobertos escaneando.
  - **Compostos:** só na Mesa, combinando os dois pais. Cada combinação gasta 1 ponto de cada pai e rende 1 do composto.
  - **Escaneamento bloqueado:** um alvo com composto ainda não descoberto não pode ser escaneado ("conhecimento insuficiente"), como no Thaumcraft 4. O HUD mostra "?" no que falta.
  - **Pontos:** passam a ser **por aspecto**, 2 por unidade no primeiro escaneamento de cada alvo (`data/research/rules.tres`).
  - **Páginas:** custam pontos de aspectos ("Compreensão de Ignis": 4 Ignis + 2 Potentia).
  - **Save:** versão 2. Saves da versão 1 mantêm aspectos e páginas, mas perdem o total antigo de pontos e voltam a poder escanear tudo.
  - **Escola:** os seis objetos da escola continuam só com primais, para o jogo começar.
- **Descartados:**
  - Escaneamento parcial (registrar só os aspectos conhecidos), mais generoso que o Thaumcraft.
  - Manter um total único de pontos: a combinação de aspectos precisa de pontos de cada aspecto.
- **Motivo:** pedido do usuário; o Thaumcraft é a base de quase todo o jogo. O teste `test_research_economy.gd` garante que, com o conteúdo atual, tudo pode ser escaneado e a página estudada.

### D040 · 2026-11-03 · Receitas dos aspectos compostos (Thaumcraft 4.2)

- **Escolha:** 15 compostos com as receitas do Thaumcraft 4.2:

  | Composto | Receita |
  | --- | --- |
  | Lux | Aer + Ignis |
  | Motus | Aer + Ordo |
  | Vacuos | Aer + Perditio |
  | Potentia | Ordo + Ignis |
  | Victus | Aqua + Terra |
  | Vitreus | Terra + Ordo |
  | Herba | Terra + Victus |
  | Mortuus | Victus + Perditio |
  | Praecantatio | Vacuos + Potentia |
  | Metallum | Terra + Vitreus |
  | Arbor | Aer + Herba |
  | Spiritus | Victus + Mortuus |
  | Exanimis | Motus + Mortuus |
  | Cognitio | Ignis + Spiritus |
  | Iter | Motus + Terra |

  Os identificadores são neutros (`light`, `life`…); os nomes latinos ficam em `locales/names.csv` (decisão 7).
- **Descartadas:** as receitas do Thaumcraft 4.0/4.1 (ex.: Cognitio = Terra + Spiritus), que mudaram na 4.2.
- **Motivo:** o acesso à wiki do Thaumcraft 4 foi liberado, mas o site (Fandom) recusa acesso automático deste ambiente (erro 403). As receitas vêm de buscas que citam a tabela atual da wiki (Cognitio, Exanimis, Arbor, Herba, Victus) e de fontes anteriores (Potentia, Praecantatio, Mortuus, Spiritus). Estão só em `data/aspects/`, fáceis de corrigir. Os nomes próprios dos compostos para a versão distribuída ainda não foram escolhidos.

### D041 · 2026-11-03 · Nódulo de Vis no lugar do braseiro

- **Pedido:** a chama do braseiro estava escura, sem animação, e deveria virar as "bolinhas de Vis" do Thaumcraft.
- **Escolha:** um Nódulo de Vis (inspirado nos nódulos de aura do Thaumcraft 4):
  - **Visual:** núcleo na cor do aspecto (Ignis), sete bolinhas em órbita, pulso e luz animados.
  - **Uso:** **segurar E** drena 12 pontos de Vis por segundo para a varinha, com bolinhas voando até a ponta dela.
  - **Código novo:** `Interactable` ganhou o modo "segurar" (`hold_to_use`), e `WandState`, o método `add()`.
  - **Recarga:** continua só na escola (decisão 3).
- **Descartados:** recarga instantânea com um aperto; nódulo com reserva própria que se esgota (fica para quando houver mais nódulos).
- **Motivo:** pedido do usuário e fidelidade ao Thaumcraft 4, em que se drena Vis dos nódulos com a varinha.

### D042 · 2026-11-03 · Parâmetros float de shader sempre com casa decimal

- **Escolha:** o gerador de cenas grava valores decimais como `3.0`. O teste `test_scene_files.gd` falha se algum parâmetro float de shader estiver gravado como inteiro.
- **Descartado:** confiar na conversão automática.
- **Motivo:** a causa da "labareda escura": `emission_energy = 3` (inteiro) era ignorado e o brilho ficava em zero. Afetava as chamas, as tochas, o projétil, o impacto e os olhos do inimigo; em alguns computadores (como o do usuário) aparecia preto.

### D043 · 2026-11-03 · Inimigos com esqueleto articulado (referência: Lunacid)

- **Pedido:** o inimigo estava "terrivelmente feio"; usar os inimigos de Lunacid como base.
- **Escolha:**
  - **Corpo:** o Bedel Descarnado foi refeito com um esqueleto de juntas (`EnemyRig`), com peças de baixa contagem de polígonos presas a elas.
  - **Animação:** calculada por código e travada em 12 quadros por segundo.
  - **Texturas geradas:** osso rachado, manto com barra rasgada, rosto de caveira, ferro.
  - **Recorte:** um shader com recorte (`ps1_cutout.gdshader`) para pano rasgado e rosto.
  - **Das descrições de Lunacid:** silhueta marcante, detalhe nas texturas e não na geometria, animação "aos trancos", olhos que brilham no escuro.
  - **Reuso:** o `EnemyRig` serve para os próximos inimigos humanoides.
- **Descartados:** modelos animados em ferramenta externa (Blender), que o ambiente não tem; um corpo de uma peça só, sem articulação.
- **Motivo:** uma figura mais legível e inquietante, que dá para editar no Godot. Não foi possível ver imagens de Lunacid (só textos): a direção está em `docs/REFERENCIAS-VISUAIS.md`.

### D044 · 2026-11-03 · Varinha mais encorpada, no formato do Thaumcraft

- **Escolha:** núcleo de madeira mais grosso, ponteiras de latão nas duas pontas e o Focus maior na ponta. O formato segue a varinha do Thaumcraft 4: núcleo + ponteiras + Focus.
- **Descartado:** só engrossar o bastão.
- **Motivo:** pedido do usuário ("ficou muito fininha") e preparo para varinhas com núcleos e ponteiras diferentes.

### D045 · 2026-11-03 · Sons: estalos mais baixos e sem cortes secos

- **Escolha:**
  - **Estalos:** os do ambiente da escola caíram para cerca de um quarto, e o ambiente tocado está 4 dB mais baixo.
  - **Laços:** os sons em laço (carga da magia, zumbido da Lente, drenagem de Vis) somem em 0,08 a 0,2 s em vez de cortar.
- **Descartado:** tirar os estalos.
- **Motivo:** pedido do usuário. Cortar um som no meio também gera estalo.

## Pendentes (aguardando o usuário)

| Nº | Decisão | Estado |
| --- | --- | --- |
| 10 | Computador de jogo | Aguardando sistema, processador e vídeo. Até lá: 240 linhas e todos os efeitos ligados por padrão |
| 11 | Referências visuais | Aguardando imagens ou descrições. Até lá: greybox com o shader PS1 |
| — | Nomes próprios dos aspectos compostos | Para a versão distribuída (como Lume, Maré… nos primais). Até lá, nomes latinos em `locales/names.csv` |
| — | Receitas do Thaumcraft | Se quiser conferir com a wiki, cole a tabela de aspectos: as receitas ficam só em `data/aspects/` |
