class_name RunState
extends RefCounted
## O estado de uma incursão: vida, reserva da varinha e a magia equipada.
## Ao contrário do conhecimento, é reiniciado quando o jogador morre.

var health: Health
var wand: WandState
var caster: SpellCaster


func _init(player: PlayerData) -> void:
	health = Health.new(player.max_health)
	wand = WandState.new(player.starting_wand)
	caster = SpellCaster.new(player.starting_focus, wand)


## Começa de novo: vida e reserva cheias, magia parada.
func reset() -> void:
	health.restore()
	wand.refill_all()
	caster.cancel()
	caster.cooldown_left = 0.0
