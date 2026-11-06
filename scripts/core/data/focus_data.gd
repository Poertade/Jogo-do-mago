class_name FocusData
extends Resource
## Um Focus: define qual magia sai da varinha, quanto custa e como se comporta.
## Cada Focus é um arquivo em data/foci/.
## Os valores padrão aqui são vazios de propósito: os valores reais ficam no arquivo de dados.

## Tipos de magia conhecidos pelo motor.
const SPELL_PROJECTILE := &"projectile"
const SPELL_CHAIN := &"chain"
const SPELL_TYPES: Array[StringName] = [SPELL_PROJECTILE, SPELL_CHAIN]

@export var id: StringName
## Chave de tradução do nome (em locales/content.csv).
@export var name_key: String
## Tipo de magia. "projectile": carrega e lança um projétil. "chain": um raio instantâneo que
## acerta o que está na mira e salta para os inimigos próximos (Focus de Choque).
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

@export_group("Efeito no alvo")
## Velocidade do alvo atingido, como fração da normal (1 = sem efeito; 0,45 = anda a 45%).
@export var slow_factor: float = 1.0
## Por quantos segundos o alvo fica lento.
@export var slow_seconds: float = 0.0

## Ligado: o projétil escava (quebra paredes rachadas e extrai veios de cristal), como o Focus
## de Escavação do Thaumcraft.
@export var digs := false

@export_group("Corrente (tipo chain)")
## Alcance do raio, em metros.
@export var chain_range: float = 0.0
## Quantos saltos para outros inimigos, a até `chain_jump_range` metros cada.
@export var chain_jumps: int = 0
@export var chain_jump_range: float = 0.0
## Fração do dano que cada salto mantém (0,7 = 70% do anterior).
@export var chain_falloff: float = 1.0

@export_group("Projétil")
## Velocidade, em metros por segundo.
@export var projectile_speed: float = 0.0
## Segundos até o projétil se apagar sozinho.
@export var projectile_lifetime: float = 0.0
## Sons do disparo e do impacto (nomes do banco de sons).
@export var cast_sound: StringName = &"spell_cast"
@export var impact_sound: StringName = &"fire_impact"
## Cor e força da luz que o projétil (ou o raio) leva.
@export var light_color: Color = Color.BLACK
@export var light_energy: float = 0.0
@export var light_range: float = 0.0
