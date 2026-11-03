# Instruções para o Claude Code

- A especificação do projeto está em `docs/ESPECIFICACAO.md`; a proposta aprovada (ou em aprovação), em `docs/PROPOSTA-M0.md`. Leia as duas antes de começar um marco.
- Trabalhe por marcos (seção 10 da especificação). Não avance de marco sem a aprovação do usuário nas decisões de que ele depende (`DECISIONS.md`, seção "Pendentes").
- Registre toda decisão em `DECISIONS.md`: data, escolha, alternativa descartada e motivo. Dependência nova só com justificativa ali.
- Motor: Godot 4.7.2, GDScript com tipos, renderizador Compatibility.
- Comentários e textos em PT-BR; identificadores em inglês. Código simples de ler: o usuário vai estudar e modificar o projeto.
- Conteúdo (valores, textos, aspectos) só em `data/`, nas cenas de sala e em `locales/`, nunca fixo no código.
- `scripts/core` é lógica pura: só `RefCounted` e `Resource`, sem nós, árvore de cena ou entrada.
- Cada marco termina executável, com testes passando, README e DECISIONS.md atualizados e um commit. Antes de entregar, rode os testes (GUT em modo headless) e, se o ambiente permitir, uma captura de tela do jogo.
- Ao fim de cada marco, resuma em poucas linhas, em português, o que ficou pronto e como executar.
