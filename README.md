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

Three.js + TypeScript + Vite, rodando no navegador (WebGL2). Motivos em [`DECISIONS.md`](DECISIONS.md#d001--2026-11-03--tecnologia-threejs--typescript--vite-no-navegador).

## Como executar

A partir do M1:

```sh
npm install
npm run dev    # abre o jogo no navegador
npm test       # roda os testes da lógica
```

## Como estender o jogo

Adicionar um aspecto, um Focus, um inimigo ou uma sala será documentado aqui no M5. O conteúdo ficará em `data/` e os textos em `locales/pt-BR/`, sem mexer no motor.
