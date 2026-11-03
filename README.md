# Jogo do Mago

Roguelike dungeon crawler em 3D e primeira pessoa, com visual de PS1 e fantasia sombria. Você é um cientista mágico: escaneia tudo o que encontra para descobrir seus aspectos, estuda na escola de magia e desce à Dungeon por um portal. Ao morrer, volta à escola com o conhecimento intacto.

"Jogo do Mago" é o nome provisório, até a decisão 7 (nomes).

## Estado

**M0: proposta.** Ainda não há código do jogo.

| Documento | Conteúdo |
| --- | --- |
| [`docs/ESPECIFICACAO.md`](docs/ESPECIFICACAO.md) | especificação completa do projeto |
| [`docs/PROPOSTA-M0.md`](docs/PROPOSTA-M0.md) | tecnologia, arquitetura e decisões em aberto |
| [`DECISIONS.md`](DECISIONS.md) | registro das decisões tomadas e pendentes |

## Tecnologia

Godot 4.7 com GDScript, programa de desktop (Windows, Linux e macOS). Motivos em [`DECISIONS.md`](DECISIONS.md#d001--2026-11-03--tecnologia-godot-47-com-gdscript-programa-de-desktop).

## Como executar

A partir do M1:

1. Baixe o [Godot 4.7.2](https://godotengine.org/download/) (versão padrão, não a .NET). É um executável, sem instalação.
2. Abra o Godot, clique em **Importar** e escolha o arquivo `project.godot` desta pasta.
3. Aperte **F5** para jogar.

Os executáveis exportados entram no fim do recorte (M5).

## Como estender o jogo

Adicionar um aspecto, um Focus, um inimigo ou uma sala será documentado aqui no M5. O conteúdo ficará em `data/` (arquivos `.tres`, editáveis no inspetor do Godot) e os textos em `locales/`, sem mexer no motor.
