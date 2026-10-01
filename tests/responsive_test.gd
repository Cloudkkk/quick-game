extends SceneTree

var checks = 0
var failures = 0
var game: Node2D

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, name: String) -> void:
	checks += 1
	if value:
		print("PASS: ",name)
	else:
		failures += 1
		push_error("FAIL: "+name)

func frame() -> void:
	await process_frame
	await process_frame

func click(logical: Vector2) -> void:
	# Viewport.push_input receives a real window-space coordinate; Godot applies
	# the viewport stretch transform before dispatching it to the game.
	var ev = InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = root.get_stretch_transform()*logical
	ev.global_position = ev.position
	root.push_input(ev)
	await frame()

func screenshot(path: String) -> void:
	game.queue_redraw()
	await frame()
	await RenderingServer.frame_post_draw
	var img = root.get_texture().get_image()
	check(img.save_png(path)==OK,"screenshot "+path)
	print("IMAGE_SIZE ",img.get_size()," LOGICAL_VIEW ",game.MAP.size)

func run() -> void:
	game = load("res://game.gd").new()
	game.test_mode = true
	root.add_child(game)
	game.set_process(false)
	for sz in [Vector2i(1200,820),Vector2i(1600,900),Vector2i(900,650),Vector2i(720,960)]:
		root.size = sz
		await frame()
		game.update_layout()
		game.restart()
		var name = "%dx%d" % [sz.x,sz.y]
		check(game.MAP.position==Vector2.ZERO and game.MAP.size==game.get_viewport_rect().size,name+" scene fills viewport")
		for rect in [game.pause_rect(),game.help_rect(),game.speed_rect(),game.mansion_rect(),game.help_close_rect(),game.replay_rect()]:
			check(game.MAP.encloses(rect),name+" HUD and target remain visible")
		for h in game.homes:
			check(game.MAP.encloses(game.home_rect(h)),name+" listing fully visible")
			check(not game.home_rect(h).intersects(game.pause_rect()) and not game.home_rect(h).intersects(game.help_rect()),name+" HUD does not cover listing")
		var h: Dictionary = game.homes[0]
		var p: Vector2 = game.lots[h.slot]
		await click(p)
		check(h.owned,name+" physical-coordinate buy hit")
		game.advance(h.cycle/2)
		await screenshot("res://evidence/q-owned-"+name+".png")
		await click(p)
		check(game.deals==1 and game.cash>100,name+" physical-coordinate sell hit")
		await click(game.pause_rect().get_center())
		var before: float = game.elapsed
		game.advance(5)
		check(game.paused and game.elapsed==before,name+" pause button freezes market")
		await click(game.pause_rect().get_center())
		check(not game.paused,name+" resume button")
		await click(game.help_rect().get_center())
		check(game.help_open,name+" help opens")
		game.advance(5)
		check(game.elapsed==before,name+" help freezes market")
		await click(game.help_close_rect().get_center())
		check(not game.help_open,name+" help closes with correct hit")
		await click(game.speed_rect().get_center())
		check(game.speed==2,name+" speed button hit")
		game.speed = 1
		game.cash = 11000
		await click(game.MANSION)
		check(game.won,name+" mansion click wins")
		await click(game.replay_rect().get_center())
		check(not game.won and game.cash==100 and game.deals==0,name+" replay button resets")
	root.size = Vector2i(1200,820)
	await frame()
	game.update_layout()
	game.restart()
	game.advance(9.3)
	game.trade(game.homes[0].id)
	await screenshot("res://evidence/Estate-Rise-Q-running.png")
	game.help_open = true
	await screenshot("res://evidence/q-help.png")
	game.help_open = false
	game.cash = 11000
	game.buy_mansion()
	await screenshot("res://evidence/q-victory.png")
	print("RESULT: ",checks-failures,"/",checks," passed")
	quit(0 if failures==0 else 1)
