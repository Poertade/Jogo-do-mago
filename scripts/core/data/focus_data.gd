class_name FocusData
extends Resource
## Um Focus: define qual magia sai da varinha, quanto custa e como se comporta.
## Cada Focus é um arquivo em data/foci/.
## Os valores padrão aqui são vazios de propósito: os valores reais ficam no arquivo de dados.

## Tipos de magia conhecidos pelo motor.
const SPELL_PROJECTILE := &"projectile"
const SPELL_TYPES: Array[StringName] = [SPELL_PROJECTILE]

@export var id: StringName
## Chave de tradução do nome (em locales/content.csv).
@export var name_key: String
## Tipo de magia. "projectile": carrega e lança um projétil.
@export var spell_type: StringName
## Elemento do dano (um identificador de aspecto, ex.: fire). Inimigos podem ser fracos a ele.
@export var element: StringName
## Vis gasto por disparo, por aspecto (ex.: fire = 2 tira 2 do recipiente de Ignis).
@export var cost: Dictionary[StringName, int] = {}

@export_group("Tempo e dano")
## Segundos segurando o botão até a magia ficar pronta.
@export var charge_time: float = 0.0
## Segundos depois de um disparo até poder carregar de novo.
@export var cooldown: float = 0.0
## Dano base, antes das páginas de pesquisa e das fraquezas do alvo.
@export var damage: float = 0.0

@export_group("Projétil")
## Velocidade, em metros por segundo.
@export var projectile_speed: float = 0.0
## Segundos até o projétil se apagar sozinho.
@export var projectile_lifetime: float = 0.0
## Cor e força da luz que o projétil leva (ele ilumina o caminho).
@export var light_color: Color = Color.BLACK
@export var light_energy: float = 0.0
@export var light_range: float = 0.0
