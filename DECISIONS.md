# Decisões

Registro de cada decisão do projeto: data, escolha, alternativa descartada e motivo.
Detalhes e comparações completas em [`docs/PROPOSTA-M0.md`](docs/PROPOSTA-M0.md).

## Tomadas

### D001 · 2026-11-03 · Tecnologia: Three.js + TypeScript + Vite, no navegador

- **Escolha:** Three.js (WebGL2) com TypeScript, Vite para desenvolvimento e build, Vitest para testes. Decisão delegada pelo usuário ("escolha a opção de ferramentas que mais se adequar").
- **Descartadas:**
  - Godot 4 + GDScript: tem editor visual e shaders PS1 prontos, mas no modo headless não renderiza, então o Claude Code na nuvem não consegue ver o jogo rodando antes de cada entrega.
  - Unity + C#: não roda no ambiente de desenvolvimento na nuvem, exige conta e editor pesado.
- **Motivo:** permite verificar cada marco rodando o jogo de verdade (Chromium headless com WebGL2, testado em 2026-11-03), roda em qualquer sistema sem instalação, deixa a lógica em TypeScript puro e testável e mantém o efeito PS1 pequeno e próprio.
- **Custo aceito:** sem editor visual de fases; colisão e demais sistemas de motor escritos por nós, no tamanho necessário.

### D002 · 2026-11-03 · Renderizador: WebGL2, não WebGPU

- **Escolha:** `WebGLRenderer` do Three.js, desenhando numa imagem de baixa resolução (padrão de 240 linhas) ampliada sem filtragem.
- **Descartada:** `WebGPURenderer`, ainda ausente ou instável em parte dos navegadores e placas.
- **Motivo:** compatibilidade máxima com computadores modestos. Os padrões serão calibrados quando o usuário informar o computador de jogo.

### D003 · 2026-11-03 · Save: armazenamento local do navegador, com exportar e importar

- **Escolha:** save em JSON legível e versionado (`formatVersion`) no armazenamento local do navegador, com botões para exportar e importar um arquivo `.json`. O save passa por uma interface de armazenamento, para que outra implementação (arquivo em disco) possa entrar sem mudar a lógica.
- **Descartadas:** File System Access API (só funciona em navegadores baseados no Chromium); empacotar como app desktop com Electron ou Tauri agora (peso e complexidade sem necessidade no recorte).
- **Motivo:** a especificação pede arquivo local legível; no navegador, exportar e importar é a forma portátil de entregar isso. Se o usuário quiser o arquivo direto no disco, o empacotamento desktop fica para depois.

### D004 · 2026-11-03 · Formato de dados: JSON validado com esquemas

- **Escolha:** um arquivo JSON por categoria (`data/aspects.json`, `data/foci.json`…) e um por sala (`data/rooms/`), validados ao carregar com esquemas `zod`, incluindo referências entre arquivos (um Focus que gasta um aspecto inexistente é um erro com mensagem clara).
- **Descartadas:** YAML (exige parser extra e tem ambiguidades de tipo); conteúdo em código TypeScript (viola o pilar 5).
- **Motivo:** JSON é lido nativamente pelo navegador e pelo Node, e a validação protege quem adiciona conteúdo sem mexer no motor.

### D005 · 2026-11-03 · Colisão própria em vez de motor de física

- **Escolha:** jogador como cilindro contra caixas alinhadas aos eixos (os blocos da sala); raios para mira e escaneamento; esferas para projéteis e inimigos.
- **Descartadas:** Rapier e cannon-es.
- **Motivo:** as salas são feitas de blocos e o recorte não tem física de objetos; algumas dezenas de linhas testáveis bastam. Um motor de física pode entrar se o jogo precisar.

### D006 · 2026-11-03 · Interface em HTML/CSS sobre o jogo

- **Escolha:** HUD, Livro de Pesquisa, Mesa e menus em HTML/CSS por cima da tela do jogo, com textos vindos de `locales/pt-BR/`.
- **Descartada:** interface desenhada dentro da cena 3D.
- **Motivo:** texto em português fácil de trocar, menus simples de fazer e de estudar.

### D007 · 2026-11-03 · Camadas `core`, `engine`, `game` e `ui`

- **Escolha:** `src/core` é lógica pura (sem Three.js nem navegador); `src/engine` é o motor genérico; `src/game` e `src/ui` ligam os dois. Um teste falha se `core` importar algo proibido.
- **Descartada:** organizar por funcionalidade misturando lógica e renderização.
- **Motivo:** a especificação exige lógica testável sem abrir o jogo.

### D008 · 2026-11-03 · Identificadores neutros; nomes exibidos em arquivo de localização

- **Escolha:** identificadores internos em inglês e neutros (`fire`, `water`…); todo nome exibido vem de `locales/pt-BR/`, e os que remetem a outras obras ficam só em `locales/pt-BR/names.json`.
- **Descartada:** usar os nomes latinos como identificadores.
- **Motivo:** trocar os nomes para uma versão distribuída vira a troca de um arquivo. A escolha dos nomes em si é a decisão 7, ainda pendente.

### D009 · 2026-11-03 · Dependências previstas

- **Escolha:** `three`, `typescript`, `vite`, `vitest`, `zod`, com versões fixas, instaladas no M1. Playwright, já presente no ambiente de desenvolvimento, só para testes de fumaça e capturas de tela.
- **Descartadas:** frameworks de interface (React, Vue) e motores de física, por não serem necessários no recorte.
- **Motivo:** o mínimo para renderizar, tipar, testar e validar dados.

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
| — | Computador de jogo | Aguardando: sistema, processador, vídeo e navegador |
| — | Referências visuais | Aguardando imagens ou descrições; até lá, greybox |
