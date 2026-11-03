class_name PlayerData
extends Resource
## Valores de movimento do jogador. O arquivo fica em data/player/player.tres.

## Velocidade andando, em metros por segundo.
@export var walk_speed: float = 3.0
## Velocidade correndo (segurando Shift), em metros por segundo.
@export var run_speed: float = 5.0
## Quanto a velocidade muda por segundo ao começar e parar de andar.
@export var acceleration: float = 20.0
## Velocidade vertical do pulo, em metros por segundo.
@export var jump_velocity: float = 4.0
## Altura dos olhos (câmera) acima dos pés, em metros.
@export var eye_height: float = 1.6
