class_name ResearchRules
extends Resource
## Regras do escaneamento e da pesquisa (no estilo do Thaumcraft 4). O arquivo fica em
## data/research/rules.tres. Os valores padrão aqui são zero de propósito: os valores reais
## ficam sempre no arquivo de dados.

## Segundos segurando o botão para completar um escaneamento.
@export var scan_duration: float = 0.0
## Distância máxima, em metros, para escanear.
@export var scan_range: float = 0.0
## Pontos de pesquisa ganhos por unidade de aspecto no primeiro escaneamento de um alvo.
## Ex.: com 2, escanear a vela (Ignis 3) rende 6 pontos de Ignis.
@export var points_per_amount: int = 0
## Pontos de cada aspecto pai gastos para combinar um aspecto composto na Mesa de Pesquisa.
@export var combine_cost: int = 0
## Pontos do aspecto composto ganhos a cada combinação.
@export var combine_yield: int = 0
