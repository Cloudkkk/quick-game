extends Node

signal sound_played(kind: String)

const CLIPS = {
	"buy": preload("res://assets/sounds/buy.wav"),
	"profit": preload("res://assets/sounds/profit.wav"),
	"loss": preload("res://assets/sounds/loss.wav"),
	"boop": preload("res://assets/sounds/boop.wav"),
	"click": preload("res://assets/sounds/click.wav"),
	"win": preload("res://assets/sounds/win.wav")
}
const GAP_MS = 80
var muted = false
var unlocked = false
var settings_path = "user://estate-rise-audio.cfg"
var players: Array[AudioStreamPlayer] = []
var cursor = 0
var last_play_ms = -10000

func _ready() -> void:
	unlocked = not OS.has_feature("web")
	load_preference()
	for i in range(2):
		var player = AudioStreamPlayer.new()
		player.autoplay = false
		player.max_polyphony = 1
		player.volume_db = -8.0
		if OS.has_feature("web"):
			player.playback_type = AudioServer.PLAYBACK_TYPE_SAMPLE
		add_child(player)
		players.append(player)

func user_gesture() -> void:
	# Godot resumes its Web AudioContext from browser input callbacks.
	# Until that first pointer/key event, no clip is allowed to start.
	unlocked = true

func play(kind: String, priority: bool = false) -> bool:
	if muted or not unlocked or not CLIPS.has(kind) or players.is_empty():
		return false
	var now = Time.get_ticks_msec()
	if not priority and now-last_play_ms < GAP_MS:
		return false
	if priority:
		stop_all()
	var player = players[cursor]
	cursor = (cursor+1) % players.size()
	player.stop()
	player.stream = CLIPS[kind]
	player.play()
	last_play_ms = now
	sound_played.emit(kind)
	return true

func stop_all() -> void:
	for player in players:
		player.stop()

func toggle_mute() -> void:
	muted = not muted
	if muted:
		stop_all()
	else:
		play("click", true)
	var cfg = ConfigFile.new()
	cfg.set_value("audio", "muted", muted)
	cfg.save(settings_path)

func load_preference() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(settings_path) == OK:
		muted = bool(cfg.get_value("audio", "muted", false))
