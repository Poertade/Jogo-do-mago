extends SceneTree
## Relatório de balanceamento: calcula, a partir de data/, os números que definem o ritmo do
## combate e da pesquisa. Útil ao ajustar valores. Rodar a partir da pasta do projeto:
##   godot --headless --path . -s tools/balance_report.gd


func _initialize() -> void:
	var db := ContentDB.new()
	db.load_all()
	if not db.errors.is_empty():
		print("Erros no conteúdo:\n  " + "\n  ".join(db.errors))
	var player := db.player
	var focus := player.starting_focus
	var wand := WandState.new(player.starting_wand)
	var cost: int = wand.effective_cost(focus.cost)
	var shots_per_reserve := wand.capacity() / maxi(cost, 1)
	var page_multiplier := 1.0
	for page: ResearchPageData in db.pages.values():
		page_multiplier *= Modifiers.from_pages([page] as Array[ResearchPageData]).damage_multiplier(focus.element)
	var cycle := focus.charge_time + focus.cooldown

	print("=== Jogador ===")
	print("Vida: %d | Reserva de Vis: %d | Custo por disparo: %d → %d disparos por reserva" % [
		player.max_health, wand.capacity(), cost, shots_per_reserve])
	print("Ciclo de disparo: %.1f s de carga + %.1f s de intervalo = %.1f s" % [focus.charge_time, focus.cooldown, cycle])
	print("Dano: %.1f (com todas as páginas: %.1f)" % [focus.damage, focus.damage * page_multiplier])

	for enemy: EnemyData in db.enemies.values():
		print("\n=== %s ===" % enemy.id)
		for with_pages in [false, true]:
			var damage := Combat.damage_against(focus.damage * (page_multiplier if with_pages else 1.0), focus.element, enemy.weaknesses)
			var shots := ceili(enemy.max_health / damage)
			print("%s: %.1f por acerto → %d acerto(s), %.1f s no mínimo; sobra(m) %d disparo(s) da reserva" % [
				"Com páginas" if with_pages else "Sem páginas", damage, shots, shots * cycle - focus.cooldown, shots_per_reserve - shots])
		var hits_to_kill_player := ceili(player.max_health / enemy.damage)
		var attack_cycle := enemy.attack_windup + enemy.attack_cooldown
		print("Golpes para derrubar o jogador: %d (um a cada %.1f s → %.0f s parado ao alcance)" % [
			hits_to_kill_player, attack_cycle, hits_to_kill_player * attack_cycle])
		print("Velocidade: inimigo %.1f m/s, jogador andando %.1f m/s e correndo %.1f m/s" % [
			enemy.move_speed, player.walk_speed, player.run_speed])

	# Pesquisa: pontos que cada aspecto rende escaneando tudo uma vez (só os valores dos objetos;
	# a ordem de descoberta e as combinações ficam por conta do jogador).
	var rules := db.research_rules
	var totals: Dictionary = {}
	for target: ScannableData in db.scannables.values() + db.enemies.values():
		for aspect_id in target.aspects:
			totals[aspect_id] = totals.get(aspect_id, 0) + target.aspects[aspect_id] * rules.points_per_amount
	print("\n=== Pesquisa ===")
	print("Aspectos: %d (%d compostos) | Escaneáveis: %d | %d ponto(s) por unidade de aspecto" % [
		db.aspects.size(), db.compounds_by_tier().size(), db.scannables.size() + db.enemies.size(), rules.points_per_amount])
	for aspect_id in totals:
		print("  %s: %d pontos escaneando tudo (nível %d)" % [aspect_id, totals[aspect_id], db.tier(aspect_id)])
	for page: ResearchPageData in db.pages.values():
		print("Página %s: nota de raio %d com %s" % [page.id, page.note_radius, page.note_aspects])
	quit()
