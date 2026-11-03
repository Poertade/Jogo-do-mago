# Jogo 3D do cientista mágico: prompt para o Claude Code

## 1. Contexto e objetivo

Você vai construir, em etapas, um jogo single-player em 3D e primeira pessoa, do gênero roguelike dungeon crawler, com gráficos no estilo PS1 (baixo poly, baixa resolução) e atmosfera de fantasia sombria, tendo Lunacid como referência visual. O jogador é um cientista mágico cuja missão é descobrir os aspectos de tudo o que o cerca, no espírito do mod Thaumcraft: cada objeto e criatura é feito de aspectos que podem ser escaneados, estudados e usados.

O ciclo do jogo é:

1. O jogador começa na escola de magia, que é o lobby. A escola é inspirada na Escola de Huppermagia de Wakfu.
2. Na escola ele estuda o que descobriu, prepara a varinha e o Focus e entra em um portal.
3. A Dungeon só é acessível por esse portal. Lá ele explora, enfrenta inimigos e escaneia o que encontra.
4. Ao morrer, ele volta para a escola, mantendo o conhecimento adquirido.

As magias saem pela varinha escolhida e pelo Focus, como em Thaumcraft: a varinha define a reserva e a eficiência da energia mágica, e o Focus define qual magia sai dela.

**Este primeiro entregável é propositalmente pequeno** (seção 5): duas salas da escola (uma delas a do portal), uma magia de fogo, a mecânica do portal, o estudo de aspectos e uma única sala de Dungeon com um inimigo. Tudo o que não está na seção 5 fica para depois, mas a arquitetura deve estar preparada para crescer.

## 2. Como trabalhar

- Antes de escrever código, leia este documento inteiro e responda com: (a) proposta de tecnologia, (b) arquitetura em módulos, (c) as perguntas da seção 9, cada uma com a sua recomendação. Aguarde a resposta do usuário.
- Depois, entregue por marcos (seção 10). Cada marco deve rodar, ter testes onde houver lógica e deixar o README atualizado.
- Registre cada decisão em DECISIONS.md: data, escolha, alternativa descartada e motivo.
- Dúvida pequena: decida, registre e siga. Dúvida que muda o jogo, a tecnologia ou o escopo: pergunte antes.
- Ao fim de cada marco, resuma em poucas linhas, em português, o que ficou pronto e como executar. Não recapitule os passos.
- Comentários no código em PT-BR; identificadores em inglês. Código simples de ler, pois o usuário vai estudar e modificar o projeto.

## 3. Pilares do jogo

1. O conhecimento é o progresso permanente: a morte custa o que foi coletado na incursão, nunca o que foi descoberto.
2. Tudo no mundo é feito de aspectos: objetos, cenário e inimigos têm aspectos que o jogador pode escanear.
3. Magia por composição: varinha, Focus e aspecto formam a magia. Uma magia gasta a energia de um aspecto específico.
4. Atmosfera antes de espetáculo: ritmo lento, tensão, pouca luz, visual de PS1.
5. Conteúdo fora do código: aspectos, varinhas, Focus, inimigos e salas ficam em arquivos de dados, para ampliar o jogo sem mexer no motor.
6. Pequeno primeiro: um recorte completo e jogável vale mais que muitos sistemas pela metade.

## 4. Direção de arte e atmosfera

- Referência: Lunacid. Primeira pessoa, mundo de baixo detalhe de propósito, ambientes de fantasia sombria. Os nomes, mapas, texturas e personagens de Lunacid não devem ser copiados.
- Polígonos poucos, texturas pequenas sem filtragem nem mipmaps, resolução interna baixa (por exemplo 320x240 ou proporção 16:9 com altura semelhante, ampliada em pixels nítidos).
- Efeitos típicos do PS1, todos com opção de ligar e desligar: vertex snapping (vértices “tremendo” numa grade), mapeamento afim de textura (texturas que deformam em polígonos grandes), cor limitada com dithering e névoa para limitar a visão. Iluminação o mais simples possível.
- Filtros visuais opcionais nas configurações (por exemplo, um PS1 mais “crocante” e um modo mais limpo), para o jogador ajustar o desconforto e o desempenho.
- Fantasia sombria: paleta fria e dessaturada, fontes de luz escassas (velas, tochas, cristais, a magia do próprio jogador), sons de ambiente em vez de música constante.
- A escola é o contraste: um lugar de estudo, mais aconchegante, mas ainda sombrio. Elementos a explorar a partir da escola de Wakfu: salão de entrada, dormitórios, estufa, andar superior e passagens secretas. No primeiro entregável, apenas duas salas.
- Peça ao usuário imagens ou descrições de referência da escola e de Lunacid antes de definir paleta e arquitetura. Enquanto não as tiver, use blocos simples (greybox) com o shader PS1 aplicado.
- Assets: gere formas simples por código ou use apenas assets livres, listados em CREDITS.md. O foco do primeiro marco é jogabilidade e sistemas, não arte final.

## 5. Escopo do primeiro entregável

Implemente exatamente o que está abaixo, nem mais nem menos.

**5.1 Escola: duas salas em primeira pessoa**

- Salão de Estudos: onde o jogador começa e reaparece depois de morrer. Contém a Mesa de Pesquisa (onde se estuda), seis objetos escaneáveis (tabela da seção 6) e um ponto de recarga de Ignis (por exemplo, um braseiro).
- Sala do Portal: contém o portal para a Dungeon, interagível. Uma porta ou corredor liga as duas salas.
- Ambas com iluminação fraca, geometria simples e o visual PS1 da seção 4.

**5.2 Jogador**

- Movimento em primeira pessoa (andar, olhar com o mouse, interagir). Pulo e corrida apenas se forem baratos de implementar.
- HUD mínimo: vida, reserva de Ignis da varinha e indicador de escaneamento.

**5.3 Varinha, Focus e a magia de fogo**

- O jogador começa com uma varinha e um Focus de Fogo já equipados.
- A varinha tem reserva de energia por aspecto primal. Neste marco só a reserva de Ignis é usada.
- A magia de fogo sai visualmente pela ponta da varinha, gasta Ignis, causa dano de fogo e tem tempo de carga curto, no espírito das magias carregadas de Lunacid. O tipo exato (projétil, cone ou híbrido) é a decisão 2 da seção 9.
- A reserva se recarrega no ponto de recarga do Salão de Estudos (a regra fora da escola é a decisão 3).
- Varinha e Focus são dados: trocar por outros no futuro não deve exigir mudar código do motor.

**5.4 Aspectos e estudo**

- Instrumento de escaneamento (nome original; decisão 6): ao mirar um objeto ou inimigo e segurar o botão, uma barra enche e, ao completar, os aspectos do alvo são revelados e registrados no Livro de Pesquisa.
- Seis aspectos primais nos dados (tabela da seção 6). Aspectos compostos ficam para depois, mas o formato de dados já deve prever aspectos formados por dois outros.
- Primeiro escaneamento de algo novo rende pontos de pesquisa; escanear de novo não rende.
- Estudar: na Mesa de Pesquisa, o jogador gasta pontos para liberar uma página de pesquisa. Neste marco existe uma única página, “Compreensão de Ignis”, com benefício permanente simples e visível (por exemplo, mais dano de fogo). O Code pode propor outra, desde que seja permanente e perceptível.
- Aspectos descobertos e páginas estudadas persistem em arquivo local legível e sobrevivem à morte e ao fechamento do jogo.

**5.5 Portal**

- Na Sala do Portal, interagir com o portal faz uma transição curta (efeito no estilo do jogo) e carrega a Dungeon. Não existe outra forma de chegar à Dungeon.
- O destino do portal é um dado (identificador de sala), para que no futuro ele leve a salas geradas.

**5.6 Dungeon: uma sala, um inimigo**

- Uma câmara de pedra, escura, com o jogador surgindo em um ponto e um inimigo.
- Inimigo simples e original, corpo a corpo, lento, com IA de três estados (parado, perseguindo, atacando), vida, reação ao dano e morte. Sugestão: um morto-vivo ligado à escola, fraco a fogo. Seus aspectos podem ser escaneados.
- Ao derrotar o inimigo, abre-se uma saída que leva de volta à escola.
- A sala deve ser construída como módulo reutilizável (pontos de entrada, saída e geração de inimigos definidos por dados), pensando em gerar Dungeons por combinação de salas no futuro.

**5.7 Morte**

- Se a vida do jogador chegar a zero, uma transição o leva de volta ao Salão de Estudos. Conhecimento e páginas estudadas permanecem; o estado da incursão (vida, reserva, inimigo) é reiniciado.

**5.8 Fora do escopo agora**

Geração procedural, mais de uma sala de Dungeon, itens, saque, inventário, loja, mais de um Focus ou varinha, aspectos compostos, NPCs e diálogos, história, música final, menus além do básico.

## 6. Dados e valores iniciais

Todo o conteúdo abaixo deve morar em arquivos de dados (proponha o formato). O Code define o esquema, que deve cobrir pelo menos: aspecto (identificador, nome, tipo primal ou composto, aspectos pais, cor), objeto escaneável (aspectos e quantidades), varinha (reserva máxima por aspecto, eficiência), Focus (magia, custo por aspecto, carga, recarga, dano, elemento), inimigo (vida, dano, velocidade, aspectos, fraquezas), sala (cena, pontos de entrada e saída, spawns) e página de pesquisa (custo, efeito, requisitos).

Aspectos primais e objetos sugeridos para escanear na escola:

| Aspecto | Significado | Objeto sugerido | Quantidade |
| --- | --- | --- | --- |
| Ignis | fogo | Vela e braseiro | 3 |
| Aqua | água | Jarro d’água | 2 |
| Terra | terra | Vaso com terra ou pedra do piso | 2 |
| Aer | ar | Pena sobre a mesa | 1 |
| Ordo | ordem | Livro ou relógio de bancada | 2 |
| Perditio | entropia, decadência | Osso, teia ou trapo velho | 2 |

Valores iniciais de balanceamento (todos ajustáveis em dados):

| Item | Valor inicial |
| --- | --- |
| Vida do jogador | 100 |
| Reserva máxima de Ignis na varinha | 30 |
| Custo de um disparo de fogo | 5 de Ignis |
| Dano base do fogo | 15 |
| Tempo de carga do disparo | 0,6 s |
| Intervalo entre disparos | 0,4 s |
| Vida do inimigo | 40 |
| Dano do inimigo por golpe | 10 |
| Multiplicador de dano de fogo contra o inimigo | 1,5 |
| Duração do escaneamento | 1,5 s |
| Pontos de pesquisa por aspecto novo descoberto | 1 |
| Custo da página “Compreensão de Ignis” | 3 pontos |
| Efeito dessa página | +20% de dano de fogo |

## 7. Controles e interface

Ponto de partida sugerido, ajustável:

- Teclado e mouse: WASD para mover, mouse para olhar, E para interagir, botão esquerdo (segurar para carregar, soltar para lançar) para a magia, botão direito (segurar) para escanear, Tab para o Livro de Pesquisa, Esc para pausa e opções. Controle (gamepad) fica para depois.
- Livro de Pesquisa: lista dos aspectos descobertos, dos objetos já escaneados e das páginas estudadas.
- Opções: ligar e desligar cada efeito PS1, escolher o filtro visual, resolução interna, sensibilidade do mouse e volume.
- Todo texto de interface em PT-BR, em arquivos de localização separados do código.

## 8. Requisitos técnicos

- Pode utilizar as dependências que precisar, cada uma justificada em DECISIONS.md.
- Separe a lógica do jogo (aspectos, varinha, magias, pesquisa, persistência) das cenas e da renderização. A lógica deve ser testável sem abrir o jogo. Escreva testes para: descoberta de aspectos, pontos de pesquisa, custo e recarga de magia e persistência.
- Persistência em arquivo legível (por exemplo, JSON) com número de versão do formato.
- A simulação aceita uma semente aleatória, para testes e para reproduzir erros.
- Os efeitos PS1 devem ser leves; antes de escolher o renderizador, pergunte ao usuário qual sistema operacional e qual computador ele usará para jogar.
- Git desde o início, com um commit por marco no mínimo.
- README com instruções para executar o jogo e para adicionar um aspecto, um Focus, um inimigo e uma sala.

## 9. Decisões em aberto

Para cada item, apresente as opções, a sua recomendação e aguarde a escolha do usuário antes de implementar o que depende dela.

1. Tecnologia. Avalie de 2 a 3 opções considerando o visual PS1, a primeira pessoa e o desempenho no computador do usuário. Candidatas: Godot 4 com GDScript (já existem shaders PS1 prontos e livres para ele) e Unity com C#, além de uma terceira a seu critério.
2. Tipo da magia de fogo: projétil com carga curta (sugestão, por combinar com Lunacid), cone contínuo (como o Focus de Fogo de Thaumcraft) ou híbrido.
3. Recarga da varinha fora da escola: nenhuma, com reserva finita por incursão (sugestão, por criar tensão de roguelike), lenta e contínua, ou por fontes de energia dentro da Dungeon.
4. Morte: renascer no Salão de Estudos ou na Sala do Portal, e o que se perde. Sugestão: renascer no Salão de Estudos, perder tudo o que foi coletado na incursão (ainda não há itens) e manter o conhecimento.
5. Como o estudo vira poder: páginas isoladas (como neste marco), árvore de pesquisa, ou combinação de aspectos para formar aspectos compostos, como em Thaumcraft.
6. Instrumento de escaneamento: nome, aparência (lente, monóculo, livro) e se ocupa a mão da varinha.
7. Nomes. Dos seis aspectos (manter os nomes latinos ou criar nomes próprios), da escola e do jogo. Mantenha tudo o que remeta a outras obras (Huppermagia, Wakfu, Thaumcraft, Lunacid) em um único arquivo de texto, fácil de trocar; use nomes originais em qualquer versão distribuída.
8. Premissa narrativa: proponha 3 premissas de 3 linhas sobre por que a escola, o portal e a Dungeon existem. Implemente apenas texto mínimo neste marco.
9. Prioridade visual: se o desempenho exigir cortes, o que reduzir primeiro (mapeamento afim, dithering, resolução interna, névoa).

## 10. Marcos e critérios de aceite

Todo marco termina executável, com testes passando onde houver lógica, README e DECISIONS.md atualizados e um commit.

| Marco | Entrega | Critério de aceite |
| --- | --- | --- |
| M0 | Proposta de tecnologia, arquitetura e respostas à seção 9. Nenhum código do jogo. | O usuário aprova a proposta. |
| M1 | Esqueleto jogável: movimento em primeira pessoa em uma sala de teste com o visual PS1 (resolução baixa, vertex snapping, mapeamento afim, névoa) e menu de opções gráficas. | Andar pela sala com o visual estável e ligar e desligar cada efeito. |
| M2 | Escola: duas salas, interação, escaneamento dos seis objetos, Livro de Pesquisa, Mesa de Pesquisa com a página única e persistência. | Escanear, estudar, fechar e reabrir o jogo mantendo o conhecimento. |
| M3 | Varinha e Focus de Fogo: disparo pela ponta da varinha, HUD de Ignis e recarga. | Disparar, esgotar a reserva e recarregar no ponto da escola. |
| M4 | Portal e Dungeon: portal, sala com um inimigo escaneável, morte que volta à escola e saída ao vencer. | Ciclo completo: escola, portal, combate, vitória ou morte, escola. |
| M5 | Acabamento do recorte: sons provisórios, ajuste de balanceamento e README de extensão. | Seguindo o README, é possível adicionar um inimigo ou um aspecto sem mexer no motor. |

## 11. O que não fazer

- Não copiar assets, textos, nomes, mapas ou personagens de Lunacid, Wakfu ou Thaumcraft: eles inspiram, não fornecem conteúdo.
- Não implementar nada fora da seção 5 antes de o usuário aprovar o recorte.
- Não deixar conteúdo (valores, textos, aspectos) fixo no código.
- Não avançar de marco sem a aprovação do usuário nas decisões da seção 9 de que o marco depende.
- Não acrescentar dependências sem justificar.
