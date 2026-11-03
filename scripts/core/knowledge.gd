class_name Knowledge
extends RefCounted
## O conhecimento do jogador, no estilo do Thaumcraft 4: aspectos descobertos, pontos de
## pesquisa de cada aspecto, alvos escaneados e páginas estudadas. É o progresso permanente:
## sobrevive à morte e vai para o save.
##
## Regras:
## - Aspectos primais são descobertos escaneando algo que os contenha.
## - Aspectos compostos só são descobertos na Mesa de Pesquisa, combinando os dois pais.
## - Um alvo com algum composto ainda não descoberto não pode ser escaneado ("conhecimento
##   insuficiente"); depois de descobri-lo na Mesa, o escaneamento funciona.
## - O primeiro escaneamento de um alvo rende pontos de cada aspecto dele; escanear de novo
##   não rende nada.

## Emitido a cada mudança (quem grava o save escuta este sinal).
signal changed

## Resultado da verificação antes de estudar uma página.
enum StudyCheck { OK, ALREADY_STUDIED, NOT_ENOUGH_POINTS, MISSING_PAGE, MISSING_ASPECT }
## Resultado da verificação antes de combinar aspectos.
enum CombineCheck { OK, NOT_COMPOUND, UNKNOWN_PARENT, NOT_ENOUGH_POINTS }

var discovered_aspects: Array[StringName] = []
var aspect_points: Dictionary[StringName, int] = {}
var scanned_targets: Array[StringName] = []
var studied_pages: Array[StringName] = []


func knows_aspect(aspect_id: StringName) -> bool:
	return aspect_id in discovered_aspects


func points(aspect_id: StringName) -> int:
	return aspect_points.get(aspect_id, 0)


func has_scanned(target_id: StringName) -> bool:
	return target_id in scanned_targets


func has_studied(page_id: StringName) -> bool:
	return page_id in studied_pages


## Compostos do alvo que ainda não foram descobertos (impedem o escaneamento).
## `aspects` é a tabela de todos os aspectos do jogo (ContentDB.aspects).
func missing_aspects(target: ScannableData, aspects: Dictionary) -> Array[StringName]:
	var missing: Array[StringName] = []
	for aspect_id: StringName in target.aspects:
		var aspect: AspectData = aspects.get(aspect_id)
		if aspect != null and aspect.is_compound() and not knows_aspect(aspect_id):
			missing.append(aspect_id)
	return missing


## Registra um escaneamento completo do alvo e devolve o que aconteceu.
func register_scan(target: ScannableData, aspects: Dictionary, rules: ResearchRules) -> ScanResult:
	var result := ScanResult.new()
	result.target = target
	result.missing = missing_aspects(target, aspects)
	if not result.missing.is_empty():
		result.blocked = true
		return result
	if has_scanned(target.id):
		return result
	result.new_target = true
	scanned_targets.append(target.id)
	for aspect_id: StringName in target.aspects:
		if not knows_aspect(aspect_id):
			discovered_aspects.append(aspect_id)
			result.new_aspects.append(aspect_id)
		var gained: int = target.aspects[aspect_id] * rules.points_per_amount
		aspect_points[aspect_id] = points(aspect_id) + gained
		result.points[aspect_id] = gained
	changed.emit()
	return result


## Diz se o composto pode ser combinado agora e, se não, por quê.
func check_combine(compound: AspectData, rules: ResearchRules) -> CombineCheck:
	if not compound.is_compound() or compound.parents.size() != 2:
		return CombineCheck.NOT_COMPOUND
	for parent in compound.parents:
		if not knows_aspect(parent):
			return CombineCheck.UNKNOWN_PARENT
	# Os dois pais podem ser o mesmo aspecto: aí o custo dobra.
	var needed: Dictionary[StringName, int] = {}
	for parent in compound.parents:
		needed[parent] = needed.get(parent, 0) + rules.combine_cost
	for parent in needed:
		if points(parent) < needed[parent]:
			return CombineCheck.NOT_ENOUGH_POINTS
	return CombineCheck.OK


## Combina os dois pais na Mesa: gasta os pontos deles, descobre o composto (se for novo) e
## rende pontos dele. Devolve false se não for possível.
func combine(compound: AspectData, rules: ResearchRules) -> bool:
	if check_combine(compound, rules) != CombineCheck.OK:
		return false
	for parent in compound.parents:
		aspect_points[parent] = points(parent) - rules.combine_cost
	if not knows_aspect(compound.id):
		discovered_aspects.append(compound.id)
	aspect_points[compound.id] = points(compound.id) + rules.combine_yield
	changed.emit()
	return true


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
	for aspect_id in page.cost:
		if not knows_aspect(aspect_id):
			return StudyCheck.MISSING_ASPECT
		if points(aspect_id) < page.cost[aspect_id]:
			return StudyCheck.NOT_ENOUGH_POINTS
	return StudyCheck.OK


## Estuda a página, gastando os pontos. Devolve false se não for possível.
func study(page: ResearchPageData) -> bool:
	if check_study(page) != StudyCheck.OK:
		return false
	for aspect_id in page.cost:
		aspect_points[aspect_id] = points(aspect_id) - page.cost[aspect_id]
	studied_pages.append(page.id)
	changed.emit()
	return true
