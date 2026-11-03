# Instruções para o Claude Code

- A especificação do projeto está em `docs/ESPECIFICACAO.md`; a proposta aprovada, em `docs/PROPOSTA-M0.md`. Leia as duas antes de começar um marco.
- Trabalhe por marcos (seção 10 da especificação). Não avance de marco sem a aprovação do usuário nas decisões de que ele depende (`DECISIONS.md`, seção "Pendentes"). Exceção: o usuário autorizou seguir do M2 ao M5 sem aprovação intermediária (D020); depois do M5, volte a pedir aprovação.
- Direção de arte: `docs/REFERENCIAS-VISUAIS.md`.
- Registre toda decisão em `DECISIONS.md`: data, escolha, alternativa descartada e motivo. Dependência nova só com justificativa ali.
- Motor: Godot 4.7.2, GDScript com tipos, renderizador Compatibility.
- Comentários e textos em PT-BR; identificadores em inglês. Código simples de ler: o usuário vai estudar e modificar o projeto.
- Conteúdo (valores, textos, aspectos) só em `data/`, nas cenas de sala e em `locales/`, nunca fixo no código.
- `scripts/core` é lógica pura: só `RefCounted` e `Resource`, sem nós, árvore de cena ou entrada (o teste `test_core_purity.gd` garante).
- Cada marco termina executável, com testes passando, README e DECISIONS.md atualizados e um commit. Antes de entregar, rode os testes e confira capturas de tela do jogo.
- Ao fim de cada marco, resuma em poucas linhas, em português, o que ficou pronto e como executar.

## Rodar o Godot na nuvem

O usuário autorizou executar o Godot oficial no ambiente de desenvolvimento (D011). Se o executável não estiver no ambiente:

```sh
curl -sSL -o godot.zip https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip
unzip godot.zip   # gera Godot_v4.7.2-stable_linux.x86_64
```

Com `G` sendo o caminho do executável, a partir da pasta do projeto:

```sh
$G --headless --path . --import                                  # importa texturas, textos e scripts novos
$G --headless --path . -s addons/gut/gut_cmdln.gd                 # testes
xvfb-run -a -s "-screen 0 1280x720x24" $G --rendering-driver opengl3 --resolution 1280x720 \
  --path . -- --screenshot=/caminho/captura.png                   # captura de tela (OpenGL por software)
```

Para testes de jogabilidade, um script `extends SceneTree` rodado com `-s` pode instanciar `scenes/main.tscn`, simular ações com `Input.action_press` e salvar capturas com `root.get_texture().get_image()`. Os autoloads (Content, Settings) são carregados também nesse modo.
