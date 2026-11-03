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
	# A varinha com os recipientes que o Focus usa cheios (o máximo que um nódulo enche).
	var full := {}
	for aspect_id in focus.cost:
		full[aspect_id] = player.make_wand().aspect_capacity
	var wand := WandState.new(player.make_wand(), full)
	var cost := wand.effective_cost(focus.cost)
	var shots_per_reserve := wand.casts_available(focus.cost)
	var start_shots := WandState.new(player.make_wand(), player.starting_vis).casts_available(focus.cost)
	var page_multiplier := 1.0
	for page: ResearchPageData in db.pages.values():
		page_multiplier *= Modifiers.from_pages([page] as Array[ResearchPageData]).damage_multiplier(focus.element)
	var cycle := focus.charge_time + focus.cooldown

	print("=== Jogador ===")
	print("Vida: %d | Varinha: %d por recipiente, %d no total | Custo por disparo: %s" % [
		player.max_health, wand.aspect_capacity(), wand.total_capacity(), cost])
	print("Disparos com os recipientes do Focus cheios: %d | no começo da incursão: %d" % [shots_per_reserve, start_shots])
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
	_incursion_report(db)
	quit()


## Mapa da Dungeon: quantos inimigos e disparos cada sala pede, em média (pela chance de cada
## EnemySpawn e pelo sorteio entre os inimigos possíveis), quanto Vis os Nódulos dão e quanta
## prata e cacos de vidro uma incursão completa rende, em média.
func _incursion_report(db: ContentDB) -> void:
	var focus := db.player.starting_focus
	var wand := WandState.new(db.player.make_wand())
	var cost := 0
	for amount in wand.effective_cost(focus.cost).values():
		cost += amount
	print("\n=== Mapa da Dungeon (Focus %s, sem páginas, sem errar) ===" % focus.id)
	var by_zone: Dictionary = {}
	# Material → quanto uma incursão que limpa o mapa rende, em média.
	var yields := {}
	var ids: Array = db.rooms.keys()
	ids.sort_custom(ContentDB.by_name)
	for room_id in ids:
		var room: RoomData = db.rooms[room_id]
		if room.zone == &"":
			continue
		var scene: Node = (load(room.scene_path) as PackedScene).instantiate()
		var enemies := 0.0
		var shots := 0.0
		for node in scene.find_children("*", "EnemySpawn", true, false):
			var spawn := node as EnemySpawn
			var pool: Array = spawn.enemy_pool if not spawn.enemy_pool.is_empty() else [spawn.enemy]
			for enemy: EnemyData in pool:
				# O inimigo e quem ele chama na fúria (chefes).
				for target: EnemyData in [enemy] + enemy.enrage_summons:
					var damage := Combat.damage_against(focus.damage, focus.element, target.weaknesses)
					shots += spawn.chance / pool.size() * ceili(target.max_health / damage)
				yields[&"silver"] = yields.get(&"silver", 0.0) + spawn.chance / pool.size() * (enemy.silver_min + enemy.silver_max) / 2.0
				if enemy.material != &"" and not enemy.material_safe:
					yields[enemy.material] = yields.get(enemy.material, 0.0) + spawn.chance / pool.size() * enemy.material_chance * enemy.material_amount
			enemies += spawn.chance
		for node in scene.find_children("*", "LootSpot", true, false):
			var spot := node as LootSpot
			var average := spot.chance * (spot.amount_min + spot.amount_max) / 2.0
			if spot.kind in db.items:
				yields[spot.kind] = yields.get(spot.kind, 0.0) + average
			elif spot.kind == &"jar":
				yields[&"glass"] = yields.get(&"glass", 0.0) + spot.chance * db.economy.glass_per_sealed_jar
		var vis := 0
		for node in scene.find_children("*", "VisNode", true, false):
			vis += maxi(node.vis_amount, 0)
		scene.free()
		print("  %s (%s): %.1f inimigo(s), %.1f disparo(s), %d de Vis nos Nódulos" % [room.id, room.zone, enemies, shots, vis])
		by_zone[room.zone] = by_zone.get(room.zone, 0.0) + shots
	var total := 0.0
	for zone in by_zone:
		print("Região %s: cerca de %.0f disparos para limpar tudo" % [zone, by_zone[zone]])
		total += by_zone[zone]
	var start := WandState.new(db.player.make_wand(), db.player.starting_vis).casts_available(focus.cost)
	print("Mapa inteiro: cerca de %.0f disparos (%.0f de Vis); a varinha começa com %d disparos (%d de Vis por disparo)" % [
		total, total * cost, start, cost])
	# O baú (um por incursão): prata e materiais sorteados.
	var economy := db.economy
	yields[&"silver"] = yields.get(&"silver", 0.0) + (economy.chest_silver_min + economy.chest_silver_max) / 2.0
	for item_id in economy.chest_materials:
		yields[item_id] = yields.get(item_id, 0.0) + float(economy.chest_material_count) / economy.chest_materials.size()
	var parts: PackedStringArray = []
	for item_id in yields:
		parts.append("%s %.1f" % [item_id, yields[item_id]])
	print("Uma incursão que limpa o mapa rende, em média: " + ", ".join(parts))
	print("\n=== Peças de varinha (Bancada Arcana) ===")
	for core: WandCoreData in db.cores.values():
		var wand_with := WandState.new(db.player.make_wand(core), {&"fire": core.aspect_capacity})
		print("  núcleo %s: %d por recipiente, %d no total (%d disparos de fogo com Ignis cheio); custa %s + Vis %s" % [
			core.id, core.aspect_capacity, core.capacity, wand_with.casts_available(focus.cost), core.cost, core.vis_cost])
	for cap: WandCapData in db.caps.values():
		var wand_with := WandState.new(db.player.make_wand(null, cap), {&"fire": 10})
		print("  ponteira %s: eficiência %.2f (10 de Ignis dão %d disparos de fogo); custa %s + Vis %s" % [
			cap.id, cap.efficiency, wand_with.casts_available(focus.cost), cap.cost, cap.vis_cost])
	print("Pote: %s no Almoxarife, ou %s + %s de Vis na bancada" % [db.economy.jar_price, db.economy.jar_materials, db.economy.jar_vis])
	# Todos os Focus: quantos disparos o Vis inicial dá a cada um (os recipientes são separados).
	for other: FocusData in db.foci.values():
		var casts := WandState.new(db.player.make_wand(), db.player.starting_vis).casts_available(other.cost)
		print("  Vis inicial dá %d disparo(s) de %s (custo %s)" % [casts, other.id, other.cost])
