class_name ResearchRules
extends Resource
## Regras do escaneamento e da pesquisa. O arquivo fica em data/research/rules.tres.
## Os valores padrão aqui são zero de propósito: os valores reais ficam sempre no arquivo de dados.

## Segundos segurando o botão para completar um escaneamento.
@export var scan_duration: float = 0.0
## Distância máxima, em metros, para escanear.
@export var scan_range: float = 0.0
## Pontos de pesquisa por aspecto descoberto pela primeira vez.
@export var points_per_new_aspect: int = 0
## Pontos de pesquisa extras por alvo escaneado pela primeira vez, mesmo sem aspecto novo.
@export var points_per_new_target: int = 0
