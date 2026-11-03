class_name EntrancePoint
extends Marker3D
## Ponto onde o jogador aparece ao entrar na sala. A seta azul (eixo -Z) indica para onde ele olha.
## Portais e saídas de outras salas apontam para uma entrada pelo `id`.

@export var id: StringName = &"default"
