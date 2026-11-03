class_name PlayerData
extends Resource
## Valores do jogador: vida, equipamento inicial e movimento. O arquivo fica em
## data/player/player.tres. Os valores padrão aqui são zero de propósito: os valores reais
## ficam sempre no arquivo de dados.

## Vida máxima (e vida no começo de cada incursão).
@export var max_health: int = 0
## Varinha e Focus com que o jogador começa.
@export var starting_wand: WandData
@export var starting_focus: FocusData
## Vis na varinha no começo de cada incursão (e ao despertar depois de morrer), por aspecto.
@export var starting_vis: Dictionary[StringName, int] = {}
## Quantos potes de Vis cabem no cinto (o jogador começa sem nenhum: compra ou fabrica na
## escola) e quanto Vis cabe em cada um.
@export var jar_slots: int = 0
@export var jar_capacity: int = 0

@export_group("Movimento")
## Velocidade andando, em metros por segundo.
@export var walk_speed: float = 0.0
## Velocidade correndo (segurando Shift), em metros por segundo.
@export var run_speed: float = 0.0
## Quanto a velocidade muda por segundo ao começar e parar de andar.
@export var acceleration: float = 0.0
## Velocidade vertical do pulo, em metros por segundo.
@export var jump_velocity: float = 0.0
## Altura dos olhos (câmera) acima dos pés, em metros.
@export var eye_height: float = 0.0
## Distância máxima, em metros, para interagir (E) com mesas, portais etc.
@export var interact_range: float = 0.0
