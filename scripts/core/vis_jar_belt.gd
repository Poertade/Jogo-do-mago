class_name VisJarBelt
extends RefCounted
## O cinto de potes de Vis: alguns potes que o jogador leva, cada um com Vis de um só aspecto.
## São uma reserva além da varinha:
## - na escola, o Vis que não cabe na varinha enquanto ele drena um Nódulo vai para os potes;
## - na Dungeon, a tecla R despeja um pote na varinha;
## - potes selados achados na Dungeon entram no cinto.
## Faz parte da incursão: ao morrer, o conteúdo se perde.

## Emitido quando algum pote muda (para o HUD).
signal changed

## Um pote: o aspecto guardado (vazio se o pote está vazio) e quanto tem.
class Jar:
	var aspect: StringName = &""
	var amount := 0

	func is_empty() -> bool:
		return amount <= 0


var capacity: int
var jars: Array[Jar] = []


## `slots`: quantos potes cabem no cinto; `jar_capacity`: quanto Vis cabe em cada pote.
func _init(slots: int, jar_capacity: int) -> void:
	capacity = jar_capacity
	for i in slots:
		jars.append(Jar.new())


## Quanto Vis do aspecto há nos potes, somando todos.
func total(aspect_id: StringName) -> int:
	var sum := 0
	for jar in jars:
		if jar.aspect == aspect_id:
			sum += jar.amount
	return sum


## Guarda Vis do aspecto: primeiro completa os potes que já têm esse aspecto, depois usa potes
## vazios. Devolve quanto coube.
func store(aspect_id: StringName, amount: int) -> int:
	var left := maxi(amount, 0)
	for pass_empty in [false, true]:
		for jar in jars:
			if left <= 0:
				break
			var fits: bool = jar.aspect == aspect_id if not pass_empty else jar.is_empty()
			if not fits:
				continue
			if jar.is_empty():
				jar.aspect = aspect_id
			var added := mini(left, capacity - jar.amount)
			jar.amount += added
			left -= added
	var stored := maxi(amount, 0) - left
	if stored > 0:
		changed.emit()
	return stored


## Cabe mais Vis deste aspecto em algum pote?
func has_room_for(aspect_id: StringName) -> bool:
	for jar in jars:
		if jar.is_empty() or (jar.aspect == aspect_id and jar.amount < capacity):
			return true
	return false


## Despeja na varinha um pote de um dos `aspects` (na ordem da lista) cujo recipiente na
## varinha ainda tenha espaço. O que não couber fica no pote. Devolve quanto Vis entrou
## (0: nenhum pote serviu).
func pour_into(wand: WandState, aspects: Array) -> int:
	for aspect_id in aspects:
		if wand.room_for(aspect_id) <= 0:
			continue
		for jar in jars:
			if jar.aspect == aspect_id and not jar.is_empty():
				var added := wand.add(aspect_id, jar.amount)
				if added <= 0:
					continue
				jar.amount -= added
				if jar.is_empty():
					jar.aspect = &""
				changed.emit()
				return added
	return 0


## Esvazia todos os potes (morte).
func clear() -> void:
	for jar in jars:
		jar.aspect = &""
		jar.amount = 0
	changed.emit()
