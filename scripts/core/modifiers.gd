class_name Modifiers
extends RefCounted
## Soma dos efeitos permanentes das páginas estudadas.
## Efeitos do mesmo tipo e elemento se multiplicam (duas páginas de +20% = ×1,44).

var _damage_multipliers: Dictionary[StringName, float] = {}
## Focus liberados pelas páginas, na ordem em que as páginas foram estudadas.
var unlocked_foci: Array[FocusData] = []
## Núcleos e ponteiras de varinha liberados pelas páginas (podem ser feitos na Bancada Arcana).
var unlocked_parts: Array[Resource] = []


static func from_pages(pages: Array[ResearchPageData]) -> Modifiers:
	var modifiers := Modifiers.new()
	for page in pages:
		for effect in page.effects:
			modifiers._add(effect)
	return modifiers


## Multiplicador de dano do elemento (1.0 se nenhuma página o afeta).
func damage_multiplier(element: StringName) -> float:
	return _damage_multipliers.get(element, 1.0)


func _add(effect: PageEffect) -> void:
	if effect.type == PageEffect.DAMAGE_MULTIPLIER:
		_damage_multipliers[effect.element] = damage_multiplier(effect.element) * effect.value
	elif effect.type == PageEffect.UNLOCK_FOCUS and effect.focus != null and not effect.focus in unlocked_foci:
		unlocked_foci.append(effect.focus)
	elif effect.type == PageEffect.UNLOCK_WAND_PART and effect.wand_part != null and not effect.wand_part in unlocked_parts:
		unlocked_parts.append(effect.wand_part)
