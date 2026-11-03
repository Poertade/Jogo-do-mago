class_name RunState
extends RefCounted
## O estado de uma incursão: vida, reserva da varinha e a magia equipada.
## Ao contrário do conhecimento, é reiniciado quando o jogador morre.

var health: Health
var wand: WandState
var caster: SpellCaster
var _player: PlayerData


func _init(player: PlayerData) -> void:
	_player = player
	health = Health.new(player.max_health)
	wand = WandState.new(player.starting_wand, player.starting_vis)
	caster = SpellCaster.new(player.starting_focus, wand)


## Começa de novo: vida cheia, a varinha com o Vis inicial e a magia parada.
func reset() -> void:
	health.restore()
	wand.reset(_player.starting_vis)
	caster.cancel()
	caster.cooldown_left = 0.0
