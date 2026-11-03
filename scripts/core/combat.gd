class_name Combat
extends RefCounted
## Regras de dano entre atacante e alvo.


## Dano final contra um alvo com fraquezas (elemento → multiplicador, ex.: fire = 1.5).
static func damage_against(base_damage: float, element: StringName, weaknesses: Dictionary) -> float:
	return base_damage * float(weaknesses.get(element, 1.0))
