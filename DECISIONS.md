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

### D046 · 2026-11-03 · Ícones dos aspectos desenhados por código

- **Escolha:** um ícone 16×16 para cada aspecto (`AspectData.icon`), com símbolos originais e simples (chama, gota, montanha, raio…) na cor do aspecto, com contorno escuro. Gerados por `tools/generate_icons.gd`; qualquer PNG pode substituí-los mantendo o nome.
- **Descartado:** copiar os ícones do Thaumcraft; só bolinhas coloridas.
- **Motivo:** a Mesa no estilo da imagem enviada é uma grade de ícones, e os ícones do mod não podem ser usados.

### D047 · 2026-11-03 · Reserva única de Vis na varinha (substituída por D051)

- **Escolha:** a varinha guarda um só número de Vis (`capacity` = 30); cada Focus custa um tanto desse Vis (`cost` = 5 no Focus de Fogo); o Nódulo de Vis enche a reserva; o HUD mostra uma barra de Vis. A reserva não vai para o save: ela é da incursão.
- **Descartado:** uma reserva por aspecto (como estava, e como nos Thaumcraft 3 e 4, em que a varinha guarda os seis primais separados).
- **Motivo:** pedido do usuário ("uma reserva única para todos os Vis"). Se a intenção era uma varinha com os seis primais em barras separadas, a troca é pequena: `WandState` volta a ter um dicionário e o Focus volta a ter custo por aspecto.

### D048 · 2026-11-03 · Notas de pesquisa no lugar do custo das páginas

- **Escolha:** cada página tem uma nota de pesquisa no estilo do Thaumcraft 4: grade de hexágonos (`note_radius`), com os aspectos de `note_aspects` marcados na borda. Escrever um aspecto num hexágono vazio gasta `note_write_cost` (1) ponto dele; apagar devolve. Vizinhos se ligam quando um é pai do outro; a página é estudada quando todos os marcados estão ligados. A lógica fica em `scripts/core/research_note.gd` (testada); a tela, em `research_note_view.gd`. Compreensão de Ignis: Ignis, Potentia e Lux, raio 2.
- **Descartado:** pagar a página direto com pontos (D039); copiar as regras de tinta e de aspectos "conectados por cor" do mod.
- **Motivo:** pedido do usuário, com a imagem da pesquisa do mod. A nota obriga a conhecer as receitas, que é o coração da pesquisa do Thaumcraft 4.
- **Save:** formato 3, com `research_notes` (página → {"q,r": aspecto}). Saves antigos carregam com as notas vazias.

### D049 · 2026-11-03 · A nota resolvida fica guardada

- **Escolha:** ao estudar a página, a nota resolvida continua no save e no pergaminho, e não pode mais ser apagada (nem devolve pontos).
- **Descartado:** apagar a nota ao estudar.
- **Motivo:** a página estudada mostrava a grade vazia, o que parecia um erro; ver a própria solução é a recompensa.

### D050 · 2026-11-03 · Menus de pergaminho e fonte Pixelify Sans (dependência nova)

- **Escolha:**
  - **Tema:** `assets/ui/parchment_theme.tres`, aplicado à Mesa, ao Livro, à pausa, às opções e à tela de leitura. Painéis de pergaminho com borda queimada e rasgada; a Mesa tem moldura de madeira escura (variação `WoodPanel`), como a imagem enviada. Tinta marrom no texto, títulos em vermelho escuro. O HUD continua escuro, sobre o jogo.
  - **Texturas:** geradas por `tools/generate_ui_theme.gd`. O miolo do pergaminho se repete sem emenda.
  - **Fonte:** [Pixelify Sans](https://github.com/eifetx/Pixelify-Sans), fonte de pixels sob a licença SIL OFL 1.1. O texto da licença fica em `assets/fonts/` e vai dentro dos executáveis (`include_filter` dos perfis de exportação). Importada sem suavização.
- **Descartado:** desenhar uma fonte própria (muito trabalho para pouco ganho); a fonte padrão do Godot (lisa, destoa do visual PS1); fontes sem licença livre.
- **Motivo:** pedido do usuário ("menus que pareçam pergaminhos"). A OFL permite distribuir a fonte dentro do jogo, inclusive em venda, desde que a licença acompanhe.

### D051 · 2026-11-03 · Recipientes de Vis por aspecto, com limite total (substitui D047)

- **Escolha:** a varinha tem um recipiente para cada aspecto da lista `aspects` (os seis primais, na ordem dos frascos do HUD). Cada recipiente guarda até `aspect_capacity` (10), e a soma de todos não passa de `capacity` (30): com 10 de Ignis, 10 de Aqua e 10 de Perditio, a varinha está cheia.
  - **Custo:** o Focus volta a ter custo por aspecto (`cost`), e o Focus de Fogo passa a gastar 2 de Ignis.
  - **Vis inicial:** fica em `starting_vis` (`data/player/player.tres`, 10 de Ignis). Ele vale no começo de cada incursão e depois da morte; o resto se perde ao morrer.
  - **Nódulo:** enche só o recipiente do aspecto dele, até o limite do recipiente ou o total.
  - **HUD:** um mostrador como o do Thaumcraft 4 (imagem enviada pelo usuário), com o orbe do Focus no centro, um frasco por recipiente em leque e o total embaixo.
- **Descartado:**
  - **Manter os 5 de Ignis por disparo da especificação:** com 10 no recipiente, seriam só 2 disparos, e o Bedel precisa de 3 sem a página.
  - **Recipientes sem limite próprio:** o usuário pediu os dois limites.
- **Motivo:** pedido do usuário ("um contêiner separado para cada Vis, com uma reserva total e uma separada"). Com 2 por disparo, o recipiente cheio dá 5 disparos: o Bedel cai com 3, ou 2 com a página, como antes.

### D052 · 2026-11-03 · Interface em pixels grandes, com o mesmo filtro do mundo (refina D050)

- **Escolha:**
  - **Pixels grandes:** HUD e menus são desenhados num `SubViewport` de 640×360 e ampliados 2× sem filtro (`SubViewportContainer` com `stretch_shrink` = 2).
  - **Mesmo filtro do mundo:** a imagem pequena passa pelo mesmo dithering e pela mesma cor limitada do mundo 3D (`scripts/render/ui_pixels.gdshader`). Ela segue as mesmas opções, por parâmetros globais de shader.
  - **Cores:** o pergaminho ficou mais escuro, sujo e queimado nas bordas, e a madeira mais escura. O fundo atrás dos menus escurece menos, para o jogo continuar visível.
  - **Desenho na grade:** ícones dos aspectos em 16×16 sem escala, linhas de 1 pixel e controles (chave, seta, marcador) desenhados em pixels.
  - **Letras:** 10 px e 20 px, os únicos tamanhos em que a Pixelify Sans fica nítida. Os espaços entre palavras ganharam 1 pixel (`assets/ui/ui_font.tres`).
- **Descartado:**
  - **Mudar o modo de esticar do projeto para "viewport":** a imagem do mundo, de 240 linhas, ficaria ampliada 1,5×, com pixels desiguais.
  - **Pixelar a tela inteira por cima:** as letras ficariam tortas.
  - **Uma imagem de 427×240, como o mundo:** não cabe a Mesa de Pesquisa com texto legível.
- **Motivo:** o usuário achou os menus "destoantes, como se fossem de outro jogo": eram claros, lisos e em alta resolução sobre um mundo escuro e pixelado. A interface fica com pixels de 2×, perto dos 3× do mundo.

### D053 · 2026-11-03 · Save formato 4: páginas estudadas no sistema antigo reabrem

- **Escolha:** ao carregar um save anterior ao formato 4, uma página só continua estudada se tiver a nota resolvida guardada. As que foram pagas com pontos no sistema antigo (antes de D048) voltam a ficar abertas.
- **Descartado:**
  - **Manter como estava:** a Mesa mostrava "Pesquisa concluída" com a grade vazia, e o usuário viu como erro ("a pesquisa se compreendeu sozinha").
  - **Apagar o save inteiro.**
- **Motivo:** nenhum código estudava a página sozinho; ela vinha do save das versões anteriores. Agora a única forma de estudar é resolver a nota.

## M6 e M7 (aprovados pelo usuário)

### D054 · 2026-11-03 · Escopo do M6 e do M7, feitos de uma vez

- **Escolha:** o usuário autorizou fazer o M6 e o M7 sem parar entre eles e aceitou as escolhas propostas:
  - **Recarga na Dungeon:** um Nódulo pequeno, que se esgota, numa sala de descanso no meio do caminho. Muda a decisão 3, que não previa nenhuma recarga fora da escola.
  - **Tamanho:** 5 salas por incursão.
  - **Chefe:** sim, na última sala; vencê-lo abre a volta à escola.
- **M6, a Dungeon montada:** salas sorteadas de peças prontas, com semente (a mesma semente gera a mesma incursão), dois inimigos novos e a sala de descanso.
- **M7, magia e pesquisa novas:** Focus de Gelo (gasta Aqua e Ordo), Nódulo de Aqua na escola, troca de Focus na escola, uma página de pesquisa ligada aos aspectos da Dungeon e o chefe.
- **Descartado:** fazer só o M6 e esperar a aprovação do M7.
- **Motivo:** pedido do usuário ("pode dar início até o M7"). Ao fim do M7, o trabalho para até o usuário jogar.

### D055 · 2026-11-03 · Fogo a 1 de Ignis por disparo (equilíbrio da incursão)

- **Escolha:** o Focus de Fogo passa a gastar 1 de Ignis por disparo, então o recipiente cheio dá 10 disparos.
- **Descartado:** manter 2 por disparo (5 disparos) da D051.
- **Motivo:** uma incursão de 5 salas pede uns 17 disparos em média (`tools/balance_report.gd`). Com 10 no começo e 10 de Ignis na fonte, dá para vencer, mas é preciso acertar. Com 5 por recipiente, seria impossível.

### D056 · 2026-11-03 · Incursão: salas em sequência, sorteadas com semente (substituída por D065)

- **Escolha:**
  - **Roteiro:** o portal sorteia o roteiro da incursão (`DungeonPlan`, em `scripts/core`), uma sala para cada tipo da sequência `layout` de `data/dungeon/rules.tres`. Uma sala não se repete na mesma incursão enquanto houver outra do mesmo tipo.
  - **Passagem:** cada sala é carregada sozinha, com a transição de pixels, quando o jogador atravessa a saída da anterior. Todas as salas sorteáveis têm a entrada `south`, sobre um círculo de chegada, e uma saída com `goes_deeper`.
  - **Variação:** cada sala tem a sua semente, derivada da semente da incursão, e cada `EnemySpawn` sorteia o inimigo (`enemy_pool`) e se aparece alguém (`chance`).
  - **Semente:** a semente da incursão sai do gerador do jogo, então `--seed=N` repete as mesmas incursões.
- **Descartado:**
  - **Emendar as salas num espaço só, sem transição:** exige evitar sobreposição, juntar a névoa e a luz de várias salas e pesa mais (várias salas acesas ao mesmo tempo).
  - **Gerar a planta da sala por código:** perde o cuidado de cada sala montada à mão.
- **Motivo:** aproveita a sala como módulo, que a especificação pedia desde o M4 (seção 5.6), e o mesmo fluxo de viagem que já existia. Salas novas entram no sorteio só com dados.

### D057 · 2026-11-03 · Inimigos novos e corpo de inimigo como peça trocável

- **Escolha:**
  - **Corpo trocável:** o nó `Rig` de um inimigo pode ter qualquer script que herde de `EnemyBody`: `EnemyRig` (humanoide articulado) ou `BlobRig` (gosma). O comportamento (`EnemyBrain`) é o mesmo para todos, e só os números mudam.
  - **Aprendiz Esquecido:** aluno morto da Primeira Escola, com uniforme cinza-azulado, capuz, livro e pena. Rápido e frágil (28 de vida, 2,3 m/s, golpe com 0,45 s de aviso), fraco a fogo.
  - **Lodo de Tinta:** gosma da tinta dos livros afogados, com olhos claros e um braço que bate. Lento e forte (36 de vida, 12 de dano), resiste a fogo (×0,6), para pedir outra magia no M7.
- **Descartado:** um inimigo que ataca de longe, porque pede um comportamento novo no cérebro (fica para depois).
- **Motivo:** dois perfis opostos ao Bedel (rápido e frágil; lento e resistente) mudam o jeito de lutar sem código de IA novo. Os aspectos deles (Cognitio, Mortuus, Exanimis) levam a pesquisa para a Dungeon.

### D058 · 2026-11-03 · Nódulos que se esgotam e objetos novos da Dungeon

- **Escolha:**
  - **Nódulos:** `VisNode.vis_amount` limita o Vis de um nódulo (-1 = não acaba, como o da escola). A fonte de Vis tem um nódulo de Ignis e um de Aqua, com 10 cada; ao esgotar, o nódulo se apaga.
  - **Objetos novos para escanear:** livros afogados, pilha de ossos, poça de tinta, lamparina de almas e beliche apodrecido.
- **Descartado:** recarga lenta e contínua na Dungeon.
- **Motivo:** D054 (um nódulo pequeno no meio do caminho). Os objetos novos trazem aspectos que a escola não tem (Mortuus, Vacuos, Spiritus), para explorar render pesquisa.

### D059 · 2026-11-03 · Troca de Focus com Q, em qualquer lugar (muda o plano da D054)

- **Escolha:** a tecla Q troca entre os Focus liberados, em qualquer lugar, inclusive na Dungeon; a carga em andamento se perde. Um Focus é liberado por uma página de pesquisa com o efeito `unlock_focus`.
- **Descartado:** trocar só na escola, como estava na proposta da D054.
- **Motivo:** com recipientes separados (D051), o Vis de Aqua e Ordo só serve se o jogador puder usar o gelo na mesma incursão em que usa o fogo. Trocando só na escola, cada incursão teria um Focus e metade da varinha ficaria parada. Alguns inimigos também pedem um Focus específico: o Lodo de Tinta resiste a fogo e é fraco a frio. É o mesmo jeito do Thaumcraft, em que o Focus se troca a qualquer hora.

### D060 · 2026-11-03 · Gelum e o Focus de Gelo

- **Escolha:**
  - **Gelum (frio):** aspecto composto novo, Ignis + Perditio, a receita do Thaumcraft 4. Ícone de floco de neve.
  - **Focus de Gelo:** projétil de frio com 11 de dano, gasta 1 de Aqua e 1 de Ordo e deixa o alvo a 45% da velocidade por 3 s. Lento, o inimigo anda, prepara o golpe e se anima mais devagar, coberto de geada azul.
  - **A página:** *Focus de Gelum* tem nota de raio 2 com Gelum, Aqua e Vacuos. Gelum e Vacuos rendem pontos na Dungeon (geada, poças de tinta).
  - **Vis inicial:** 10 de Ignis, 10 de Aqua e 10 de Ordo, os recipientes dos dois Focus.
  - **Escola:** ganhou um Nódulo de Aqua que também dá Ordo. Um Nódulo pode ter outros aspectos (`other_aspects`), como os do Thaumcraft.
- **Descartado:**
  - **Gelo que congela o alvo de vez:** contra o chefe seria fácil demais.
  - **Um Nódulo de Ordo separado:** encheria a escola de nódulos.
- **Motivo:** D054. O gelo dá outro jeito de lutar (controlar a distância) e usa os outros recipientes da varinha.

### D061 · 2026-11-03 · O Arquivista, chefe do Grande Arquivo

- **Escolha:**
  - **O chefe:** o mesmo esqueleto humanoide, 1,55× maior, com mitra, lanterna de almas e um tomo de ferro. Tem 130 de vida e 18 de dano por golpe, e o frio o fere 30% mais.
  - **Não se abala:** com `hurt_stun` = 0, os disparos não interrompem o golpe; sem isso, disparar a cada segundo o travaria para sempre.
  - **Fúria** (`enrage_at` = 0,5): fica 40% mais rápido e chama dois Aprendizes Esquecidos.
  - **Barra de vida:** aparece no alto da tela quando ele nota o jogador (`show_health_bar`).
  - **A sala:** o Grande Arquivo fecha o roteiro, e a saída dele leva à escola.
- **Descartado:** ataques à distância e fases com padrões novos, porque pedem comportamento novo no cérebro.
- **Motivo:** D054. Sem a página de fogo e sem o gelo, a incursão pede mais disparos do que a varinha tem (uns 25 contra 20): o chefe é o que cobra a pesquisa.

### D062 · 2026-11-03 · Teste que compila todos os scripts

- **Escolha:** `test_scripts_load.gd` carrega todo script de `scripts/` e `tools/`.
- **Descartado:** confiar só nos testes de lógica.
- **Motivo:** um erro de sintaxe no HUD passou pelos testes e só aparecia ao abrir o jogo.

## Edições depois do M7 (pedidas pelo usuário)

### D063 · 2026-11-03 · Potes de Vis no cinto

- **Escolha:** o usuário escolheu "potes que você carrega". O cinto tem 3 potes (`jar_slots`) de até 10 de Vis cada (`jar_capacity`), um aspecto por pote (`VisJarBelt`, em `scripts/core`).
  - **Encher:** o Vis que não cabe na varinha enquanto o jogador drena um Nódulo vai para os potes.
  - **Usar:** R despeja na varinha um pote do aspecto que o Focus gasta (ou de outro, se nenhum servir).
  - **Achar:** potes selados aparecem pelas salas (`LootSpot` com `kind` = `jar`); o que não cabe no cinto fica no pote.
  - **Morte:** o conteúdo se perde.
  - **HUD:** os potes aparecem embaixo do mostrador de Vis.
- **Descartado:** potes espalhados que se drenam como Nódulos; potes fixos de guardar Vis na escola (as outras duas opções da pergunta).
- **Motivo:** escolha do usuário. Também resolve o orçamento: o caminho de 7 salas pede uns 39 disparos, e só a varinha e a fonte não bastam.

### D064 · 2026-11-03 · Livros perdidos e receitas escondidas (a parte das receitas foi refeita na D067)

- **Escolha:**
  - **Aspectos novos:** Tenebrae (Vacuos + Lux), Limus (Victus + Aqua), Vitium (Praecantatio + Perditio) e Alienis (Vacuos + Tenebrae), as receitas do Thaumcraft 4. Todos com `needs_recipe`: a Mesa só combina os pais depois de ler o livro que ensina a receita.
  - **Os livros** (`data/books/`): Tratado das Sombras (ruínas), Bestiário das Grutas (grutas), Diário do Arquivista e Fragmentos do Avesso (o Avesso).
  - **Achar:** cada região mostra um livro ainda não lido por incursão, num lugar de livro das salas dela.
  - **Ler:** só no atril do Salão de Estudos. Quem morre antes perde o livro, que volta a aparecer.
  - **Save formato 5:** livros lidos e receitas aprendidas.
  - **Escanear:** as coisas das grutas e do Avesso têm esses aspectos e só podem ser escaneadas depois que eles forem descobertos.
- **Descartado:**
  - **Ler na hora, na Dungeon:** o usuário pediu que os livros fossem lidos só na escola.
  - **Livros que dão pontos:** não ensinariam nada novo.
- **Motivo:** pedido do usuário. Trazer o livro vivo para a escola dá um motivo para voltar e um risco a cada sala, como os fragmentos de conhecimento que o Thaumcraft 4 espalha pelo mundo.

### D065 · 2026-11-03 · Dungeon contínua, com regiões (substitui D056; o sorteio de salas foi substituído pelo mapa fixo da D068)

- **Escolha:**
  - **Montagem:** o portal monta a Dungeon inteira de uma vez (`Dungeon`, em `scripts/game`). As salas sorteadas ficam em fila para o norte, ligadas por corredores retos que descem em rampa. A planta é calculada em `DungeonLayout`, em `scripts/core` (testada).
  - **O caminho** (`steps` em `data/dungeon/rules.tres`): 7 salas, das **ruínas da escola** (2) às **grutas** (combate, fonte de Vis, combate) e ao **Avesso** (combate e o chefe). Cada passo diz a região, o tipo e quanto o corredor antes dele desce.
  - **Regiões** (`data/dungeon/zones/`): nome, materiais e luzes dos corredores. Ao entrar numa região, o nome dela aparece no alto da tela.
  - **Atmosfera:** a névoa, a luz ambiente e o som mudam aos poucos conforme o jogador anda de uma sala para outra.
  - **Convenção das salas:** porta aberta ao sul (`SouthDoorway`) e saída com grade ao norte. A passagem atrás da grade (`ExitPassage`) só fica na última sala, onde leva de volta à escola. O círculo de chegada fica num beco antes da primeira sala.
  - **Salas novas:** gruta dos fungos, lago subterrâneo e salão invertido. A fonte de Vis foi para as grutas, e o Grande Arquivo, para o Avesso. As salas antigas foram refeitas na convenção nova.
  - **Rampas:** a descida de um corredor é sorteada, e o corredor tem pelo menos 2,2 vezes o comprimento da descida (rampa de até uns 25°). O jogador desce andando, conferido com a tecla de andar.
  - **Sons novos:** ambientes das grutas (gotas com eco) e do Avesso (zumbidos desafinados).
- **Descartado:**
  - **Manter salas separadas com transição (D056):** o usuário pediu "sem esses portais, ligadas por corredores".
  - **Corredores com curvas:** pedem cuidado com sobreposição; a fila reta, com a névoa curta, já esconde o fim.
  - **Escadas com degraus:** o corpo do jogador não sobe degraus sem código a mais; rampas resolvem.
- **Motivo:** pedido do usuário, com uma narrativa que desce da escola para o bizarro. A montagem leva cerca de 1,3 s, dentro da transição do portal.

### D066 · 2026-11-03 · Inimigos que contornam obstáculos, se chamam e batem mais forte

- **Escolha:**
  - **Navegação:** a Dungeon gera uma malha de navegação na montagem, a partir das colisões fixas; as grades ficam de fora, porque abrem depois. Cada inimigo segue o caminho dela com um `NavigationAgent3D`. Num teste, o Bedel contornou um pilar até o alcance do golpe; sem a malha, ficava preso atrás dele.
  - **Alerta:** quem nota o jogador acorda os inimigos a até 9 m, e cada magia lançada acorda os que estão a até 10 m (`noise_radius` na varinha).
  - **Dano:** Bedel 10 → 16, Aprendiz 7 → 11, Lodo 12 → 20, Arquivista 18 → 28.
- **Descartado:**
  - **Desvio local entre inimigos (avoidance):** mais custo; eles raramente se amontoam.
  - **Ataques à distância:** comportamento novo, fica para depois.
- **Motivo:** pedido do usuário: "os inimigos dão pouco dano e são meio burrinhos, tente fazê-los dar a volta em obstáculos".

### D067 · 2026-11-03 · Livros ensinam uma receita que o jogador não tem (refaz parte da D064)

- **Escolha:** o usuário escolheu "receita sorteada, de qualquer composto".
  - **Receitas:** todo composto precisa da receita para ser combinado na Mesa. As dos compostos de nível 1 (dois primais) já vêm sabidas (`free_recipe_tier` = 1). Quem já descobriu um aspecto conhece a receita dele, o que vale para os saves antigos.
  - **Livros:** não têm receita fixa. Ao ser lido, o livro ensina uma receita sorteada entre as que o jogador ainda não conhece, de preferência uma que ele já possa fazer. São 13 a aprender.
  - **Mesa:** sem a receita, mostra "×" e não diz se o par forma algo, como se não formasse nada.
  - **Livro de Pesquisa:** lista as receitas conhecidas ainda por fazer.
  - **Aparecimento:** cada região mostra um livro por incursão enquanto houver receitas a aprender; os títulos se repetem (dois por região).
  - **Ordem dos sorteios:** os identificadores são ordenados por texto. Ordenar `StringName` direto não segue o alfabeto e podia mudar o sorteio com semente de uma execução para outra.
- **Descartado:**
  - **Livros fixos com receitas de 4 aspectos (D064):** o usuário explicou que não era isso.
  - **Mesa que revela combinações por tentativa:** tiraria o valor dos livros.
- **Motivo:** pedido do usuário ("quero que eles ensinem uma receita que você não tem"). A pesquisa agora depende das incursões: cada livro trazido vivo abre um composto novo.

### D068 · 2026-11-03 · Dungeon de mapa fixo, no estilo do Lunacid (substitui o sorteio de salas da D065)

- **Escolha:** o usuário pediu uma Dungeon "parecida com o mapa do Lunacid" e escolheu "fixa, feita à mão". O mapa (`scenes/dungeon/dungeon.tscn`) é original: só a estrutura segue o Lunacid, sem copiar nomes, salas ou o mapa dele (seção 4 da especificação).
  - **Pesquisa:** a busca funcionou, mas os sites (wikis, análises) estão bloqueados na rede deste ambiente; valeram os trechos que a busca devolve. Deles: áreas temáticas ligadas entre si, um centro (Wing's Rest) com loja, cristais de viagem e de save em cada área, caminhos labirínticos que voltam a lugares já vistos, becos sem saída, paredes secretas, portas com chave achada em outro lugar, desníveis (bordas, quedas, pontes) e nenhum mapa na tela.
  - **O mapa:** 15 salas em três regiões, que descem da escola ao bizarro (a narrativa da D065):
    - **Ruínas:** o **Átrio do Poço** é o centro e a chegada. Ao norte, a biblioteca; a leste, o dormitório; a oeste, a câmara de pedra e a Escadaria que desce às grutas. Biblioteca, ossuário e dormitório formam um **laço** de volta ao átrio. No fim do ramo leste fica a **Cripta**, com a chave.
    - **Grutas:** gruta dos fungos, **lago** e **Fonte de Vis**. A **Fenda** tem uma ponte estreita sobre um abismo de 8 m; um túnel no fundo volta à gruta dos fungos.
    - **Avesso:** depois do **portão selado**, o salão invertido, o Vestíbulo e o Grande Arquivo, com o chefe.
  - **Peças** (em `scripts/game`, todas no mapa):
    - **Atalho (`Gate`, `one_way`):** a grade entre o dormitório e o átrio só abre do lado do dormitório.
    - **Porta trancada (`Gate`, `needs_key`):** o portão selado abre com a chave da cripta.
    - **Paredes falsas (`SecretWall`):** na biblioteca e no lago. Somem ao toque (E) ou com uma magia; não mostram texto, e a Lente as revela como "parede ilusória".
    - **Âncoras do portal (`PortalAnchor`):** no átrio, na fonte e no vestíbulo, como os cristais de viagem do Lunacid. Tocar sintoniza; depois, a âncora leva de volta à escola com o que foi achado. Com mais de uma sintonizada, o portal pergunta para onde ir.
    - **O poço:** o buraco no meio do átrio cai no lago das grutas, uma descida rápida e só de ida.
    - **Corredores (`CorridorPath`):** uma linha de pontos, com rampas e curvas, editável no inspetor e visível no editor.
  - **O que fica:** passagens abertas, chaves, âncoras e o chefe vencido vão para o save (`DungeonProgress`) e valem para sempre.
  - **O que muda a cada incursão:** inimigos (`EnemySpawn`, com a semente) e achados (`LootSpot`): livros, potes selados, prata e cacos de vidro.
  - **Orientação:** sem mapa na tela, o canto mostra o nome da sala, e cada lugar tem um marco: o poço com brilho azul, a ponte, o salão invertido.
  - **Grades entre salas:** saem. Só o Grande Arquivo ainda fecha a saída até o chefe cair.
  - **Medidas:** a malha de navegação do mapa inteiro sai em cerca de 30 ms (730 polígonos). Montar o mapa e fazer a transição leva cerca de 1,4 s.
- **Descartado:**
  - **Sorteada com a estrutura do Lunacid:** era a recomendação; o usuário preferiu o mapa fixo.
  - **Copiar áreas do Lunacid:** a especificação proíbe copiar os mapas dele.
  - **Corredores criados por código na montagem (D065):** não apareciam no editor.
- **Motivo:** pedido do usuário. Um mapa fixo deixa o jogador aprender o caminho, e os atalhos, chaves e âncoras dão progresso no mundo além do conhecimento.

### D069 · 2026-11-03 · Potes comprados ou fabricados; prata e cacos de vidro

- **Escolha:** o usuário escolheu "comprar e fabricar" e "os potes ficam; só o Vis se perde".
  - **Começo:** o jogador começa sem potes. O cinto leva até 4 (`jar_slots`).
  - **Comprar:** o **Almoxarife**, atrás de um balcão no Salão de Estudos, vende um pote por 35 de prata.
  - **Fabricar:** a **bancada de vidraria**, do outro lado do salão, faz um pote com 4 cacos de vidro, 3 de Ignis e 3 de Ordo tirados da varinha, como a Bancada Arcana do Thaumcraft, que gasta Vis da varinha.
  - **Os valores** ficam em `data/economy/rules.tres`; os materiais, em `data/items/`.
  - **Prata:** os inimigos deixam prata ao cair (Bedel 2–4, Aprendiz 1–3, Lodo 1–2, Arquivista 25–35), e há bolsas de prata pelas salas.
  - **Cacos de vidro:** aparecem em montes e ficam de cada pote selado que é esvaziado. O Vis dos potes selados vai primeiro para os potes do cinto e depois para a varinha.
  - **Guardar:** o que é achado numa incursão só fica guardado (`Stash`) ao voltar vivo, por uma âncora ou pela saída do Arquivo. Morrer perde os achados e o Vis dos potes, mas não os potes.
  - **HUD:** prata e cacos aparecem embaixo dos potes, somando o guardado e o achado.
  - **Conta:** uma incursão que limpa o mapa inteiro rende, em média, uns 120 de prata e 15 cacos (`tools/balance_report.gd`): uns três potes de cada jeito. Uma incursão curta, que explora só uma parte, rende um pote.
- **Descartado:**
  - **Só comprar** ou **só fabricar:** as outras opções da pergunta.
  - **Potes achados que entram no cinto:** dariam potes de graça. Agora os potes selados dão Vis e cacos.
- **Motivo:** pedido do usuário. A prata e os cacos dão um motivo para explorar os ramos laterais e os segredos do mapa.

### D070 · 2026-11-03 · Save formato 6

- **Escolha:** o save guarda, além do conhecimento, o mapa (`world`: passagens abertas, chaves, âncoras e chefes vencidos) e o que fica na escola (`stash`: materiais e potes). Saves antigos carregam com o mapa fechado e sem potes.
- **Descartado:** um arquivo separado para o mapa.
- **Motivo:** um arquivo só, legível, como antes (D009).

## M8 (aprovado pelo usuário)

### D071 · 2026-11-03 · M8: a varinha que cresce

- **Escolha:** o usuário aprovou o M8 ("pode ir para a M8") com as respostas recomendadas na proposta: os materiais achados se perdem ao morrer (já era a regra da D069), há um baú por incursão, e o trabalho para no fim do M8.
  - **Peças:** a varinha é montada com um **núcleo** (`WandCoreData`, os limites de Vis) e um par de **ponteiras** (`WandCapData`, a eficiência), como as hastes e ponteiras do Thaumcraft.
    - **Núcleos:** madeira (10/30, inicial), osso (12/36) e cristal (15/45).
    - **Ponteiras:** ferro (1,0, inicial), latão (1,25) e prata (1,5).
  - **Eficiência acumulada:** o Vis é contado em inteiros e as magias custam 1 ou 2, então dividir e arredondar para cima não pouparia nada. A varinha guarda a fração poupada (`WandState.cost_now`): com 1,25, a cada cinco disparos de 1, um sai de graça.
  - **Bancada Arcana:** fica no Salão de Estudos, com uma tela para fazer e montar as peças. Fazer gasta materiais guardados na escola e Vis da varinha, como a Bancada Arcana do Thaumcraft. Trocar entre peças que você já tem é de graça. A varinha na mão muda de cor.
  - **Pesquisa:** uma página por peça nova, com o efeito `unlock_wand_part`:
    - **Ponteiras de Latão:** Ordo, Ignis e Potentia, todos de receita livre. É a primeira peça que dá para conseguir.
    - **Núcleo de Osso:** Mortuus, Terra e Perditio.
    - **Núcleo de Cristal:** Vitreus, Praecantatio e Terra; pede a de osso.
    - **Ponteiras de Prata:** Metallum, Lux e Praecantatio; pede a de latão, em grade maior.
    - As de osso, cristal e prata pedem receitas dos livros. As abas da Mesa ganharam ordem (`order`) e quebram linha.
  - **Materiais** (`data/items/`, cada um com a cena do achado em `pickup_scene`):
    - **Osso antigo:** ruínas e Bedel (50%).
    - **Fio de latão:** ruínas e Aprendiz (35%).
    - **Lasca de cristal:** grutas.
    - **Selo do Arquivista:** o chefe deixa ao cair (`material_safe`) e vai direto para a escola, uma vez só. Saves em que ele já tinha caído recebem o selo ao carregar.
  - **Baú:** um por incursão, sorteado entre quatro lugares (cripta, gruta dos fungos, fundo da Fenda, salão invertido). Tem prata e três materiais sorteados.
  - **Ritmo:** uma incursão que limpa o mapa rende uns 6 ossos, 5 fios de latão, 6 lascas e 130 de prata. Dá para fazer uma peça a cada uma ou duas incursões.
  - **Save formato 7:** as peças feitas e as montadas.
- **Descartado:**
  - **Eficiência arredondada para cima (como antes):** não pouparia nada com os custos de 1.
  - **Varinhas inteiras como itens:** montar com peças é o que o Thaumcraft faz e dá mais combinações.
  - **Baú guardado por um inimigo a mais:** as salas com baú já têm inimigos.
- **Motivo:** fecha o ciclo do roguelike: as incursões rendem materiais, e os materiais viram uma varinha melhor na seguinte.

## M9 (aprovado pelo usuário)

### D072 · 2026-11-04 · M9: alquimia (o cadinho)

- **Escolha:** o usuário pediu para seguir para o M9. Entre as opções propostas, ficou a primeira da lista, a **alquimia**. O segundo andar da Dungeon e o acabamento continuam como opções para depois.
  - **Laboratório:** uma sala nova a leste do Salão de Estudos, com uma porta na parede leste. Tem o cadinho, uma estante de frascos, uma mesa de trabalho e o "Caderno de alquimia" (placa), que explica o uso.
  - **Cadinho (`Crucible`, em `scripts/core`):** um material guardado, jogado nele, se desfaz na essência dos aspectos dele (`ItemData.aspects`). A essência fica no cadinho entre as incursões, e a cor do caldo segue o aspecto que mais há nele.
  - **Anotar:** a essência de um aspecto já descoberto vira pontos de pesquisa (1 por 1). É uma fonte renovável de pontos, além do escaneamento, que só rende uma vez por alvo.
  - **Receitas (`data/alchemy/recipes/`):**
    - **Elixir de Victus:** Victus 3 e Aqua 2; cura 40. A tecla **F** bebe, até 5 elixires.
    - **Destilar Ignis, Aqua ou Ordo:** 3 do aspecto; 10 de Vis num pote vazio do cinto.
    - Só dá para preparar com os aspectos da receita já descobertos.
  - **Ingredientes novos:** fungo luminoso (Victus 2, Lux 1), em lugares das grutas, e tinta coagulada (Aqua 2, Cognitio 1), que cai do Lodo de Tinta (50%). Os materiais que já existiam ganharam aspectos: osso (Mortuus, Terra), cristal (Vitreus, Ordo), latão (Metallum, Ignis), vidro (Vitreus, Ignis) e prata (Metallum). O Selo do Arquivista não se dissolve.
  - **Elixires** ficam com o jogador mesmo se ele morrer, como os potes: são feitos na escola.
  - **HUD:** um frasco com a quantidade de elixires, ao lado dos potes.
  - **Save formato 8:** a essência do cadinho e os elixires.
- **Descartado:**
  - **Catalisador nas receitas,** como no Thaumcraft: seria mais um material para juntar, sem mudar o jogo agora.
  - **Fluxo** (essência que polui ao ser jogada fora): fica para quando houver distorção (ideia 7 da referência do Thaumcraft).
  - **Pontos de pesquisa direto ao dissolver:** anotar à parte deixa o jogador escolher entre pontos e receitas.
  - **Segundo andar da Dungeon agora:** era a outra opção do M9; fica para depois.
- **Motivo:** a alquimia é o centro do Thaumcraft 4. Dá uso a tudo o que é achado na Dungeon e traz a primeira cura fora da escola.

## M10 a M12 (aprovados pelo usuário: "já faça todos")

### D073 · 2026-11-06 · M10: Focus de Choque e Focus de Escavação

- **Escolha:** o usuário pediu os três marcos propostos de uma vez ("já faça todos"): Focus novos (M10), o segundo andar da Dungeon (M11) e o acabamento (M12).
  - **Focus de Choque** (tipo novo, `chain`): um raio instantâneo até a mira (16 m), com 10 de dano, por 1 de Aer.
    - **Corrente:** se acertar um inimigo, salta para o mais próximo a até 5 m, até 2 saltos, com 70% do dano do anterior.
    - **Onde fica a conta:** quem escolhe os alvos e o dano é `ChainLightning`, em `scripts/core` (testado). O raio aparece como segmentos em zigue-zague com um clarão.
    - **Fraqueza:** o Lodo de Tinta leva 50% a mais.
  - **Focus de Escavação** (projétil com `digs`): 8 de dano, por 1 de Terra; o Bedel leva 50% a mais.
    - **Paredes rachadas** (`CrackedWall`): só a Escavação derruba. As rachaduras brilham fraco, e a Lente mostra a parede. Uma delas, na câmara de pedra, esconde o **Depósito Soterrado**, um tesouro. Derrubada, fica aberta para sempre (`passage_id`, no save).
    - **Veios de cristal** (`CrystalVein`): em quatro salas das grutas. A Escavação arranca as lascas, que caem no chão para pegar. Os veios voltam a cada incursão.
  - **Pesquisa:** *Focus de Aer* (Aer, Motus, Potentia) e *Focus de Escavação* (Terra, Vitreus, Perditio), com o efeito `unlock_focus`. As abas foram reordenadas: os Focus vêm antes das peças de varinha.
  - **Vis:** Nódulo de Aer (com Perditio) na Sala do Portal e Nódulo de Terra no laboratório. Como a varinha tem limite total, o Vis que você leva decide os Focus que vai usar.
- **Descartado:**
  - **Escavação contínua (segurar para cavar), como no Thaumcraft:** um projétil reaproveita a magia que já existe e basta para paredes e veios.
  - **Choque que atravessa paredes:** o raio para no primeiro obstáculo, como os projéteis.
- **Motivo:** os Focus que faltavam do Thaumcraft 4 deixam o Vis de Aer e Terra úteis, e a Escavação dá um uso novo ao mapa (passagens e cristal).

### D074 · 2026-11-06 · M11: o segundo andar (O Observatório Afogado) e o inimigo à distância

- **Escolha:**
  - **Região nova:** `observatory`, "O Observatório Afogado". A narrativa continua descendo: a Primeira Escola baixou o observatório para baixo da terra, e lá as estrelas também olham. Quatro salas, do original:
    - **Galeria das Lentes:** lunetas quebradas e lentes que brilham.
    - **Sala dos Mapas Celestes:** mesas de mapas e uma esfera armilar.
    - **Cisterna Estelar:** água que reflete estrelas, Nódulos pequenos e a quarta âncora do portal.
    - **Cúpula Quebrada:** a grande luneta e o chefe.
    - Os materiais e luzes são novos (pedra azulada), e há estrelas pintadas no teto.
  - **Acesso:** uma grade a leste do Grande Arquivo, com `requires_defeat` = `archivist`: só abre depois que o Arquivista cai. Uma parede rachada liga a galeria direto à cúpula, um atalho para quem tem a Escavação.
  - **Inimigo à distância:** o **Olho Vigia** (`ranged` em EnemyData):
    - **Movimento:** mantém `keep_distance` (4,5 m) e atira de até 10 m, só enxergando o jogador. A regra fica em `EnemyBrain`, testada.
    - **Tiro (`EnemyShot`):** uma bola de luz lenta (7 m/s), com 10 de dano, que dá para desviar.
    - **Corpo:** `EyeRig`, um olho que flutua com nervos pendurados e cuja íris acende ao preparar o tiro.
  - **Chefe:** **O Olho do Fundo**, um olho grande:
    - **Ataque:** atira três bolas em leque e não se abala com os disparos.
    - **Fúria:** na metade da vida, fica vermelho, mais rápido e chama dois Olhos Vigias.
    - **Relíquia:** ao cair, deixa 3 fragmentos de estrela guardados direto na escola, uma vez só.
  - **Progresso:** fragmentos de estrela (material novo, também dissolvível) e o **Núcleo Estelar** (18/54), com página própria depois da de cristal. Os Olhos Vigias às vezes deixam fragmentos.
  - **Livros:** dois livros da região (o Diário do Astrônomo e o Mapa Celeste Afogado), para a região também esconder receitas.
- **Descartado:**
  - **Sortear um segundo andar:** o mapa é fixo (D068); o andar novo é feito à mão como o resto.
  - **Olho que voa de verdade (física de voo):** o corpo anda no chão e o olho flutua só no desenho. A malha de navegação continua servindo.
- **Motivo:** pedido do usuário. O andar novo dá um lugar para o Núcleo Estelar e põe à prova o Focus de Choque, contra grupos, e a Escavação, no atalho.

### D075 · 2026-11-06 · M12: acabamento (menu inicial, introdução, música, sons próprios, letras)

- **Escolha:**
  - **Menu inicial (`TitleScreen`):** abre sobre a escola pausada, sem o HUD. Continuar (ou Começar, sem save), Novo jogo, Opções e Sair.
    - **Novo jogo:** pede confirmação, apaga o save e recria conhecimento, mapa, posses e cadinho (`Game.reset_progress`). O sinal `Game.progress_reset` avisa quem guardou referência aos objetos antigos (a Mesa de Pesquisa).
    - **Testes e capturas:** `show_title` em main.gd e o argumento `--no-title` pulam o menu.
  - **Introdução (`IntroScreen`):** linhas `INTRO_1`, `INTRO_2`… de `locales/content.csv`, uma por vez, sobre fundo preto; para mudar o texto ou o número de linhas, basta mexer no CSV. Clique, E ou Esc pulam.
  - **Música:** `RoomData.music`, uma faixa por região (escola, ruínas e grutas, abismo, observatório). São geradas por `tools/generate_sounds.gd` (acordes lentos, arpejo, bordão e, em algumas, sinos; de 24 a 32 s, em laço), como os outros sons provisórios.
    - **Troca:** suave entre regiões; a mesma faixa continua de onde estava.
    - **Volume:** controle próprio nas opções, gravado em `settings.cfg`.
  - **Sons próprios:**
    - **Inimigos:** `EnemyData.sound_set` escolhe quatro sons (alerta, golpe ou tiro, dor e morte) para cada inimigo; sem o conjunto no banco, valem os genéricos.
    - **Focus:** `FocusData.cast_sound` e `impact_sound`. O gelo tem disparo e estilhaço próprios, o choque tem estalo elétrico e a escavação tem impacto de pedra.
    - **Observatório:** ambiente próprio, com um zumbido baixo e brilhos agudos que vêm e vão.
  - **Letras:** a interface passa de 10 para **11 px** (títulos de 20 para 22).
    - **Por quê:** a Pixelify Sans é desenhada numa grade de cerca de 92 unidades por ponto (em 1000). Em 11 px, cada ponto cai num pixel; em 10, os pontos ficam menores que um pixel e detalhes somem (o C virava O, o E ficava torto, o 2 parecia um 8).
    - **Ligaduras desligadas** (o "fi" virava um desenho só).
    - **Algarismos:** desenhados à mão em 5 × 7 pixels (`tools/generate_digit_font.gd` gera `assets/ui/digits_font.tres`), com a Pixelify como fonte reserva para o resto. A fonte dos algarismos também tem o espaço, porque um espaço antes de um número cai no trecho dela.
- **Descartado:**
  - **Fonte de bitmap completa (letras também):** muito trabalho para um ganho pequeno, já que em 11 px a Pixelify fica nítida.
  - **Manter 10 px e só trocar os algarismos:** o C e o E continuavam ilegíveis.
  - **Músicas de terceiros:** dependência e licença novas; as faixas geradas podem ser trocadas depois, pelo mesmo campo.
  - **Introdução em cena 3D:** é mais cara; o texto sobre fundo preto basta e é fácil de editar.
- **Motivo:** pedido do usuário ("já faça todos"). O jogo precisava de uma porta de entrada (menu, novo jogo, introdução), de som que distinga inimigos e regiões e de letras que não se confundam.

## Pendentes (aguardando o usuário)

| Nº | Decisão | Estado |
| --- | --- | --- |
| 10 | Computador de jogo | Aguardando sistema, processador e vídeo. Até lá: 240 linhas e todos os efeitos ligados por padrão |
| 11 | Referências visuais | Aguardando imagens ou descrições. Até lá: greybox com o shader PS1 |
| — | Nomes próprios dos aspectos compostos | Para a versão distribuída (como Lume, Maré… nos primais). Até lá, nomes latinos em `locales/names.csv` |
| — | Receitas do Thaumcraft | Se quiser conferir com a wiki, cole a tabela de aspectos: as receitas ficam só em `data/aspects/` |
