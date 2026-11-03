class_name PlayerData
extends Resource
## Valores de movimento do jogador. O arquivo fica em data/player/player.tres.
## Os valores padrão aqui são zero de propósito: os valores reais ficam sempre no arquivo de dados.

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
