class_name SoundBank
extends Resource
## Liga cada evento do jogo (ex.: spell_cast) a um arquivo de som e a um volume.
## O arquivo fica em data/audio/sound_bank.tres. Para trocar um som, aponte o evento para
## outro arquivo; para silenciar, apague a linha do evento.

## Evento → som.
@export var sounds: Dictionary[StringName, AudioStream] = {}
## Evento → ajuste de volume em decibéis (0 = original; -6 = metade da força).
@export var volumes_db: Dictionary[StringName, float] = {}
