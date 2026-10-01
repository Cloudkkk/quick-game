extends SceneTree
var game: Node2D
var events: Array[String] = []
var checks = 0
var failures = 0
func check(ok: bool, title: String) -> void:
	checks += 1
	if ok: print("PASS: ",title)
	else:
		failures += 1
		push_error("FAIL: "+title)
func allow() -> void:
	game.sounds.last_play_ms = -10000
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	game = load("res://game.gd").new()
	game.test_mode = true
	root.add_child(game)
	game.set_process(false)
	game.sounds.settings_path = "res://evidence/audio-unit.cfg"
	game.sounds.muted = false
	game.sounds.sound_played.connect(func(kind): events.append(kind))
	game.sounds.unlocked = false
	check(not game.sounds.play("buy") and events.is_empty(),"no audio before user gesture")
	game.sounds.user_gesture()
	check(game.sounds.unlocked,"first gesture unlocks")
	for kind in game.sounds.CLIPS:
		var clip = game.sounds.CLIPS[kind]
		check(clip is AudioStreamWAV and clip.get_length() < 1.0,"baked short WAV: "+kind)
	allow();game.trade(game.homes[0].id)
	check(events.back()=="buy","purchase pop")
	var home: Dictionary=game.homes[0]
	home.price=home.cost+10
	allow();game.trade(home.id)
	check(events.back()=="profit","profitable sale coin tone")
	game.restart();allow();game.trade(game.homes[0].id)
	home=game.homes[0];home.price=home.cost-10
	allow();game.trade(home.id)
	check(events.back()=="loss","loss sale descending tone")
	game.restart();allow();game.trade(game.homes[2].id)
	check(events.back()=="boop","insufficient funds boop")
	allow();game.click_at(game.pause_rect().get_center())
	check(events.back()=="click" and game.paused,"HUD button click")
	var before=events.size();allow();game.trade(game.homes[0].id)
	check(events.size()==before,"blocked trade silent")
	game.paused=false;allow();before=events.size()
	for i in range(25): game.sounds.play("click")
	check(events.size()==before+1,"rapid 25 requests accept only one inside 80ms")
	check(game.sounds.players.size()==2 and game.sounds.players.all(func(p):return p.max_polyphony==1 and p.volume_db==-8),"two capped voices and reduced gain")
	game.click_at(game.mute_rect().get_center());before=events.size();allow()
	game.sounds.play("buy");game.sounds.play("win",true)
	check(game.sounds.muted and events.size()==before,"mute blocks all priorities")
	check(game.sounds.players.all(func(p):return not p.playing),"mute stops active voices")
	game.restart();check(game.sounds.muted,"restart preserves mute")
	var bank=load("res://sounds.gd").new()
	bank.settings_path=game.sounds.settings_path;root.add_child(bank)
	await process_frame
	check(bank.muted,"new instance reloads saved mute")
	bank.free();game.click_at(game.mute_rect().get_center())
	check(not game.sounds.muted and events.back()=="click","unmute confirms softly")
	game.cash=11000;game.buy_mansion()
	check(game.won and events.back()=="win","victory interrupts cooldown for celebration")
	game.help_open=true;game.click_at(game.mute_rect().get_center())
	check(game.sounds.muted,"mute remains operable on victory/help overlay")
	game.free()
	DirAccess.remove_absolute("res://evidence/audio-unit.cfg")
	print("RESULT: ",checks-failures,"/",checks," passed")
	quit(0 if failures==0 else 1)
