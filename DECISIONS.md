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

## Pendentes (aguardando o usuário)

Recomendações completas em [`docs/PROPOSTA-M0.md`](docs/PROPOSTA-M0.md#c-decisões-em-aberto-seção-9-da-especificação).

| Nº | Decisão | Recomendação |
| --- | --- | --- |
| 2 | Tipo da magia de fogo | Projétil com carga curta, que ilumina o caminho |
| 3 | Recarga fora da escola | Nenhuma; reserva finita por incursão |
| 4 | Morte | Salão de Estudos; conhecimento salvo no momento da descoberta |
| 5 | Estudo vira poder | Árvore leve de páginas com pré-requisitos |
| 6 | Instrumento de escaneamento | Lente Taxonômica na mão esquerda; não escaneia e lança ao mesmo tempo |
| 7 | Nomes | IDs neutros; latinos durante o desenvolvimento; Lume, Maré, Barro, Sopro, Prumo e Ruína para distribuir |
| 8 | Premissa | As Ruínas da Primeira Escola |
| 9 | Prioridade visual | Cortar dithering → afim → resolução → névoa |
| 10 | Computador de jogo | Aguardando: sistema, processador e vídeo |
| 11 | Referências visuais | Aguardando imagens ou descrições; até lá, greybox |
| 12 | Executar o Godot na nuvem | Aguardando autorização para testes e capturas de tela |
