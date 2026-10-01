extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func screenshot(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var err = root.get_texture().get_image().save_png(path)
	print("SCREENSHOT ",path," status=",err)

func run() -> void:
	root.size = Vector2i(1200,820)
	var game = load("res://game.gd").new()
	game.test_mode = true
	root.add_child(game)
	game.set_process(false)
	await process_frame
	await screenshot("res://evidence/01-street.png")
	var h: Dictionary = game.homes[0]
	var click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = game.lots[h.slot]
	Input.parse_input_event(click)
	await process_frame
	game.advance(h.cycle/2)
	game.queue_redraw()
	await screenshot("res://evidence/02-owned.png")
	Input.parse_input_event(click)
	await process_frame
	game.queue_redraw()
	await screenshot("res://evidence/03-sold.png")
	print("VISUAL_INPUT deals=",game.deals," profit=",game.profit)
	game.help_open = true
	game.queue_redraw()
	await screenshot("res://evidence/04-help.png")
	game.help_open = false
	var original_font = game.font
	game.cjk_available = false
	game.font = ThemeDB.fallback_font
	game.queue_redraw()
	await screenshot("res://evidence/06-english-fallback.png")
	game.font = original_font
	game.cjk_available = true
	game.cash = 11000
	game.buy_mansion()
	game.queue_redraw()
	await screenshot("res://evidence/05-victory.png")
	quit()
