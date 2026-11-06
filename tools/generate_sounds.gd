extends SceneTree
## Gera os sons provisórios do jogo em assets/sounds/ (WAV mono, 22 050 Hz, 16 bits: um som
## "abafado", no espírito do PS1). Tudo é sintetizado aqui, com ondas e ruído; semente fixa,
## então rodar de novo produz os mesmos arquivos.
## Rodar a partir da pasta do projeto:
##   godot --headless --path . -s tools/generate_sounds.gd
## Para trocar um som por outro (gravado ou de um banco livre), substitua o WAV mantendo o nome,
## ou aponte o evento para outro arquivo em data/audio/sound_bank.tres.
## Sons que repetem (ambientes, zumbido da Lente) têm "Loop Mode: Forward" na aba Importar.

const RATE := 22050
const OUTPUT_DIR := "res://assets/sounds"

var rng := RandomNumberGenerator.new()


func _initialize() -> void:
	rng.seed = 2026
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	_save("spell_charge", _spell_charge())
	_save("spell_cast", _spell_cast())
	_save("fire_impact", _fire_impact())
	_save("no_energy", _no_energy())
	_save("scan_hum", _scan_hum(), true)
	_save("scan_complete", _scan_complete())
	_save("page_studied", _page_studied())
	_save("recharge", _recharge())
	_save("portal", _portal())
	_save("player_hurt", _player_hurt())
	_save("player_death", _player_death())
	_save("enemy_alert", _enemy_alert())
	_save("enemy_swing", _enemy_swing())
	_save("enemy_hurt", _enemy_hurt())
	_save("enemy_death", _enemy_death())
	_save("ambience_school", _ambience_school(), true)
	_save("ambience_dungeon", _ambience_dungeon(), true)
	_save("ambience_caves", _ambience_caves(), true)
	_save("ambience_abyss", _ambience_abyss(), true)
	# Sons acrescentados depois (no fim, para os de cima continuarem iguais).
	_save("gate", _gate())
	_save("coin", _coin())
	_save("glass", _glass())
	# M12: sons próprios de cada inimigo, dos Focus novos, ambiente do Observatório e músicas.
	_enemy_sounds()
	_save("frost_cast", _frost_cast())
	_save("frost_impact", _frost_impact())
	_save("shock_cast", _shock_cast())
	_save("dig_impact", _dig_impact())
	_save("ambience_stars", _ambience_stars(), true)
	_save("music_school", _music(24.0, 146.83, [[0, 3, 7], [-4, 0, 3], [3, 7, 10], [-2, 2, 5]], 0.5, 0.11, 0.16, 0.0, false), true)
	_save("music_ruins", _music(32.0, 110.0, [[0, 3, 7], [-4, 0, 3], [0, 3, 7], [-5, -1, 2]], 2.0, 0.08, 0.2, 0.1, true), true)
	_save("music_abyss", _music(32.0, 65.41, [[0, 6, 11], [1, 5, 10], [0, 6, 9], [-1, 5, 10]], 2.67, 0.1, 0.14, 0.12, true), true)
	_save("music_stars", _music(32.0, 164.81, [[0, 4, 7, 11], [2, 6, 9, 14], [-3, 0, 4, 7], [-5, 0, 2, 7]], 0.4, 0.07, 0.12, 0.0, false), true)
	quit()


# --- Sons ---------------------------------------------------------------------

## Zumbido que sobe enquanto a magia carrega.
func _spell_charge() -> PackedFloat32Array:
	var out := _silence(0.6)
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		phase += TAU * lerpf(160.0, 420.0, t / 0.6) / RATE
		out[i] = (sin(phase) * 0.5 + _tri(phase * 2.0) * 0.2) * minf(t * 4.0, 1.0) * 0.5
	return out


## Sopro de fogo: ruído que fecha, com um tom que desce.
func _spell_cast() -> PackedFloat32Array:
	var out := _silence(0.45)
	var lp := 0.0
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		lp = lerpf(lp, rng.randf_range(-1.0, 1.0), lerpf(0.5, 0.05, t / 0.45))
		phase += TAU * lerpf(320.0, 110.0, t / 0.45) / RATE
		out[i] = (lp * 0.9 + sin(phase) * 0.35) * _env(t, 0.01, 0.45)
	return out


## Explosão pequena: estalo de ruído e um baque grave.
func _fire_impact() -> PackedFloat32Array:
	var out := _silence(0.5)
	var lp := 0.0
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		lp = lerpf(lp, rng.randf_range(-1.0, 1.0), lerpf(0.6, 0.08, t / 0.5))
		phase += TAU * lerpf(95.0, 45.0, t / 0.5) / RATE
		out[i] = (lp * 0.8 + sin(phase) * 0.7) * _env(t, 0.002, 0.5)
	return out


## Clique seco: a varinha está vazia.
func _no_energy() -> PackedFloat32Array:
	var out := _silence(0.15)
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		phase += TAU * 120.0 / RATE
		out[i] = signf(sin(phase)) * 0.35 * _env(t, 0.002, 0.15)
	return out


## Zumbido contínuo da Lente (repete sem emenda: 1 s com ciclos inteiros).
func _scan_hum() -> PackedFloat32Array:
	var out := _silence(1.0)
	for i in out.size():
		var t := float(i) / RATE
		var tremolo := 0.75 + 0.25 * sin(TAU * 6.0 * t)
		out[i] = (sin(TAU * 520.0 * t) * 0.3 + sin(TAU * 780.0 * t) * 0.15) * tremolo * 0.5
	return out


## Duas notas de sino: escaneamento completo.
func _scan_complete() -> PackedFloat32Array:
	var out := _silence(0.7)
	for i in out.size():
		var t := float(i) / RATE
		var a := sin(TAU * 880.0 * t) * exp(-t * 7.0)
		var b := sin(TAU * 1320.0 * t) * exp(-maxf(t - 0.12, 0.0) * 6.0) * (1.0 if t > 0.12 else 0.0)
		out[i] = (a + b) * 0.35
	return out


## Acorde suave: página estudada.
func _page_studied() -> PackedFloat32Array:
	var out := _silence(1.2)
	for i in out.size():
		var t := float(i) / RATE
		var chord := sin(TAU * 440.0 * t) + sin(TAU * 554.4 * t) * 0.8 + sin(TAU * 659.3 * t) * 0.6
		out[i] = chord * 0.18 * minf(t * 20.0, 1.0) * exp(-t * 2.5)
	return out


## Sopro que sobe e estalos de brasa: varinha recarregada.
func _recharge() -> PackedFloat32Array:
	var out := _silence(0.8)
	var lp := 0.0
	for i in out.size():
		var t := float(i) / RATE
		lp = lerpf(lp, rng.randf_range(-1.0, 1.0), lerpf(0.03, 0.4, t / 0.8))
		var crackle := rng.randf_range(-1.0, 1.0) if rng.randf() < 0.004 else 0.0
		out[i] = (lp * 0.8 + crackle * 0.15) * _env(t, 0.3, 0.8)
	return out


## Brilho que sobe e desce, com vibrato: atravessar o portal.
func _portal() -> PackedFloat32Array:
	var out := _silence(1.4)
	var phases := [0.0, 0.0, 0.0]
	var base := [220.0, 330.0, 495.0]
	for i in out.size():
		var t := float(i) / RATE
		var bend := sin(PI * t / 1.4)
		var sample := 0.0
		for k in 3:
			phases[k] += TAU * base[k] * (1.0 + 0.5 * bend + 0.01 * sin(TAU * 7.0 * t)) / RATE
			sample += sin(phases[k]) / (k + 1.0)
		out[i] = sample * 0.3 * _env(t, 0.2, 1.4)
	return out


## Baque surdo: o jogador apanhou.
func _player_hurt() -> PackedFloat32Array:
	var out := _silence(0.35)
	var phase := 0.0
	var lp := 0.0
	for i in out.size():
		var t := float(i) / RATE
		phase += TAU * lerpf(170.0, 90.0, t / 0.35) / RATE
		lp = lerpf(lp, rng.randf_range(-1.0, 1.0), 0.1)
		out[i] = (sin(phase) * 0.8 + lp * 0.5) * _env(t, 0.003, 0.35)
	return out


## Tom grave que afunda: a morte.
func _player_death() -> PackedFloat32Array:
	var out := _silence(1.5)
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		phase += TAU * lerpf(140.0, 40.0, t / 1.5) / RATE
		out[i] = (sin(phase) + _tri(phase * 0.5) * 0.4) * 0.45 * _env(t, 0.02, 1.5)
	return out


## Gemido grave e trêmulo: o inimigo notou você.
func _enemy_alert() -> PackedFloat32Array:
	var out := _silence(0.9)
	var phase := 0.0
	var lp := 0.0
	for i in out.size():
		var t := float(i) / RATE
		phase += TAU * (lerpf(75.0, 55.0, t / 0.9) + 4.0 * sin(TAU * 9.0 * t)) / RATE
		lp = lerpf(lp, rng.randf_range(-1.0, 1.0), 0.05)
		out[i] = (_saw(phase) * 0.5 + lp * 0.6) * _env(t, 0.1, 0.9)
	return out


## Sopro curto: o golpe do inimigo.
func _enemy_swing() -> PackedFloat32Array:
	var out := _silence(0.35)
	var lp := 0.0
	for i in out.size():
		var t := float(i) / RATE
		lp = lerpf(lp, rng.randf_range(-1.0, 1.0), 0.05 + 0.3 * sin(PI * t / 0.35))
		out[i] = lp * 1.2 * sin(PI * t / 0.35)
	return out


## Estalos de osso: o inimigo tomou dano.
func _enemy_hurt() -> PackedFloat32Array:
	var out := _silence(0.3)
	for click in 3:
		_add_click(out, 0.02 + click * 0.06, 0.012, 0.8)
	for i in out.size():
		var t := float(i) / RATE
		out[i] += sin(TAU * 300.0 * t) * 0.25 * _env(t, 0.002, 0.3)
	return out


## Ossos desmoronando e um baque: o inimigo caiu.
func _enemy_death() -> PackedFloat32Array:
	var out := _silence(1.0)
	for click in 9:
		_add_click(out, 0.05 + click * 0.07 + rng.randf_range(0.0, 0.03), 0.015, rng.randf_range(0.4, 0.8))
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		phase += TAU * 60.0 / RATE
		if t > 0.6:
			out[i] += sin(phase) * 0.6 * _env(t - 0.6, 0.005, 0.4)
	return out


## Ambiente da escola (4 s, repete): zumbido grave e estalos de braseiro.
func _ambience_school() -> PackedFloat32Array:
	var out := _silence(4.0)
	for i in out.size():
		var t := float(i) / RATE
		out[i] = sin(TAU * 55.0 * t) * 0.06 + sin(TAU * 82.5 * t) * 0.03
	for crackle in 24:
		_add_click(out, rng.randf_range(0.0, 3.95), rng.randf_range(0.003, 0.008), rng.randf_range(0.015, 0.05))
	return out


## Ambiente da Dungeon (6 s, repete): vento grave, zumbido e gotas.
func _ambience_dungeon() -> PackedFloat32Array:
	var out := _silence(6.0)
	var lp := 0.0
	for i in out.size():
		var t := float(i) / RATE
		lp = lerpf(lp, rng.randf_range(-1.0, 1.0), 0.01)
		var wind := lp * (0.5 + 0.5 * sin(TAU * 0.5 * t)) * 1.5
		out[i] = wind * 0.5 + sin(TAU * 41.0 * t) * 0.08
	for drop in 3:
		var start := rng.randf_range(0.3, 5.3)
		var phase := 0.0
		for i in int(0.25 * RATE):
			var t := float(i) / RATE
			phase += TAU * lerpf(1300.0, 800.0, t / 0.25) / RATE
			var index := int(start * RATE) + i
			if index < out.size():
				out[index] += sin(phase) * 0.25 * _env(t, 0.002, 0.25)
	return out


## Ambiente das grutas (8 s, repete): ronco grave da terra e muitas gotas ecoando.
func _ambience_caves() -> PackedFloat32Array:
	var out := _silence(8.0)
	var lp := 0.0
	for i in out.size():
		var t := float(i) / RATE
		lp = lerpf(lp, rng.randf_range(-1.0, 1.0), 0.004)
		out[i] = lp * 0.7 + sin(TAU * 32.0 * t) * 0.05 * (0.6 + 0.4 * sin(TAU * 0.25 * t))
	for drop in 9:
		var start := rng.randf_range(0.2, 7.6)
		var pitch := rng.randf_range(700.0, 1600.0)
		var phase := 0.0
		for i in int(0.3 * RATE):
			var t := float(i) / RATE
			phase += TAU * lerpf(pitch, pitch * 0.6, t / 0.3) / RATE
			var index := int(start * RATE) + i
			if index < out.size():
				# Gota e eco fraco logo depois.
				out[index] += sin(phase) * 0.2 * _env(t, 0.002, 0.3)
				var echo := index + int(0.12 * RATE)
				if echo < out.size():
					out[echo] += sin(phase) * 0.07 * _env(t, 0.002, 0.3)
	return out


## Ambiente do Avesso (8 s, repete): dois zumbidos graves desafinados que batem entre si,
## um pulso lento e um sussurro de ruído que vem e vai.
func _ambience_abyss() -> PackedFloat32Array:
	var out := _silence(8.0)
	var lp := 0.0
	for i in out.size():
		var t := float(i) / RATE
		lp = lerpf(lp, rng.randf_range(-1.0, 1.0), 0.08)
		var drone := sin(TAU * 49.0 * t) * 0.09 + sin(TAU * 51.5 * t) * 0.09 + sin(TAU * 73.4 * t) * 0.03
		var pulse := 0.5 + 0.5 * sin(TAU * 0.5 * t)
		var whisper := lp * 0.12 * maxf(sin(TAU * 0.125 * t), 0.0)
		out[i] = drone * (0.6 + 0.4 * pulse) + whisper
	return out


# --- Ferramentas de síntese ---------------------------------------------------

## Ferro arrastando e um baque no fim: grade que desce para o chão.
func _gate() -> PackedFloat32Array:
	var out := _silence(1.8)
	var phase := 0.0
	var lp := 0.0
	for i in out.size():
		var t := float(i) / RATE
		phase += TAU * (55.0 + 8.0 * sin(TAU * 3.0 * t)) / RATE
		lp = lerpf(lp, rng.randf_range(-1.0, 1.0), 0.08)
		out[i] = (_saw(phase) * 0.25 + lp * 0.5) * _env(t, 0.1, 1.6)
	_add_click(out, 1.55, 0.12, 0.6)
	return out


## Tilintar de moedas: dois toques metálicos curtos.
func _coin() -> PackedFloat32Array:
	var out := _silence(0.5)
	for i in out.size():
		var t := float(i) / RATE
		var sample := 0.0
		for hit in [0.0, 0.09]:
			if t >= hit:
				var u: float = t - hit
				sample += (sin(TAU * 1850.0 * u) + sin(TAU * 2770.0 * u) * 0.6) * exp(-u * 18.0)
		out[i] = sample * 0.18
	return out


## Vidro que se parte: estalo e tinidos agudos.
func _glass() -> PackedFloat32Array:
	var out := _silence(0.6)
	for i in out.size():
		var t := float(i) / RATE
		var shimmer := sin(TAU * 3300.0 * t) * 0.5 + sin(TAU * 4100.0 * t) * 0.4 + sin(TAU * 2600.0 * t) * 0.3
		out[i] = shimmer * 0.16 * exp(-t * 9.0)
	_add_click(out, 0.0, 0.04, 0.5)
	_add_click(out, 0.11, 0.03, 0.25)
	return out


# --- M12: blocos para compor os sons novos ----------------------------------------------

## Soma um tom que desliza de `f0` a `f1` Hz, com ataque e queda (onda: "sine", "saw",
## "square" ou "tri") e um leve vibrato.
func _tone(out: PackedFloat32Array, start: float, length: float, f0: float, f1: float, wave: String, gain: float,
		attack := 0.02, vibrato := 0.0) -> void:
	var phase := 0.0
	var first := int(start * RATE)
	for i in int(length * RATE):
		if first + i >= out.size():
			break
		var t := float(i) / RATE
		var f := lerpf(f0, f1, t / length) * (1.0 + vibrato * sin(TAU * 5.5 * t))
		phase += TAU * f / RATE
		var sample := sin(phase)
		match wave:
			"saw":
				sample = _saw(phase)
			"square":
				sample = 1.0 if sin(phase) >= 0.0 else -1.0
			"tri":
				sample = _tri(phase)
		out[first + i] += sample * gain * _env(t, attack, length)


## Soma ruído filtrado: `bright` de 0 (abafado) a 1 (chiado), deslizando de `b0` a `b1`.
func _noise(out: PackedFloat32Array, start: float, length: float, b0: float, b1: float, gain: float, attack := 0.02) -> void:
	var lp := 0.0
	var first := int(start * RATE)
	for i in int(length * RATE):
		if first + i >= out.size():
			break
		var t := float(i) / RATE
		lp = lerpf(lp, rng.randf_range(-1.0, 1.0), clampf(lerpf(b0, b1, t / length), 0.005, 1.0))
		out[first + i] += lp * gain * _env(t, attack, length)


## Vários estalos espalhados (ossos batendo, cascalho).
func _clicks(out: PackedFloat32Array, start: float, length: float, count: int, gain: float) -> void:
	for i in count:
		_add_click(out, start + rng.randf() * length, rng.randf_range(0.004, 0.015), gain * rng.randf_range(0.5, 1.0))


## Os quatro sons (alerta, golpe, dano e morte) de cada tipo de inimigo: "<tipo>_alert" etc.
func _enemy_sounds() -> void:
	# Bedel: gemido rouco e ossos batendo.
	var out := _silence(0.9)
	_tone(out, 0.0, 0.9, 95.0, 80.0, "saw", 0.22, 0.15, 0.02)
	_noise(out, 0.0, 0.9, 0.05, 0.02, 0.3, 0.1)
	_clicks(out, 0.1, 0.7, 8, 0.4)
	_save("beadle_alert", out)
	out = _silence(0.4)
	_noise(out, 0.0, 0.35, 0.05, 0.4, 0.5, 0.15)
	_add_click(out, 0.33, 0.02, 0.7)
	_save("beadle_swing", out)
	out = _silence(0.3)
	_tone(out, 0.0, 0.25, 820.0, 760.0, "tri", 0.2, 0.002)
	_tone(out, 0.0, 0.2, 1230.0, 1150.0, "sine", 0.12, 0.002)
	_add_click(out, 0.0, 0.01, 0.6)
	_save("beadle_hurt", out)
	out = _silence(1.3)
	_clicks(out, 0.0, 1.1, 26, 0.45)
	_tone(out, 0.0, 0.5, 70.0, 45.0, "sine", 0.4, 0.005)
	_save("beadle_death", out)
	# Aprendiz: sussurros e chiados.
	out = _silence(0.8)
	_noise(out, 0.0, 0.8, 0.5, 0.8, 0.22, 0.2)
	_tone(out, 0.0, 0.8, 300.0, 340.0, "saw", 0.04, 0.2, 0.05)
	_save("apprentice_alert", out)
	out = _silence(0.3)
	_noise(out, 0.0, 0.3, 0.3, 0.9, 0.4, 0.05)
	_save("apprentice_swing", out)
	out = _silence(0.3)
	_noise(out, 0.0, 0.25, 0.7, 0.4, 0.35, 0.005)
	_tone(out, 0.0, 0.2, 520.0, 380.0, "saw", 0.06, 0.005)
	_save("apprentice_hurt", out)
	out = _silence(1.3)
	_noise(out, 0.0, 1.3, 0.6, 0.1, 0.3, 0.1)
	_tone(out, 0.0, 1.2, 260.0, 160.0, "saw", 0.05, 0.1, 0.03)
	_save("apprentice_death", out)
	# Lodo: borbulhas e estalos molhados.
	for name in ["ooze_alert", "ooze_hurt", "ooze_death"]:
		var length := 0.9 if name == "ooze_alert" else (0.35 if name == "ooze_hurt" else 1.4)
		out = _silence(length)
		_noise(out, 0.0, length, 0.03, 0.01, 0.4, 0.05)
		for b in int(length * 14):
			var at := rng.randf() * (length - 0.08)
			_tone(out, at, 0.07, rng.randf_range(150.0, 260.0), rng.randf_range(300.0, 520.0), "sine", 0.18, 0.005)
		_save(name, out)
	out = _silence(0.4)
	_noise(out, 0.0, 0.3, 0.08, 0.02, 0.6, 0.01)
	_tone(out, 0.05, 0.3, 300.0, 90.0, "sine", 0.25, 0.005)
	_save("ooze_swing", out)
	# Arquivista: gemido grave e páginas.
	out = _silence(1.5)
	_tone(out, 0.0, 1.5, 58.0, 52.0, "saw", 0.25, 0.2, 0.03)
	_tone(out, 0.0, 1.5, 87.0, 78.0, "saw", 0.12, 0.2, 0.03)
	_noise(out, 0.2, 0.8, 0.4, 0.6, 0.15, 0.05)
	_save("archivist_alert", out)
	out = _silence(0.6)
	_noise(out, 0.0, 0.55, 0.03, 0.25, 0.6, 0.25)
	_save("archivist_swing", out)
	out = _silence(0.45)
	_tone(out, 0.0, 0.4, 75.0, 60.0, "saw", 0.3, 0.01)
	_save("archivist_hurt", out)
	out = _silence(2.2)
	_tone(out, 0.0, 2.1, 70.0, 32.0, "saw", 0.3, 0.1, 0.04)
	_noise(out, 0.0, 2.2, 0.3, 0.05, 0.2, 0.3)
	_save("archivist_death", out)
	# Olhos: zumbidos de vidro.
	out = _silence(0.8)
	_tone(out, 0.0, 0.8, 600.0, 900.0, "sine", 0.18, 0.1, 0.04)
	_tone(out, 0.0, 0.8, 905.0, 1350.0, "sine", 0.08, 0.1, 0.04)
	_save("eye_alert", out)
	out = _silence(0.5)
	_tone(out, 0.0, 0.5, 400.0, 1400.0, "sine", 0.18, 0.4)
	_save("eye_swing", out)
	out = _silence(0.3)
	_tone(out, 0.0, 0.3, 1800.0, 1400.0, "tri", 0.15, 0.005)
	_save("eye_hurt", out)
	out = _silence(1.3)
	_tone(out, 0.0, 1.3, 1200.0, 200.0, "sine", 0.2, 0.02, 0.06)
	_tone(out, 0.0, 1.0, 1810.0, 300.0, "sine", 0.08, 0.02)
	_save("eye_death", out)


## Gelo: sinos de cristal subindo.
func _frost_cast() -> PackedFloat32Array:
	var out := _silence(0.6)
	for i in 4:
		_tone(out, i * 0.07, 0.4, 1400.0 + i * 300.0, 1450.0 + i * 300.0, "sine", 0.12, 0.003)
	_noise(out, 0.0, 0.5, 0.8, 0.9, 0.06, 0.1)
	return out


## Gelo se partindo: estalo e tinidos agudos.
func _frost_impact() -> PackedFloat32Array:
	var out := _silence(0.7)
	_add_click(out, 0.0, 0.03, 0.6)
	for i in 6:
		_tone(out, rng.randf() * 0.1, 0.5, rng.randf_range(2200.0, 3800.0), rng.randf_range(2000.0, 3600.0), "sine", 0.07, 0.002)
	_noise(out, 0.0, 0.4, 0.9, 0.6, 0.15, 0.003)
	return out


## Choque: zumbido elétrico e estalos.
func _shock_cast() -> PackedFloat32Array:
	var out := _silence(0.45)
	_tone(out, 0.0, 0.4, 70.0, 55.0, "square", 0.12, 0.003)
	_noise(out, 0.0, 0.4, 1.0, 0.7, 0.3, 0.003)
	_clicks(out, 0.0, 0.35, 14, 0.5)
	return out


## Escavação: baque grave e cascalho.
func _dig_impact() -> PackedFloat32Array:
	var out := _silence(0.7)
	_tone(out, 0.0, 0.35, 75.0, 40.0, "sine", 0.6, 0.003)
	_noise(out, 0.0, 0.5, 0.06, 0.02, 0.4, 0.005)
	_clicks(out, 0.05, 0.5, 18, 0.35)
	return out


## O Observatório: um zumbido baixo e brilhos agudos que vêm e vão (8 s, em repetição).
func _ambience_stars() -> PackedFloat32Array:
	var seconds := 8.0
	var out := _silence(seconds)
	for i in out.size():
		var t := float(i) / RATE
		out[i] = sin(TAU * 55.0 * t) * 0.05 * (0.7 + 0.3 * sin(TAU * t / seconds))
	for k in 10:
		var at := k * seconds / 10.0
		var f: float = [1760.0, 2093.0, 2349.0, 2637.0][k % 4]
		_wrap_tone(out, at, 2.0, f, 0.03)
	return out


## Um tom de sino que começa em `start` e, se passar do fim, continua no começo (o som repete
## sem emenda).
func _wrap_tone(out: PackedFloat32Array, start: float, length: float, freq: float, gain: float, bell := false) -> void:
	var first := int(start * RATE)
	for i in int(length * RATE):
		var t := float(i) / RATE
		var decay := exp(-t * 3.0 / length)
		var sample := sin(TAU * freq * t)
		if bell:
			sample += 0.4 * sin(TAU * freq * 2.76 * t) * exp(-t * 6.0 / length) + 0.2 * sin(TAU * freq * 5.4 * t) * exp(-t * 9.0 / length)
		out[(first + i) % out.size()] += sample * gain * decay * minf(t * 200.0, 1.0)


## Música ambiente em repetição: acordes longos (pad) que se misturam, um arpejo por cima e,
## se `drone`, uma nota grave contínua. As frequências são arredondadas para fechar o ciclo
## sem emenda. `chords`: semitons em relação a `root_hz`, um acorde a cada quarto do tempo.
func _music(seconds: float, root_hz: float, chords: Array, arp_every: float, pad_gain: float, arp_gain: float,
		drone_gain: float, bells: bool) -> PackedFloat32Array:
	var out := _silence(seconds)
	var chord_length := seconds / chords.size()
	var fade := minf(1.5, chord_length / 2.0)
	var period := func(f: float) -> float: return roundf(f * seconds) / seconds
	for i in out.size():
		var t := float(i) / RATE
		var sample := 0.0
		for c in chords.size():
			# Peso do acorde: 1 dentro do trecho dele, misturando nas bordas (com a volta do ciclo).
			var center := (c + 0.5) * chord_length
			var distance := absf(fposmod(t - center + seconds / 2.0, seconds) - seconds / 2.0)
			var weight := clampf((chord_length / 2.0 + fade / 2.0 - distance) / fade, 0.0, 1.0)
			if weight <= 0.0:
				continue
			for semitone in chords[c]:
				var f: float = period.call(root_hz * pow(2.0, semitone / 12.0))
				var f2: float = period.call(f * 1.003)
				sample += (sin(TAU * f * t) + 0.6 * sin(TAU * f2 * t) + 0.25 * sin(TAU * 2.0 * f * t)) * weight
		sample *= pad_gain / 2.0
		if drone_gain > 0.0:
			var low: float = period.call(root_hz / 2.0)
			sample += sin(TAU * low * t) * drone_gain * (0.8 + 0.2 * sin(TAU * 2.0 * t / seconds))
		out[i] = sample
	# Arpejo: notas do acorde da vez, subindo e descendo, uma oitava acima.
	var pattern := [0, 1, 2, 1, 0, 2, 1, 2]
	var steps := int(roundf(seconds / arp_every))
	for k in steps:
		var at := k * arp_every
		var chord: Array = chords[mini(int(at / chord_length), chords.size() - 1)]
		var semitone: int = chord[pattern[k % pattern.size()] % chord.size()] + 12
		var f: float = period.call(root_hz * pow(2.0, semitone / 12.0))
		_wrap_tone(out, at, 2.4 if bells else 1.4, f, arp_gain, bells)
	# Normaliza o volume (pico em 0,8).
	var peak := 0.0001
	for sample in out:
		peak = maxf(peak, absf(sample))
	for i in out.size():
		out[i] = out[i] / peak * 0.8
	return out


func _silence(seconds: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(seconds * RATE))
	return out


## Envelope: sobe em `attack` segundos e cai até zero no fim (`length`).
func _env(t: float, attack: float, length: float) -> float:
	var rise := minf(t / maxf(attack, 0.0001), 1.0)
	var fall := clampf(1.0 - (t - attack) / maxf(length - attack, 0.0001), 0.0, 1.0)
	return rise * fall * fall


func _tri(phase: float) -> float:
	return 2.0 / PI * asin(sin(phase))


func _saw(phase: float) -> float:
	return fmod(phase / TAU, 1.0) * 2.0 - 1.0


## Estalo curto de ruído em `at` segundos.
func _add_click(out: PackedFloat32Array, at: float, length: float, gain: float) -> void:
	var start := int(at * RATE)
	for i in int(length * RATE):
		if start + i < out.size():
			out[start + i] += rng.randf_range(-1.0, 1.0) * gain * (1.0 - float(i) / (length * RATE))


func _save(file_name: String, samples: PackedFloat32Array, loop := false) -> void:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = samples.size()
	var path := OUTPUT_DIR.path_join(file_name + ".wav")
	stream.save_to_wav(path)
	print("Gerado: ", path)
