extends SceneTree

var failures = 0
var checks = 0

func check(value: bool, name: String) -> void:
	checks += 1
	if value:
		print("PASS: " + name)
	else:
		failures += 1
		push_error("FAIL: " + name)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://game.gd").new()
	game.test_mode = true
	root.add_child(game)
	game.set_process(false)
	check(game.cash == 100.0 and game.homes.size() == 3, "initial 100K and three real listings")
	var starter: Dictionary = game.homes[0]
	var id: int = starter.id
	var price: float = starter.price
	check(game.hit_home(game.lots[starter.slot]) == id, "house pointer hit area")
	var buy_event = InputEventMouseButton.new()
	buy_event.button_index = MOUSE_BUTTON_LEFT
	buy_event.pressed = true
	buy_event.position = game.lots[starter.slot]
	game._unhandled_input(buy_event)
	check(starter.owned and is_equal_approx(game.cash,100.0-price), "mouse input purchases and debits once")
	game.advance(starter.cycle/2)
	check(starter.price > starter.cost*2.1 and starter.owned, "price cycle reaches profitable peak")
	var sell_value: float = starter.price
	game._unhandled_input(buy_event)
	check(game.homes.filter(func(h):return h.id == id).is_empty(), "mouse input sells and removes owned listing")
	check(is_equal_approx(game.cash,100.0-price+sell_value) and game.profit>0 and game.deals==1, "sale credits proceeds and realized profit")
	game.restart()
	var expensive: Dictionary = game.homes[2]
	check(game.trade(expensive.id) == "insufficient" and game.cash==100.0 and not expensive.owned, "insufficient funds causes no state mutation")
	check(not game.buy_mansion() and not game.won, "cannot win without cash")
	game.trade(game.homes[0].id)
	var owned_id: int = game.homes[0].id
	game.advance(70.0)
	check(game.homes.any(func(h):return h.id==owned_id and h.owned), "owned property survives listing expiration")
	check(not game.homes.any(func(h):return h.id==expensive.id), "unowned listings expire")
	var pause_event = InputEventKey.new()
	pause_event.pressed = true
	pause_event.keycode = KEY_SPACE
	game._unhandled_input(pause_event)
	var before: float = game.elapsed
	game.advance(10.0)
	check(game.elapsed==before and game.paused, "space key pauses market")
	check(game.trade(owned_id)=="blocked", "transactions blocked while paused")
	game._unhandled_input(pause_event)
	game.click_at(game.help_rect().get_center())
	check(game.help_open, "help button responds")
	game.advance(5.0)
	check(game.elapsed==before, "help freezes market")
	game.click_at(game.help_close_rect().get_center())
	check(not game.help_open, "help start button returns to game")
	game.click_at(game.speed_rect().get_center())
	check(game.speed==2.0, "speed button doubles simulation")
	game.restart()
	game.speed = 1.0
	# Play a deterministic low-buy / high-sell strategy through the real market,
	# without injecting cash, to demonstrate the normal economy can be completed.
	for step in range(12000):
		game.advance(0.1)
		for h in game.homes.duplicate():
			if h.owned and h.price > h.cost*1.80:
				game.trade(h.id)
			elif not h.owned and h.rising and h.price < h.base*0.88 and h.price<=game.cash:
				game.trade(h.id)
		if game.cash >= game.mansion_price():
			game.click_at(game.MANSION)
			break
	check(game.won, "normal economy reaches mansion through trading only")
	print("ECONOMY completion_months=%d deals=%d profit=%s" % [int(game.elapsed), game.deals,game.money(game.profit)])
	var end_time: float = game.elapsed
	game.advance(1.0)
	check(game.elapsed==end_time, "victory freezes timer")
	game.click_at(game.replay_rect().get_center())
	check(not game.won and game.cash==100.0 and game.deals==0, "victory replay restores new game")
	print("RESULT: %d/%d passed" % [checks-failures,checks])
	game.queue_free()
	quit(0 if failures==0 else 1)
