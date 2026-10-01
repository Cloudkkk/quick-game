extends Node2D

const SoundBank = preload("res://sounds.gd")
var sounds: Node

const INK = Color("343536")
const CREAM = Color("ffffff")
const GOLD = Color("ffb517")
const GREEN = Color("2b8068")
const BASES = [46.0, 260.0, 840.0, 2180.0]
const NAMES = ["花园小屋", "林荫联排", "湖畔别墅", "景观公馆"]
var MAP = Rect2(0, 0, 1200, 820)
var MANSION = Vector2(1032, 205)
var language = "en"
var language_settings_path = "user://estate-rise-language.cfg"
var font: Font
var atlas: Texture2D
var sprite_regions: Array[Rect2] = []
var lots: Array[Vector2] = []
var homes: Array[Dictionary] = []
var floats: Array[Dictionary] = []
var history: Array[String] = []
var rng = RandomNumberGenerator.new()
var cash = 100.0
var elapsed = 0.0
var spawn_clock = 0.0
var profit = 0.0
var deals = 0
var paused = false
var won = false
var help_open = false
var speed = 1.0
var next_id = 0
var hover_id = -1
var best_months = -1
var test_mode = false
var pointer = Vector2(-100, -100)
var cjk_available = false
var feedback = "点击白色挂牌买入，点击金色持有房卖出。"

func _ready() -> void:
	sounds = SoundBank.new()
	if test_mode:
		sounds.settings_path = "res://evidence/audio-test.cfg"
	add_child(sounds)
	# Redistributable CJK font is part of the game on every platform.
	font = load("res://assets/fonts/NotoSansCJKsc-Regular.otf")
	if font == null:
		font = ThemeDB.fallback_font
	cjk_available = font.has_char(0x4f60)
	if test_mode:
		language_settings_path = "res://evidence/language-test.cfg"
	load_language()
	if ResourceLoader.exists("res://assets/buildings-q.png"):
		atlas = load("res://assets/buildings-q.png")
		prepare_sprite_regions()
	get_viewport().size_changed.connect(update_layout)
	update_layout()
	_load_best()
	restart()

func detect_language(locale: String) -> String:
	return "zh" if locale.to_lower().begins_with("zh") else "en"

func load_language() -> void:
	var locale = OS.get_locale()
	if OS.has_feature("web"):
		var browser_locale = JavaScriptBridge.eval("navigator.language || 'en'", true)
		if browser_locale is String:
			locale = browser_locale
	language = detect_language(locale)
	var cfg = ConfigFile.new()
	if cfg.load(language_settings_path) == OK:
		var saved = str(cfg.get_value("locale", "language", ""))
		if saved in ["zh", "en"]:
			language = saved
	if language == "zh" and not cjk_available:
		language = "en"
	_sync_document_language()

func set_language(value: String, persist: bool = true) -> void:
	if value not in ["zh", "en"]:
		return
	language = value if value != "zh" or cjk_available else "en"
	if persist:
		var cfg = ConfigFile.new()
		cfg.set_value("locale", "language", language)
		cfg.save(language_settings_path)
	_sync_document_language()
	queue_redraw()

func _sync_document_language() -> void:
	if OS.has_feature("web"):
		var locale = "zh-CN" if language == "zh" else "en"
		JavaScriptBridge.eval("document.documentElement.lang = "+JSON.stringify(locale), true)

func text(value: String) -> String:
	return value if language == "zh" else english(value)

func restart() -> void:
	if sounds != null:
		sounds.stop_all()
	cash = 100.0
	elapsed = 0.0
	spawn_clock = 0.0
	profit = 0.0
	deals = 0
	paused = false
	won = false
	help_open = false
	homes.clear()
	floats.clear()
	history.clear()
	next_id = 0
	rng.seed = 7731 if test_mode else Time.get_ticks_usec()
	_spawn_home(0, 8, true)
	_spawn_home(1, 3)
	_spawn_home(2, 15)
	feedback = "从 100 K 开始，低买高卖，买下 10,000 K 豪宅。"
	queue_redraw()

func mansion_price() -> float:
	return 10000.0 + sin(elapsed * 0.15) * 480.0

func _process(delta: float) -> void:
	advance(delta)
	queue_redraw()

func advance(delta: float) -> void:
	if paused or won or help_open:
		return
	var dt = delta * speed
	elapsed += dt
	spawn_clock += dt
	for h in homes:
		h.age += dt
		var previous: float = h.price
		h.price = price_at(h, h.age)
		h.rising = h.price >= previous
	for i in range(homes.size()-1, -1, -1):
		if not homes[i].owned and homes[i].age > homes[i].life:
			homes.remove_at(i)
	if spawn_clock >= 3.1:
		spawn_clock = 0.0
		if homes.size() < 9:
			_spawn_home()
	for i in range(floats.size()-1, -1, -1):
		floats[i].ttl -= delta
		if floats[i].ttl <= 0:
			floats.remove_at(i)

func price_at(h: Dictionary, age: float) -> float:
	var phase: float = age / h.cycle * TAU - PI * 0.5
	var market: float = 1.05 + sin(phase) * 0.40
	return maxf(12.0, h.base * market)

func _spawn_home(tier: int = -1, slot: int = -1, starter: bool = false) -> void:
	var free: Array[int] = []
	for i in range(lots.size()):
		var occupied = false
		for h in homes:
			if h.slot == i:
				occupied = true
		if not occupied:
			free.append(i)
	if free.is_empty():
		return
	if slot < 0 or not free.has(slot):
		slot = free[rng.randi_range(0, free.size()-1)]
	if tier < 0:
		var wealth = cash
		for h in homes:
			if h.owned:
				wealth += h.price
		var cap = 0 if wealth < 200 else (1 if wealth < 700 else (2 if wealth < 1900 else 3))
		tier = rng.randi_range(0, mini(cap+1, 3))
		# Keep affordable opportunities even after the player moves to villas.
		if rng.randf() < 0.35:
			tier = 0
	var h = {"id":next_id, "slot":slot, "tier":tier, "base":BASES[tier]*rng.randf_range(0.85, 1.15), "age":0.0, "cycle":rng.randf_range(19.0, 29.0), "life":rng.randf_range(32.0, 48.0), "price":0.0, "owned":false, "cost":0.0, "rising":true}
	if starter:
		h.base = 70.0
	h.price = price_at(h, 0)
	homes.append(h)
	next_id += 1

func trade(id: int) -> String:
	if paused or won or help_open:
		return "blocked"
	for i in range(homes.size()):
		var h = homes[i]
		if h.id != id:
			continue
		var p = lots[h.slot]
		if h.owned:
			var gain: float = h.price - h.cost
			cash += h.price
			profit += gain
			deals += 1
			feedback = "售出%s · %s %s" % [NAMES[h.tier], "盈利" if gain >= 0 else "亏损", money(absf(gain))]
			_note(("+" if gain >= 0 else "−") + money(absf(gain)), p-Vector2(0,125), GREEN if gain >= 0 else Color("c35543"))
			history.push_front(feedback)
			if history.size() > 3:
				history.pop_back()
			homes.remove_at(i)
			sounds.play("profit" if gain >= 0 else "loss")
			return "sold"
		if cash + 0.00001 < h.price:
			feedback = "资金不足 · 还需要 " + money(h.price-cash)
			_note("资金不足", p-Vector2(0,125), Color("c35543"))
			sounds.play("boop")
			return "insufficient"
		cash -= h.price
		h.owned = true
		h.cost = h.price
		feedback = "已买入%s · %s；留意价格箭头。" % [NAMES[h.tier], money(h.price)]
		_note("买入 " + money(h.price), p-Vector2(0,125), GREEN)
		sounds.play("buy")
		return "bought"
	return "missing"

func buy_mansion() -> bool:
	if won or paused or help_open:
		return false
	if cash < mansion_price():
		feedback = "豪宅目标 · 还需要 " + money(mansion_price()-cash)
		_note("继续积累 " + money(mansion_price()-cash), MANSION+Vector2(0,73), Color("c35543"))
		sounds.play("boop")
		return false
	cash -= mansion_price()
	won = true
	sounds.play("win", true)
	if not test_mode and (best_months < 0 or int(elapsed) < best_months):
		best_months = int(elapsed)
		var cfg = ConfigFile.new()
		cfg.set_value("record", "months", best_months)
		cfg.save("user://estate-rise-record.cfg")
	return true

func _load_best() -> void:
	var cfg = ConfigFile.new()
	if cfg.load("user://estate-rise-record.cfg") == OK:
		best_months = cfg.get_value("record", "months", -1)

func _note(s: String, p: Vector2, c: Color) -> void:
	floats.append({"text":s, "p":p, "color":c, "ttl":2.0})

func money(n: float) -> String:
	return "%s K" % String.num(n, 0)

func _unhandled_input(event: InputEvent) -> void:
	# Handle one primary finger directly. Mouse emulation is disabled in the
	# project so a single tap cannot buy and immediately sell the same home.
	if event is InputEventScreenTouch:
		if event.index == 0 and event.pressed:
			sounds.user_gesture()
			pointer = event.position
			click_at(pointer)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion:
		pointer = event.position
		hover_id = hit_home(pointer)
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if hover_id >= 0 or mansion_rect().has_point(pointer) else Input.CURSOR_ARROW)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_SPACE, KEY_R, KEY_H, KEY_ESCAPE]:
			sounds.user_gesture()
		if event.keycode == KEY_SPACE:
			paused = not paused
			sounds.play("click")
		if event.keycode == KEY_R:
			restart()
			sounds.play("click")
		if event.keycode == KEY_H or event.keycode == KEY_ESCAPE:
			help_open = not help_open
			sounds.play("click")
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		sounds.user_gesture()
		click_at(event.position)

func update_layout() -> void:
	var sz = get_viewport_rect().size
	MAP = Rect2(Vector2.ZERO, sz)
	MANSION = Vector2(sz.x*0.86, sz.y*0.25)
	if OS.has_feature("web"):
		# A smaller Web reference viewport keeps phone prices/HUD readable.
		# Keep the complete target inside that viewport.
		MANSION.x = minf(MANSION.x,sz.x-114)
		MANSION.y = maxf(MANSION.y,155)
	lots.clear()
	for i in range(5):
		for j in range(5):
			var old_y = 241 + (i+j)*50
			if old_y > 270 and old_y < 610:
				lots.append(Vector2(sz.x*0.47+(i-j)*sz.x*0.094, sz.y*0.15+(i+j)*sz.y*0.088))
	queue_redraw()

func language_rect() -> Rect2:
	return Rect2(MAP.size.x-284,12,80,36)

func pause_rect() -> Rect2:
	return Rect2(MAP.size.x-196,12,80,36)

func help_rect() -> Rect2:
	return Rect2(MAP.size.x-104,12,92,36)

func speed_rect() -> Rect2:
	return Rect2(MAP.size.x-100,MAP.size.y-46,88,34)

func mute_rect() -> Rect2:
	return Rect2(MAP.size.x-196,MAP.size.y-46,88,34)

func help_panel() -> Rect2:
	return Rect2(MAP.size/2-Vector2(290,195),Vector2(580,390))

func help_close_rect() -> Rect2:
	return Rect2(help_panel().position+Vector2(170,328),Vector2(240,44))

func win_panel() -> Rect2:
	return Rect2(MAP.size/2-Vector2(245,216),Vector2(490,432))

func replay_rect() -> Rect2:
	return Rect2(win_panel().position+Vector2(125,365),Vector2(240,44))

func click_at(p: Vector2) -> void:
	if language_rect().has_point(p):
		set_language("en" if language == "zh" else "zh")
		sounds.play("click")
		return
	if mute_rect().has_point(p):
		sounds.toggle_mute()
		return
	if won:
		if replay_rect().has_point(p):
			restart()
			sounds.play("click")
		return
	if help_open:
		if help_close_rect().has_point(p):
			help_open = false
			sounds.play("click")
		return
	if pause_rect().has_point(p):
		paused = not paused
		sounds.play("click")
		return
	if help_rect().has_point(p):
		help_open = true
		sounds.play("click")
		return
	if speed_rect().has_point(p):
		speed = 1.0 if speed == 2.0 else 2.0
		sounds.play("click")
		return
	if mansion_rect().has_point(p):
		buy_mansion()
		return
	var id = hit_home(p)
	if id >= 0:
		trade(id)

func mansion_rect() -> Rect2:
	return Rect2(MANSION-Vector2(110,142), Vector2(220,185))

func home_rect(h: Dictionary) -> Rect2:
	return Rect2(lots[h.slot]-Vector2(55,96), Vector2(110,114))

func prepare_sprite_regions() -> void:
	# Generated atlases have approximate column spacing. Trim each isolated
	# sprite's transparent padding, without changing any generated pixels.
	var img = atlas.get_image()
	var cuts = [0.0,0.237,0.450,0.718,1.0]
	sprite_regions.clear()
	for row in range(2):
		for col in range(4):
			var zone = Rect2i(int(img.get_width()*cuts[col]),int(img.get_height()*row/2.0),int(img.get_width()*cuts[col+1])-int(img.get_width()*cuts[col]),int(img.get_height()/2.0))
			var piece = img.get_region(zone)
			var lo = Vector2i(piece.get_width(),piece.get_height())
			var hi = Vector2i.ZERO
			for y in range(piece.get_height()):
				for x in range(piece.get_width()):
					# Ignore invisible generation specks when measuring padding.
					if piece.get_pixel(x,y).a > 0.5:
						lo = Vector2i(mini(lo.x,x),mini(lo.y,y))
						hi = Vector2i(maxi(hi.x,x),maxi(hi.y,y))
			var used = Rect2i(lo,hi-lo+Vector2i.ONE).grow(2).intersection(Rect2i(Vector2i.ZERO,piece.get_size()))
			sprite_regions.append(Rect2(zone.position+used.position,used.size))

func hit_home(p: Vector2) -> int:
	for i in range(homes.size()-1, -1, -1):
		if home_rect(homes[i]).has_point(p):
			return homes[i].id
	return -1

func rounded(rect: Rect2, color: Color, radius: int = 12, border: Color = Color.TRANSPARENT) -> void:
	var box = StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	if border.a > 0:
		box.set_border_width_all(1)
		box.border_color = border
	draw_style_box(box, rect)

func fitted_size(s: String, size: int, max_width: float) -> int:
	var result = size
	while result > 10 and font.get_string_size(s,HORIZONTAL_ALIGNMENT_LEFT,-1,result).x > max_width:
		result -= 1
	return result

func label_at(s: String, p: Vector2, size: int = 18, color: Color = INK, max_width: float = -1) -> void:
	s = text(s)
	var available = MAP.size.x-p.x-12 if max_width < 0 else max_width
	size = fitted_size(s,size,available)
	draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func centered(s: String, p: Vector2, size: int = 18, color: Color = INK, max_width: float = -1) -> void:
	s = text(s)
	var available = minf(p.x-12,MAP.size.x-p.x-12)*2 if max_width < 0 else max_width
	size = fitted_size(s,size,available)
	label_at(s, p-Vector2(font.get_string_size(s,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x/2,0), size, color, available)

func wrapped_text(s: String, max_width: float, size: int) -> Array[String]:
	var translated = text(s)
	var parts: Array[String] = []
	if language == "en":
		for word in translated.split(" "):
			parts.append(word+" ")
	else:
		for character in translated:
			parts.append(character)
	var lines: Array[String] = []
	var line = ""
	for part in parts:
		if not line.is_empty() and font.get_string_size(line+part,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x > max_width:
			lines.append(line.strip_edges())
			line = ""
		line += part
	if not line.is_empty():
		lines.append(line.strip_edges())
	return lines

func english(s: String) -> String:
	var phrases = {
		"街区大亨  /  低买高卖，住进你的梦想豪宅":"Buy low. Sell high. Own your dream mansion.",
		"白色挂牌：买入    金色挂牌：卖出":"WHITE: BUY    GOLD: SELL",
		"从 100 K 开始，低买高卖，买下 10,000 K 豪宅。":"Start 100 K. Goal: a 10,000 K mansion.",
		"点击白色挂牌买入，点击金色持有房卖出。":"Click white listings to buy, gold listings to sell.",
		"点击购买 · 仅使用现金":"Click to buy with cash",
		"卖出房产后即可使用收益":"Sell properties to unlock their equity",
		"你的第一套房，从这里开始":"Your first property starts here",
		"01   用 100 K 启动资金购买白色挂牌房屋。":"01   Start with 100 K. Click a white listing to buy.",
		"02   ▲ 表示上涨，▼ 表示下跌；价格会反复波动。":"02   Watch the arrows: prices rise and fall in cycles.",
		"03   持有房屋变为金色挂牌，点击即可卖出兑现。":"03   Owned listings turn gold. Click to sell for cash.",
		"04   从小屋到别墅，逐步放大交易，积累现金。":"04   Trade cottages, townhouses and villas to grow.",
		"05   凑足豪宅现价，点击右上方豪宅完成挑战。":"05   Buy the mansion at top right to finish the run.",
		"挂牌会下架，持有房产不会消失。没有租金收入。":"Listings expire. Owned homes persist. No rental income.",
		"梦想豪宅，正式属于你":"Your dream mansion is yours!",
		"已暂停 · 空格继续":"Paused - Space to resume",
		"留意价格箭头。":"Watch the price arrows.",
		"点击立即卖出":"Click to sell now", "点击立即买入":"Click to buy now",
		"空格 暂停    R 重开    1秒 = 1个月    最佳：":"Space: Pause   R: Restart   1 sec = 1 month   Best: ",
		"开始交易":"Start trading", "再玩一次":"Play again", "最佳：":"Best: ", "游戏时间":"TIME", "可用资金":"CASH",
		"花园小屋":"Cottage", "林荫联排":"Townhouse", "湖畔别墅":"Villa", "景观公馆":"Residence",
		"累计交易利润":"Trading profit ", "梦想豪宅":"Mansion", "林荫街区":"Lake District",
		"继续积累":"Need ", "挂牌剩余":"Expires in ", "即将下架":"Expiring soon", "现金进度":"Cash progress ",
		"资金不足":"Not enough cash", "还需要":"Need ", "豪宅目标":"Mansion goal", "已买入":"Bought ",
		"总资产":"Equity ", "售出":"Sold ", "成交":"Sales ", "用时":"Time: ", "完成":"Closed ",
		"浮盈":"Gain ", "浮亏":"Loss ", "盈利":"Profit ", "亏损":"Loss ", "成本":"Cost ", "现价":"Price ",
		"买入":"Buy ", "持有":"Owned ", "待售":"For sale", "暂停":"Pause", "继续":"Resume", "玩法":"Help", "速度":"Speed",
		"静音":"Muted", "声音":"Sound",
		"个月":" months", "年":"y", "月":"m", "栋":"", "笔交易":" trades", "笔":"", "：":": ", "；":"; ", "，":", "}
	for phrase in phrases:
		s = s.replace(phrase,phrases[phrase])
	return s

func _draw() -> void:
	if font == null:
		return
	_draw_map()
	_draw_mansion()
	var order = homes.duplicate()
	order.sort_custom(func(a,b):return lots[a.slot].y < lots[b.slot].y)
	for h in order:
		_draw_home(h)
	for f in floats:
		var c: Color = f.color
		c.a = minf(1.0,f.ttl)
		centered(f.text,f.p-Vector2(0,(2-f.ttl)*16),17,c)
	_draw_hud()
	if hover_id >= 0 and not won and not help_open:
		_draw_hover()
	if paused and not help_open and not won:
		var p = MAP.size/2
		rounded(Rect2(p-Vector2(145,32),Vector2(290,64)),CREAM,10,INK)
		centered("已暂停 · 空格继续",p+Vector2(0,8),21,INK)
	if help_open:
		_draw_help()
	if won:
		_draw_win()
	rounded(language_rect(),Color("ffffffe8"),10,INK)
	centered("EN" if language == "zh" else "中文",language_rect().get_center()+Vector2(0,6),15,INK,68)
	rounded(mute_rect(),Color("ffffffe8"),10,INK)
	centered("静音" if sounds.muted else "声音",mute_rect().get_center()+Vector2(0,6),15,INK)

func _draw_map() -> void:
	draw_rect(MAP,Color("8fa33b"))
	var slope_size = MAP.size.y*0.088/(MAP.size.x*0.094)
	var origin_x = MAP.size.x*0.47
	for k in range(-8,13):
		for slope in [-slope_size,slope_size]:
			var b = MAP.size.y*(0.062+k*0.176)
			var a = Vector2(0, slope*(0-origin_x)+b)
			var z = Vector2(MAP.size.x,slope*(MAP.size.x-origin_x)+b)
			if a.y < 0:
				a = Vector2(origin_x-b/slope,0)
			if a.y > MAP.size.y:
				a = Vector2(origin_x+(MAP.size.y-b)/slope,MAP.size.y)
			if z.y < 0:
				z = Vector2(origin_x-b/slope,0)
			if z.y > MAP.size.y:
				z = Vector2(origin_x+(MAP.size.y-b)/slope,MAP.size.y)
			if a.x < 0 or a.x > MAP.size.x or z.x < 0 or z.x > MAP.size.x:
				continue
			draw_line(a,z,Color("383d32"),29,true)
			draw_line(a,z,Color("62665b"),25,true)
			draw_dashed_line(a,z,Color("f4f5ed"),1.7,12,true)
	var lake = MAP.size*Vector2(0.2,0.16)
	draw_ellipse(lake,Vector2(88,31),INK)
	draw_ellipse(lake-Vector2(0,1),Vector2(85,28),Color("4cbcef"))
	draw_ellipse(lake-Vector2(27,8),Vector2(27,7),CREAM)
	for uv in [Vector2(0.035,0.16),Vector2(0.08,0.40),Vector2(0.285,0.135),Vector2(0.385,0.18),Vector2(0.04,0.66),Vector2(0.075,0.87),Vector2(0.25,0.85),Vector2(0.455,0.89),Vector2(0.80,0.84),Vector2(0.96,0.88),Vector2(0.97,0.45),Vector2(0.62,0.11),Vector2(0.70,0.18)]:
		_draw_tree(uv*MAP.size)

func draw_ellipse(p: Vector2, radii: Vector2, c: Color) -> void:
	var points = PackedVector2Array()
	for i in range(40):
		var a = TAU*i/40.0
		points.append(p+Vector2(cos(a)*radii.x,sin(a)*radii.y))
	draw_colored_polygon(points,c)

func _draw_tree(p: Vector2) -> void:
	draw_ellipse(p+Vector2(6,1),Vector2(18,6),Color("7b8c33"))
	draw_rect(Rect2(p-Vector2(3,17),Vector2(6,18)),Color("886744"))
	var triangle = PackedVector2Array([p-Vector2(0,58),p+Vector2(13,-10),p+Vector2(-13,-10)])
	draw_colored_polygon(triangle,Color("bdcc61"))
	draw_colored_polygon(PackedVector2Array([p-Vector2(0,58),p+Vector2(13,-10),p+Vector2(1,-10)]),Color("738639"))
	draw_polyline(PackedVector2Array([triangle[0],triangle[1],triangle[2],triangle[0]]),Color("505638"),1.5,true)

func _sprite(tier: int, rect: Rect2, tint: Color = Color.WHITE, owned: bool = false) -> void:
	if atlas:
		var src = sprite_regions[tier+(4 if owned else 0)]
		var fit = minf(rect.size.x/src.size.x,rect.size.y/src.size.y)
		var sz = src.size*fit
		var target = Rect2(Vector2(rect.get_center().x-sz.x/2,rect.end.y-sz.y),sz)
		draw_texture_rect_region(atlas,target,src,tint)
	else:
		var p = rect.position+rect.size*Vector2(0.5,0.7)
		draw_colored_polygon(PackedVector2Array([p+Vector2(-30,0),p+Vector2(0,13),p+Vector2(30,-1),p+Vector2(30,-40),p+Vector2(0,-52),p+Vector2(-30,-38)]),GOLD if owned else CREAM)
		draw_colored_polygon(PackedVector2Array([p+Vector2(-36,-38),p+Vector2(0,-65),p+Vector2(37,-40),p+Vector2(0,-27)]),Color("777777"))

func _draw_mansion() -> void:
	draw_ellipse(MANSION,Vector2(82,24),Color("7b8c33"))
	_sprite(3,Rect2(MANSION-Vector2(98,145),Vector2(196,145)))
	rounded(Rect2(MANSION+Vector2(-96,11),Vector2(192,30)),CREAM,12,INK)
	centered("梦想豪宅 · "+money(mansion_price()),MANSION+Vector2(0,32),16,INK)

func _draw_home(h: Dictionary) -> void:
	var p = lots[h.slot]
	if h.id == hover_id:
		draw_ellipse(p+Vector2(0,2),Vector2(42,14),Color("c3ca79"))
	_sprite(h.tier,Rect2(p-Vector2(43,70),Vector2(86,74)),Color.WHITE,h.owned)
	var tag = Rect2(p-Vector2(46,96),Vector2(92,26))
	rounded(tag,CREAM,10,Color("e08b10") if h.owned else INK)
	# Geometric arrows also work when the browser fallback font lacks symbols.
	var arrow = tag.position+Vector2(12,13)
	var direction = -1.0 if h.rising else 1.0
	draw_colored_polygon(PackedVector2Array([arrow+Vector2(0,5*direction),arrow+Vector2(-5,-4*direction),arrow+Vector2(5,-4*direction)]),GREEN if h.rising else Color("da4936"))
	centered(money(h.price),p+Vector2(8,-78),15,INK)
	if h.owned:
		centered("持有",p+Vector2(0,22),12,INK)
	elif h.life-h.age < 8:
		centered("即将下架",p+Vector2(0,22),12,Color("a24023"))

func _draw_hud() -> void:
	# All HUD elements are overlays inside the full-window game scene.
	rounded(Rect2(12,12,292,42),Color("ffffffe8"),11,INK)
	label_at("可用资金  "+money(cash),Vector2(24,39),20,INK,179)
	label_at("%d 年 %d 月" % [int(elapsed)/12,int(elapsed)%12],Vector2(211,39),17,INK,82)
	for rect in [pause_rect(),help_rect(),speed_rect()]:
		rounded(rect,Color("ffffffe8"),10,INK)
	centered("继续" if paused else "暂停",pause_rect().get_center()+Vector2(0,6),16,INK)
	centered("玩法  H",help_rect().get_center()+Vector2(0,6),16,INK)
	centered("速度 ×%d" % int(speed),speed_rect().get_center()+Vector2(0,6),15,INK)
	var note = Rect2(12,MAP.size.y-64,mini(710,MAP.size.x-232),52)
	rounded(note,Color("ffffffe0"),9)
	var lines = wrapped_text(feedback,note.size.x-20,13)
	for i in range(mini(2,lines.size())):
		label_at(lines[i],note.position+Vector2(10,20+i*19),13,INK,note.size.x-20)

func _draw_hover() -> void:
	for h in homes:
		if h.id != hover_id:
			continue
		var p = Vector2(clampf(pointer.x+18,12,MAP.size.x-244),clampf(pointer.y+24,65,MAP.size.y-167))
		rounded(Rect2(p,Vector2(228,108)),CREAM,10,INK)
		label_at(NAMES[h.tier]+(" · 持有" if h.owned else " · 待售"),p+Vector2(12,24),16,INK,204)
		label_at("现价 "+money(h.price),p+Vector2(12,49),15,INK,204)
		var detail = "成本 %s · %s %s" % [money(h.cost),"浮盈" if h.price>=h.cost else "浮亏",money(absf(h.price-h.cost))] if h.owned else "挂牌剩余 %d 个月" % maxi(0,int(h.life-h.age))
		label_at(detail,p+Vector2(12,73),12,INK,204)
		label_at("点击立即卖出" if h.owned else "点击立即买入",p+Vector2(12,95),13,INK,204)

func _draw_help() -> void:
	draw_rect(MAP,Color(0,0,0,0.40))
	var rect = help_panel()
	var p = rect.position
	rounded(rect,CREAM,14,INK)
	label_at("你的第一套房，从这里开始",p+Vector2(26,44),25,INK,528)
	var lines = ["01   用 100 K 启动资金购买白色挂牌房屋。", "02   ▲ 表示上涨，▼ 表示下跌；价格会反复波动。", "03   持有房屋变为金色挂牌，点击即可卖出兑现。", "04   从小屋到别墅，逐步放大交易，积累现金。", "05   凑足豪宅现价，点击右上方豪宅完成挑战。"]
	for i in range(lines.size()):
		label_at(lines[i],p+Vector2(26,90+i*36),17,INK,528)
	label_at("挂牌会下架，持有房产不会消失。没有租金收入。",p+Vector2(26,286),14,INK,528)
	label_at("最佳："+("—" if best_months<0 else "%d年%d月" % [best_months/12,best_months%12]),p+Vector2(26,310),13,INK,528)
	rounded(help_close_rect(),GOLD,9,INK)
	centered("开始交易",help_close_rect().get_center()+Vector2(0,6),18,INK)

func _draw_win() -> void:
	draw_rect(MAP,Color(0,0,0,0.40))
	var rect = win_panel()
	var p = rect.position
	rounded(rect,CREAM,14,INK)
	centered("梦想豪宅，正式属于你",p+Vector2(245,49),26,INK,438)
	centered("用时 %d 年 %d 月 · 完成 %d 笔交易" % [int(elapsed)/12,int(elapsed)%12,deals],p+Vector2(245,86),17,INK,438)
	_sprite(3,Rect2(p+Vector2(130,116),Vector2(230,190)))
	centered("累计交易利润 "+money(profit),p+Vector2(245,337),17,INK,438)
	rounded(replay_rect(),GOLD,9,INK)
	centered("再玩一次",replay_rect().get_center()+Vector2(0,6),18,INK)
