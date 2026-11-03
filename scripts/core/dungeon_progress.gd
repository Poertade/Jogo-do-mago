class_name DungeonProgress
extends RefCounted
## O que o jogador já mudou no mapa fixo da Dungeon, para sempre (vai para o save, como o
## conhecimento): atalhos abertos, portas destrancadas, paredes falsas desfeitas, chaves
## achadas, âncoras do portal sintonizadas e chefes vencidos.
## Cada peça do mapa tem um identificador único (ex.: &"dorm_gate"), definido na cena do mapa.

## Emitido a cada mudança (quem grava o save escuta este sinal).
signal changed

## Passagens abertas: portões de atalho, portas trancadas e paredes falsas.
var open_passages: Array[StringName] = []
## Chaves que o jogador tem.
var keys: Array[StringName] = []
## Âncoras do portal sintonizadas (lugares aonde o portal da escola pode levar).
var anchors: Array[StringName] = []
## Chefes vencidos (não voltam nas próximas incursões).
var defeated: Array[StringName] = []


func is_open(passage_id: StringName) -> bool:
	return passage_id in open_passages


## Abre uma passagem. Devolve false se ela já estava aberta.
func open(passage_id: StringName) -> bool:
	return _add(open_passages, passage_id)


func has_key(key_id: StringName) -> bool:
	return key_id in keys


## Guarda uma chave. Devolve false se o jogador já a tinha.
func take_key(key_id: StringName) -> bool:
	return _add(keys, key_id)


func is_attuned(anchor_id: StringName) -> bool:
	return anchor_id in anchors


## Sintoniza uma âncora do portal. Devolve false se ela já estava sintonizada.
func attune(anchor_id: StringName) -> bool:
	return _add(anchors, anchor_id)


func is_defeated(enemy_id: StringName) -> bool:
	return enemy_id in defeated


## Registra um chefe vencido. Devolve false se ele já estava registrado.
func defeat(enemy_id: StringName) -> bool:
	return _add(defeated, enemy_id)


func _add(list: Array[StringName], id: StringName) -> bool:
	if id == &"" or id in list:
		return false
	list.append(id)
	changed.emit()
	return true
