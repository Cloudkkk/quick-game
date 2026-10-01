extends SceneTree
var checks = 0
var failures = 0
var game: Node2D
func check(ok: bool, name: String) -> void:
	checks += 1
	if ok: print("PASS: ",name)
	else:
		failures += 1
		push_error("FAIL: "+name)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	game=load("res://game.gd").new()
	game.test_mode=true
	root.add_child(game)
	game.set_process(false)
	game.language_settings_path="res://evidence/language-unit.cfg"
	check(game.font is FontFile and game.cjk_available,"bundled CJK font loaded")
	check(game.font.resource_path.begins_with("res://assets/fonts/"),"no OS font dependency")
	for locale in ["zh-CN","zh-TW","ZH-hans","en-US","fr-FR",""]:
		check(game.detect_language(locale)==("zh" if locale.to_lower().begins_with("zh") else "en"),"default locale "+locale)
	var source_strings=[" · 待售", " · 持有", "%d 年 %d 月", "%d年%d月", "01   用 100 K 启动资金购买白色挂牌房屋。", "02   ▲ 表示上涨，▼ 表示下跌；价格会反复波动。", "03   持有房屋变为金色挂牌，点击即可卖出兑现。", "04   从小屋到别墅，逐步放大交易，积累现金。", "05   凑足豪宅现价，点击右上方豪宅完成挑战。", "个月", "买入", "买入 ", "亏损", "从 100 K 开始，低买高卖，买下 10,000 K 豪宅。", "你的第一套房，从这里开始", "再玩一次", "卖出房产后即可使用收益", "即将下架", "可用资金", "可用资金  ", "售出", "售出%s · %s %s", "声音", "完成", "已买入", "已买入%s · %s；留意价格箭头。", "已暂停 · 空格继续", "年", "开始交易", "待售", "总资产", "成交", "成本", "成本 %s · %s %s", "持有", "挂牌会下架，持有房产不会消失。没有租金收入。", "挂牌剩余", "挂牌剩余 %d 个月", "景观公馆", "暂停", "最佳：", "月", "林荫联排", "林荫街区", "栋", "梦想豪宅", "梦想豪宅 · ", "梦想豪宅，正式属于你", "浮亏", "浮盈", "游戏时间", "湖畔别墅", "点击白色挂牌买入，点击金色持有房卖出。", "点击立即买入", "点击立即卖出", "点击购买 · 仅使用现金", "玩法", "玩法  H", "现价", "现价 ", "现金进度", "用时", "用时 %d 年 %d 月 · 完成 %d 笔交易", "留意价格箭头。", "白色挂牌：买入    金色挂牌：卖出", "盈利", "空格 暂停    R 重开    1秒 = 1个月    最佳：", "笔", "笔交易", "累计交易利润", "累计交易利润 ", "继续", "继续积累", "继续积累 ", "花园小屋", "街区大亨  /  低买高卖，住进你的梦想豪宅", "豪宅目标", "豪宅目标 · 还需要 ", "资金不足", "资金不足 · 还需要 ", "还需要", "速度", "速度 ×%d", "静音"]
	var missing=[]
	for s in source_strings:
		for character in s:
			if not game.font.has_char(character.unicode_at(0)): missing.append(character)
	check(missing.is_empty(),"font covers every source UI character")
	game.set_language("en",false)
	var chinese=RegEx.new();chinese.compile("[一-龥]")
	var untranslated=[]
	for s in source_strings:
		if chinese.search(game.text(s))!=null:untranslated.append(s)
	check(untranslated.is_empty(),"all source UI phrases translated: "+str(untranslated))
	game.trade(game.homes[0].id)
	var snapshot=JSON.stringify([game.cash,game.elapsed,game.homes,game.profit,game.deals,game.speed,game.best_months])
	game.set_language("zh")
	check(JSON.stringify([game.cash,game.elapsed,game.homes,game.profit,game.deals,game.speed,game.best_months])==snapshot,"switch preserves active economy and ownership")
	check(game.text(game.feedback).contains("已买入"),"existing purchase feedback switches to Chinese")
	game.set_language("en",false)
	check(game.text(game.feedback).contains("Bought Cottage"),"existing feedback switches to English")
	game.load_language();check(game.language=="zh","saved language restored")
	game.restart();check(game.language=="zh","restart keeps chosen language")
	game.trade(game.homes[2].id)
	check(game.text(game.feedback).contains("资金不足"),"Chinese insufficient funds")
	game.set_language("en",false)
	check(game.text(game.feedback).contains("Not enough cash"),"English insufficient funds")
	game.help_open=true
	game.click_at(game.language_rect().get_center())
	check(game.language=="zh" and game.help_open,"language button works during help")
	game.help_open=false;game.cash=11000;game.buy_mansion()
	game.click_at(game.language_rect().get_center())
	check(game.language=="en" and game.won,"language button works after victory")
	game.set_language("de")
	check(game.language=="en","unsupported saved selection rejected")
	for width in [600.0,1038.0]:
		game.MAP=Rect2(0,0,width,480)
		check(game.MAP.encloses(game.language_rect()) and not game.language_rect().intersects(Rect2(12,12,292,42)),"language HUD fits width "+str(width))
		for locale in ["zh","en"]:
			game.set_language(locale,false)
			for message in ["从 100 K 开始，低买高卖，买下 10,000 K 豪宅。","已买入景观公馆 · 2180 K；留意价格箭头。","售出花园小屋 · 盈利 123 K","资金不足 · 还需要 9999 K"]:
				var lines=game.wrapped_text(message,minf(710,width-232)-20,13)
				check(lines.size()<=2 and lines.all(func(l):return game.font.get_string_size(l,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x<=minf(710,width-232)-20),locale+" feedback fits "+str(width))
	game.free();DirAccess.remove_absolute("res://evidence/language-unit.cfg")
	print("RESULT: ",checks-failures,"/",checks," passed")
	quit(0 if failures==0 else 1)
