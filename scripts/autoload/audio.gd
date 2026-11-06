extends Node
## Autoload "Audio": toca os sons do jogo pelo nome do evento. Qual arquivo toca em cada
## evento (e com que volume) está em data/audio/sound_bank.tres.
## Também escuta os avisos do autoload Game para tocar os sons de pesquisa e de dano.

## Distância, em metros, em que um som 3D some.
const MAX_DISTANCE_3D := 22.0
## Grupo de todos os sons tocando (2D e 3D), para pará-los ao fechar o jogo.
const PLAYING_GROUP := &"playing_sounds"

## Volume da música no máximo (dB), antes do volume escolhido nas opções.
const MUSIC_DB := -10.0
## Segundos para uma música dar lugar a outra.
const MUSIC_FADE := 2.0

var _bank: SoundBank
var _ambience: AudioStreamPlayer
var _music: AudioStreamPlayer
var _music_volume := 0.6
var _music_tween: Tween


func _ready() -> void:
	# Sons de interface tocam mesmo com o jogo pausado (ex.: estudar uma página na Mesa).
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bank = Content.db.sound_bank
	_ambience = AudioStreamPlayer.new()
	_ambience.volume_db = -8.0
	add_child(_ambience)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -60.0
	add_child(_music)
	Game.scan_completed.connect(_on_scan_completed)
	Game.page_studied.connect(func(_page): play(&"page_studied"))
	Game.player_damaged.connect(func(_amount): play(&"player_hurt"))
	Game.player_died.connect(func(): play(&"player_death"))
	Game.travel_requested.connect(func(_room, _entrance): play(&"portal"))
	Game.dungeon_requested.connect(func(_seed, _anchor): play(&"portal"))


## Toca um som "na cabeça" do jogador (sem posição no mundo).
func play(event: StringName) -> AudioStreamPlayer:
	if _bank == null or not event in _bank.sounds:
		return null
	var player := AudioStreamPlayer.new()
	player.stream = _bank.sounds[event]
	player.volume_db = _bank.volumes_db.get(event, 0.0)
	player.add_to_group(PLAYING_GROUP)
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
	return player


## Toca um som num ponto do mundo 3D; ele fica mais fraco com a distância.
## `parent` é um nó do mundo (o som pausa junto com o jogo).
func play_at(event: StringName, position: Vector3, parent: Node) -> void:
	if _bank == null or not event in _bank.sounds or parent == null:
		return
	var player := AudioStreamPlayer3D.new()
	player.stream = _bank.sounds[event]
	player.volume_db = _bank.volumes_db.get(event, 0.0)
	player.max_distance = MAX_DISTANCE_3D
	player.add_to_group(PLAYING_GROUP)
	parent.add_child(player)
	player.global_position = position
	player.finished.connect(player.queue_free)
	player.play()


## Abaixa o som até sumir e então o apaga. Cortar um som de uma vez faz um estalo.
## `player` pode já ter terminado e sumido (aí não faz nada), por isso não tem tipo.
func fade_out(player, seconds := 0.08) -> void:
	if not is_instance_valid(player):
		return
	var tween: Tween = player.create_tween()
	tween.tween_property(player, "volume_db", -60.0, seconds)
	tween.tween_callback(player.queue_free)


## Começa o som de ambiente da sala (ou silencia, se `stream` for null).
func set_ambience(stream: AudioStream) -> void:
	if _ambience.stream == stream and _ambience.playing:
		return
	_ambience.stream = stream
	if stream != null:
		_ambience.play()
	else:
		_ambience.stop()


## Existe um som com este nome no banco? (Ex.: os sons próprios de cada inimigo.)
func has_sound(event: StringName) -> bool:
	return _bank != null and event in _bank.sounds


## Troca a música (de cada sala, em RoomData.music) com a música antiga sumindo devagar.
## A mesma música continua de onde estava.
func set_music(stream: AudioStream) -> void:
	if _music.stream == stream and _music.playing:
		return
	if _music_tween != null:
		_music_tween.kill()
	_music_tween = create_tween()
	if _music.playing:
		_music_tween.tween_property(_music, "volume_db", -60.0, MUSIC_FADE / 2.0)
	_music_tween.tween_callback(func():
		_music.stream = stream
		if stream != null:
			_music.play()
		else:
			_music.stop())
	if stream != null:
		_music_tween.tween_property(_music, "volume_db", _music_db(), MUSIC_FADE / 2.0)


## Volume da música, de 0 a 1 (opções).
func set_music_volume(linear: float) -> void:
	_music_volume = linear
	if _music_tween == null or not _music_tween.is_running():
		_music.volume_db = _music_db() if _music.playing else -60.0


func _music_db() -> float:
	return MUSIC_DB + linear_to_db(maxf(_music_volume, 0.0001))


## Para todos os sons (usado ao fechar o jogo, para nada ficar tocando na saída).
func stop_all() -> void:
	_ambience.stop()
	_ambience.stream = null
	_music.stop()
	_music.stream = null
	for player in get_tree().get_nodes_in_group(PLAYING_GROUP):
		player.stop()
		player.queue_free()


## Volume geral, de 0 a 1.
func set_master_volume(linear: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(linear, 0.0001)))


func _on_scan_completed(result: ScanResult) -> void:
	if result.discovered_something():
		play(&"scan_complete")
