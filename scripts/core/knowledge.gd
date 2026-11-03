class_name Knowledge
extends RefCounted
## O conhecimento do jogador: aspectos descobertos, alvos escaneados, pontos de pesquisa
## e páginas estudadas. É o progresso permanente: sobrevive à morte e vai para o save.

## Emitido a cada mudança (quem grava o save escuta este sinal).
signal changed

## Resultado da verificação antes de estudar uma página.
enum StudyCheck { OK, ALREADY_STUDIED, NOT_ENOUGH_POINTS, MISSING_PAGE, MISSING_ASPECT }

var discovered_aspects: Array[StringName] = []
var scanned_targets: Array[StringName] = []
var research_points := 0
var studied_pages: Array[StringName] = []


func knows_aspect(aspect_id: StringName) -> bool:
	return aspect_id in discovered_aspects


func has_scanned(target_id: StringName) -> bool:
	return target_id in scanned_targets


func has_studied(page_id: StringName) -> bool:
	return page_id in studied_pages


## Registra um escaneamento completo do alvo e devolve o que foi descoberto.
## Pontos: `rules.points_per_new_aspect` por aspecto novo e `rules.points_per_new_target`
## pelo primeiro escaneamento do alvo. Escanear de novo não rende nada.
func register_scan(target: ScannableData, rules: ResearchRules) -> ScanResult:
	var result := ScanResult.new()
	result.target = target
	if not has_scanned(target.id):
		result.new_target = true
		scanned_targets.append(target.id)
		result.points += rules.points_per_new_target
	for aspect_id in target.aspects:
		if not knows_aspect(aspect_id):
			discovered_aspects.append(aspect_id)
			result.new_aspects.append(aspect_id)
			result.points += rules.points_per_new_aspect
	research_points += result.points
	if result.discovered_something():
		changed.emit()
	return result


## Diz se a página pode ser estudada agora e, se não, por quê.
func check_study(page: ResearchPageData) -> StudyCheck:
	if has_studied(page.id):
		return StudyCheck.ALREADY_STUDIED
	for required in page.required_pages:
		if not has_studied(required):
			return StudyCheck.MISSING_PAGE
	for required in page.required_aspects:
		if not knows_aspect(required):
			return StudyCheck.MISSING_ASPECT
	if research_points < page.cost:
		return StudyCheck.NOT_ENOUGH_POINTS
	return StudyCheck.OK


## Estuda a página, gastando os pontos. Devolve false se não for possível.
func study(page: ResearchPageData) -> bool:
	if check_study(page) != StudyCheck.OK:
		return false
	research_points -= page.cost
	studied_pages.append(page.id)
	changed.emit()
	return true
