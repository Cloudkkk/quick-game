extends SceneTree

var game: Node2D
var checks = 0
var failures = 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, name: String) -> void:
	checks += 1
	if value:
		print("PASS: ", name)
	else:
		failures += 1
		push_error("FAIL: " + name)

func tap(p: Vector2, index: int = 0, pressed: bool = true) -> void:
	var ev = InputEventScreenTouch.new()
	ev.index = index
	ev.pressed = pressed
	ev.position = root.get_stretch_transform() * p
	root.push_input(ev)
	await process_frame

func run() -> void:
	game = load("res://game.gd").new()
	game.test_mode = true
	root.add_child(game)
	game.set_process(false)
	await process_frame
	check(not ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch"), "no emulated mouse double trade")
	for size in [Vector2i(1200,820), Vector2i(844,390), Vector2i(390,844)]:
		root.size = size
		await process_frame
		game.update_layout()
		game.restart()
		game.sounds.muted = false
		var name = "%dx%d" % [size.x,size.y]
		var h: Dictionary = game.homes[0]
		var p: Vector2 = game.lots[h.slot]
		await tap(p,1)
		check(not h.owned,name+" ignores secondary finger")
		await tap(p,0,false)
		check(not h.owned,name+" ignores release")
		await tap(p)
		check(h.owned and game.deals==0,name+" primary touch buys once")
		game.advance(h.cycle/2)
		await tap(p)
		check(game.deals==1 and game.cash>100,name+" touch sells for profit")
		await tap(game.pause_rect().get_center())
		var before: float = game.elapsed
		game.advance(4)
		check(game.paused and game.elapsed==before,name+" touch pauses")
		await tap(game.pause_rect().get_center())
		check(not game.paused,name+" touch resumes")
		await tap(game.help_rect().get_center())
		check(game.help_open,name+" touch opens help")
		await tap(game.help_close_rect().get_center())
		check(not game.help_open,name+" touch closes help")
		game.cash = 11000
		await tap(game.MANSION)
		check(game.won,name+" touch buys mansion")
		await tap(game.replay_rect().get_center())
		check(not game.won and game.cash==100,name+" touch replays")
		check(game.MAP.has_point(game.mute_rect().position) and game.MAP.has_point(game.mute_rect().end-Vector2.ONE),name+" mute fits viewport")
		await tap(game.mute_rect().get_center())
		check(game.sounds.muted,name+" touch mutes")
		await tap(game.mute_rect().get_center())
		check(not game.sounds.muted,name+" touch unmutes")
	print("RESULT: ",checks-failures,"/",checks," passed")
	quit(0 if failures==0 else 1)
