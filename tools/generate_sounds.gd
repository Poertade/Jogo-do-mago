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
