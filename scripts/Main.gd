extends Node2D
# TranceHero v2 - 4 lanes (D-F-J-K) 140 BPM com psybeyond.mp3 + visual neon psy
# D F J K = notas | L = especial | ENTER/ESPACO = recomecar

const BPM := 140.0
const BEAT := 60.0 / BPM
const APPROACH := 2.0
const START_DELAY := 3.0
const RECEPTOR_Y := 620.0
const SPAWN_Y := 90.0
const CENTER_X := 640.0
const AUDIO_FILE := "res://audio/psybeyond.mp3"
const SONG_LINE1 := "PSY BEYOND"
const SONG_LINE2 := "Cosmic Flow - 140 BPM"

const BASE_X := [410.0, 578.0, 750.0, 905.0]
const TOP_X := [598.0, 626.0, 656.0, 686.0]
const LANE_KEYS := [KEY_D, KEY_F, KEY_J, KEY_K]
const LANE_GLYPH := ["@", "O", "*", "~"]
const LANE_COLORS := [
	Color("39ff6a"),
	Color("29cfff"),
	Color("ffd93b"),
	Color("ff3b5c"),
]

var notes: Array = []
var song_time := -START_DELAY
var playing := false
var finished := false
var elapsed := 0.0
var audio_started := false

var score := 0
var combo := 0
var max_combo := 0
var mult := 1
var perfects := 0
var greats := 0
var goods := 0
var misses := 0
var special := 0
var special_ready := false
var fever := false
var fever_time := 0.0
var fever_flash := 0.0

var judge_text := ""
var judge_color := Color.WHITE
var judge_timer := 0.0
var press_anim := [0.0, 0.0, 0.0, 0.0]
var burst_anim := [0.0, 0.0, 0.0, 0.0]

var stars: Array = []
var nebula: Array = []
var eq: Array = []
var sparks: Array = []
var rings: Array = []
var player: AudioStreamPlayer
var bg_tex: Texture2D

var hud: CanvasLayer
var lbl_song: Label
var lbl_score: Label
var lbl_mult: Label
var lbl_combo: Label
var lbl_judge: Label
var lbl_special: Label
var lbl_msg: Label
var lbl_help: Label
var need_tap := false # web/celular: espera primeiro toque (desbloqueia audio)

func _ready() -> void:
	randomize()
	need_tap = OS.has_feature("web")
	_make_deco()
	_build_hud()
	_build_audio()
	_load_or_generate_chart()
	reset_game()

func _make_deco() -> void:
	stars.clear()
	for i in 150:
		stars.append({"pos": Vector2(randf() * 1280.0, randf() * 430.0), "r": randf_range(0.6, 2.4), "ph": randf() * TAU, "sp": randf_range(0.5, 2.0)})
	nebula.clear()
	nebula.append({"pos": Vector2(300, 160), "r": 220.0, "col": Color(0.5, 0.1, 0.9, 0.10), "ph": 0.0})
	nebula.append({"pos": Vector2(980, 140), "r": 250.0, "col": Color(0.0, 0.7, 1.0, 0.08), "ph": 2.1})
	nebula.append({"pos": Vector2(640, 220), "r": 300.0, "col": Color(1.0, 0.2, 0.8, 0.07), "ph": 4.2})
	eq.clear()
	for i in 28:
		eq.append({"ph": randf() * TAU, "sp": randf_range(4.0, 9.0)})
	_load_bg()

func _load_bg() -> void:
	bg_tex = null
	var candidates := ["res://art/bg.png", "res://art/bg.jpg", "res://art/bg.jpeg", "res://art/background.png", "res://art/palco.png"]
	for c in candidates:
		if ResourceLoader.exists(c):
			bg_tex = load(c)
			break

func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	lbl_song = _mk_label(Vector2(24, 14), 24, Color("7df9ff"), HORIZONTAL_ALIGNMENT_LEFT)
	hud.add_child(lbl_song)
	lbl_score = _mk_label(Vector2(980, 14), 40, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	lbl_score.size = Vector2(276, 50)
	hud.add_child(lbl_score)
	lbl_mult = _mk_label(Vector2(980, 62), 34, Color("39ff6a"), HORIZONTAL_ALIGNMENT_RIGHT)
	lbl_mult.size = Vector2(276, 44)
	hud.add_child(lbl_mult)
	lbl_combo = _mk_label(Vector2(24, 190), 44, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	lbl_combo.size = Vector2(360, 140)
	hud.add_child(lbl_combo)
	lbl_judge = _mk_label(Vector2(440, 140), 46, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	lbl_judge.size = Vector2(400, 60)
	hud.add_child(lbl_judge)
	lbl_special = _mk_label(Vector2(948, 220), 28, Color("b6ff2e"), HORIZONTAL_ALIGNMENT_CENTER)
	lbl_special.size = Vector2(308, 130)
	hud.add_child(lbl_special)
	lbl_msg = _mk_label(Vector2(340, 350), 36, Color("ffd93b"), HORIZONTAL_ALIGNMENT_CENTER)
	lbl_msg.size = Vector2(600, 60)
	hud.add_child(lbl_msg)
	lbl_help = _mk_label(Vector2(400, 688), 17, Color(1, 1, 1, 0.75), HORIZONTAL_ALIGNMENT_CENTER)
	lbl_help.size = Vector2(480, 26)
	lbl_help.text = "D F J K = tocar  |  L = especial  |  ENTER = recomecar"
	hud.add_child(lbl_help)

func _mk_label(pos: Vector2, fsize: int, col: Color, align: HorizontalAlignment) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 8)
	l.horizontal_alignment = align
	return l

func _build_audio() -> void:
	player = AudioStreamPlayer.new()
	player.name = "Music"
	add_child(player)
	if ResourceLoader.exists(AUDIO_FILE):
		player.stream = load(AUDIO_FILE)
	elif ResourceLoader.exists("res://audio/musica1.ogg"):
		player.stream = load("res://audio/musica1.ogg")

func chart_path() -> String:
	return "res://charts/test_chart.json"

func audio_length() -> float:
	if player and player.stream:
		return float(player.stream.get_length())
	return 0.0

func _load_or_generate_chart() -> void:
	notes.clear()
	var alen := audio_length()
	# se ja existe um chart longo e valido, usa ele
	if FileAccess.file_exists(chart_path()):
		var f := FileAccess.open(chart_path(), FileAccess.READ)
		var data = JSON.parse_string(f.get_as_text())
		if typeof(data) == TYPE_DICTIONARY and data.has("notes"):
			var arr: Array = data["notes"]
			if arr.size() > 100:
				for n in arr:
					notes.append({"time": float(n[0]), "lane": int(n[1]), "hit": false, "missed": false})
				notes.sort_custom(func(a, b): return float(a["time"]) < float(b["time"]))
				return
	# gera chart 140 BPM cobrindo a musica toda
	var total_beats := 96
	if alen > 10.0:
		total_beats = int((alen - 4.0) / BEAT)
	total_beats = clampi(total_beats, 32, 900)
	var pattern := [0, 1, 2, 3, 3, 2, 1, 0]
	for i in range(total_beats):
		var t := 2.0 + float(i) * BEAT
		# break de 2 beats a cada 32 (respiro estilo breakdown psy)
		if i > 16 and i % 32 >= 28 and i % 32 <= 29:
			continue
		var lane: int = pattern[i % 8]
		if (i / 8) % 2 == 1:
			lane = 3 - lane
		# comeco facil: so semicolcheia simples
		notes.append({"time": t, "lane": lane, "hit": false, "missed": false})
		# apos 16 beats adiciona viradas
		if i > 16 and i % 8 == 7:
			notes.append({"time": t + BEAT * 0.5, "lane": (lane + 2) % 4, "hit": false, "missed": false})
		# parte final: duplas ocasionais pra climax
		if i > total_beats - 32 and i % 8 == 3:
			notes.append({"time": t, "lane": (lane + 1) % 4, "hit": false, "missed": false})
	notes.sort_custom(func(a, b): return float(a["time"]) < float(b["time"]))
	_save_chart()

func _save_chart() -> void:
	var arr: Array = []
	for n in notes:
		arr.append([float(n["time"]), int(n["lane"])])
	var data := {"bpm": BPM, "song": "psybeyond", "notes": arr}
	var f := FileAccess.open(chart_path(), FileAccess.WRITE)
	f.store_string(JSON.stringify(data))

func reset_game() -> void:
	for n in notes:
		n["hit"] = false
		n["missed"] = false
	sparks.clear()
	rings.clear()
	song_time = -START_DELAY
	elapsed = 0.0
	playing = true
	finished = false
	audio_started = false
	score = 0
	combo = 0
	max_combo = 0
	mult = 1
	perfects = 0
	greats = 0
	goods = 0
	misses = 0
	special = 0
	special_ready = false
	fever = false
	fever_time = 0.0
	judge_text = ""
	judge_timer = 0.0
	if player:
		player.stop()

func song_length() -> float:
	var al := audio_length()
	if al > 10.0:
		return al + 1.0
	if notes.is_empty():
		return 30.0
	return float(notes.back()["time"]) + 3.0

func beat_phase() -> float:
	if song_time <= 0.0:
		return 0.0
	return 1.0 - fmod(song_time, BEAT) / BEAT

func _process(delta: float) -> void:
	if need_tap:
		_update_hud()
		queue_redraw()
		return
	elapsed += delta
	if playing and not finished:
		song_time = elapsed - START_DELAY
		if song_time >= 0.0 and not audio_started:
			audio_started = true
			if player and player.stream:
				player.play()
		if audio_started and player and player.playing:
			var p := player.get_playback_position() + AudioServer.get_time_since_last_mix()
			p -= AudioServer.get_output_latency()
			song_time = lerpf(song_time, p, 0.4)
		if fever:
			fever_time -= delta
			fever_flash = maxf(0.0, fever_flash - delta * 2.0)
			if fever_time <= 0.0:
				fever = false
		for n in notes:
			if not bool(n["hit"]) and not bool(n["missed"]) and song_time - float(n["time"]) > 0.18:
				n["missed"] = true
				_register_miss(n)
		if song_time > song_length():
			finished = true
			playing = false
		for i in 4:
			press_anim[i] = maxf(0.0, float(press_anim[i]) - delta * 6.0)
			burst_anim[i] = maxf(0.0, float(burst_anim[i]) - delta * 2.5)
		judge_timer -= delta
		_update_sparks(delta)
		_update_hud()
	queue_redraw()

func _update_sparks(delta: float) -> void:
	for i in range(sparks.size() - 1, -1, -1):
		var s = sparks[i]
		s["life"] = float(s["life"]) - delta
		if float(s["life"]) <= 0.0:
			sparks.remove_at(i)
			continue
		s["pos"] = Vector2(s["pos"]) + Vector2(s["vel"]) * delta
		s["vel"] = Vector2(s["vel"]) * (1.0 - delta * 2.5) + Vector2(0, 300) * delta
	for i in range(rings.size() - 1, -1, -1):
		var r = rings[i]
		r["life"] = float(r["life"]) - delta
		r["rad"] = float(r["rad"]) + delta * 260.0
		if float(r["life"]) <= 0.0:
			rings.remove_at(i)

func _spawn_hit_fx(lane: int, quality: int) -> void:
	var pos := Vector2(BASE_X[lane], RECEPTOR_Y)
	var col: Color = LANE_COLORS[lane]
	var count := 14 if quality == 0 else 9
	for i in count:
		var a := randf() * TAU
		var sp := randf_range(120.0, 420.0)
		sparks.append({
			"pos": pos + Vector2(randf_range(-8, 8), randf_range(-8, 8)),
			"vel": Vector2(cos(a), sin(a)) * sp + Vector2(0, -160),
			"life": randf_range(0.35, 0.8),
			"max": 0.8,
			"color": col,
			"size": randf_range(2.0, 5.0),
		})
	rings.append({"pos": pos, "lane": lane, "life": 0.45, "rad": 30.0})
	burst_anim[lane] = 1.0

func _update_hud() -> void:
	lbl_score.text = str(score)
	var mtxt := "x%d" % mult
	if fever:
		mtxt += " FEVER!"
		lbl_mult.add_theme_color_override("font_color", Color("ffd93b"))
	else:
		lbl_mult.add_theme_color_override("font_color", Color("39ff6a"))
	lbl_mult.text = mtxt
	if combo >= 2:
		lbl_combo.text = "%d\nSEQUENCIA" % combo
	else:
		lbl_combo.text = ""
	lbl_judge.text = judge_text
	lbl_judge.add_theme_color_override("font_color", judge_color)
	lbl_judge.modulate.a = clampf(judge_timer * 2.0, 0.0, 1.0)
	# pop no julgamento
	var pop := 1.0 + 0.35 * clampf(judge_timer, 0.0, 1.0)
	lbl_judge.scale = Vector2(pop, pop)
	if special_ready and not fever:
		lbl_special.text = "ESPECIAL\n20/20 - aperte [L]!"
		lbl_special.add_theme_color_override("font_color", Color("ffd93b"))
	elif fever:
		lbl_special.text = "SINTA O FLOW!\n%.1fs" % fever_time
	else:
		lbl_special.text = "ESPECIAL\n%d/20" % special
	var total := song_length()
	var cur := clampf(song_time, 0.0, total)
	lbl_song.text = "%s\n%s  %.0f:%02d / %.0f:%02d" % [SONG_LINE1, SONG_LINE2, floor(cur / 60.0), int(cur) % 60, floor(total / 60.0), int(total) % 60]
	if finished:
		lbl_msg.text = "FIM! %d pts  max %d  ENTER p/ de novo" % [score, max_combo]
	elif need_tap:
		lbl_msg.text = "TOQUE PARA COMECAR"
	elif song_time < 0.0:
		lbl_msg.text = "Prepare-se... %.1f" % absf(song_time)
	else:
		lbl_msg.text = ""

func _lane_from_x(x: float) -> int:
	var best := 0
	var bd := 999999.0
	for lane in 4:
		var d := absf(x - float(BASE_X[lane]))
		if d < bd:
			bd = d
			best = lane
	return best

func _tap_at(pos: Vector2) -> void:
	if need_tap:
		need_tap = false
		elapsed = 0.0
		return
	if finished:
		reset_game()
		need_tap = false
		elapsed = 0.0
		return
	# toque na area especial (canto direito) ativa fever
	if special_ready and not fever and pos.x > 950.0 and pos.y < 350.0:
		fever = true
		fever_time = 10.0
		fever_flash = 1.0
		special = 0
		special_ready = false
		judge_text = "ESPECIAL LIBERADO!"
		judge_color = Color("ffd93b")
		judge_timer = 1.5
		return
	_hit_lane(_lane_from_x(pos.x))

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_tap_at(event.position)
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_tap_at(event.position)
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if need_tap:
			need_tap = false
			elapsed = 0.0
			return
		var k: int = event.keycode
		if k == KEY_ENTER or k == KEY_KP_ENTER or k == KEY_SPACE:
			if finished or song_time < 0.5:
				reset_game()
			return
		if k == KEY_L and special_ready and not fever:
			fever = true
			fever_time = 10.0
			fever_flash = 1.0
			special = 0
			special_ready = false
			judge_text = "ESPECIAL LIBERADO!"
			judge_color = Color("ffd93b")
			judge_timer = 1.5
			return
		for lane in 4:
			if k == LANE_KEYS[lane]:
				_hit_lane(lane)
				return

func _hit_lane(lane: int) -> void:
	if finished:
		return
	press_anim[lane] = 1.0
	var best := -1
	var best_diff := 999.0
	for i in range(notes.size()):
		var n = notes[i]
		if int(n["lane"]) != lane:
			continue
		if bool(n["hit"]) or bool(n["missed"]):
			continue
		var d := absf(song_time - float(n["time"]))
		if d < best_diff:
			best_diff = d
			best = i
	if best >= 0 and best_diff <= 0.18:
		var n = notes[best]
		n["hit"] = true
		if best_diff <= 0.06:
			_register_hit("PERFEITA!", Color("39ff6a"), 300)
			perfects += 1
			_spawn_hit_fx(lane, 0)
			_add_special(1)
		elif best_diff <= 0.12:
			_register_hit("OTIMO!", Color("29cfff"), 150)
			greats += 1
			_spawn_hit_fx(lane, 1)
			_add_special(1)
		else:
			_register_hit("BOM", Color("ffd93b"), 50)
			goods += 1
			_spawn_hit_fx(lane, 2)

func _register_hit(txt: String, col: Color, base: int) -> void:
	combo += 1
	max_combo = maxi(max_combo, combo)
	if combo >= 32:
		mult = 8
	elif combo >= 16:
		mult = 4
	elif combo >= 8:
		mult = 2
	else:
		mult = 1
	var gain := base * mult
	if fever:
		gain *= 2
	score += gain
	judge_text = txt
	judge_color = col
	judge_timer = 0.8

func _add_special(v: int) -> void:
	if fever or special_ready:
		return
	special = mini(20, special + v)
	if special >= 20:
		special_ready = true
		judge_text = "ESPECIAL LIBERADO!"
		judge_color = Color("ffd93b")
		judge_timer = 1.5

func _register_miss(n) -> void:
	combo = 0
	mult = 1
	misses += 1
	judge_text = "MISS"
	judge_color = Color("ff3b5c")
	judge_timer = 0.6
	# faquinha vermelha onde perdeu
	var lane: int = int(n["lane"])
	sparks.append({
		"pos": Vector2(float(BASE_X[lane]), RECEPTOR_Y),
		"vel": Vector2(randf_range(-60, 60), -80),
		"life": 0.4, "max": 0.4,
		"color": Color("ff3b5c"),
		"size": 3.0,
	})

# ---------------- VISUAL ----------------
func _draw() -> void:
	_draw_bg()
	_draw_lasers()
	_draw_highway()
	_draw_notes()
	_draw_receptors()
	_draw_fx()
	if fever_flash > 0.0:
		draw_rect(Rect2(0, 0, 1280, 720), Color(1, 0.9, 0.3, fever_flash * 0.18))
	if fever:
		var hue := fmod(elapsed * 0.4, 1.0)
		var c := Color.from_hsv(hue, 0.9, 1.0, 0.9)
		draw_rect(Rect2(0, 0, 1280, 8), c)
		draw_rect(Rect2(0, 712, 1280, 8), c)

func _draw_bg() -> void:
	# MODO FOTO: sua referencia como fundo real, sem procedural por cima
	if bg_tex != null:
		draw_texture_rect(bg_tex, Rect2(0, 0, 1280, 720), false)
		# overlay leve pra HUD ler bem sem apagar a foto
		draw_rect(Rect2(0, 0, 1280, 720), Color(0.02, 0.0, 0.08, 0.12))
		# pulso do beat sobre o palco
		var bp0 := beat_phase()
		if fever:
			bp0 = 1.0
		draw_circle(Vector2(CENTER_X, 215), 150 + 14 * bp0, Color(0.4, 0.1, 0.9, 0.06 + 0.06 * bp0))
		return
	draw_rect(Rect2(0, 0, 1280, 720), Color("060212"))
	draw_rect(Rect2(0, 0, 1280, 430), Color("0d0433"))
	# nebulosas lentas
	for nb in nebula:
		var off := Vector2(sin(elapsed * 0.3 + float(nb["ph"])) * 40.0, cos(elapsed * 0.22 + float(nb["ph"])) * 20.0)
		var pos: Vector2 = nb["pos"] + off
		draw_circle(pos, float(nb["r"]), nb["col"])
		draw_circle(pos, float(nb["r"]) * 0.6, nb["col"])
	# estrelas cintilantes
	for s in stars:
		var a := 0.3 + 0.45 * (0.5 + 0.5 * sin(elapsed * float(s["sp"]) * 2.0 + float(s["ph"])))
		draw_circle(s["pos"], float(s["r"]), Color(1, 1, 1, a))
	# sol/olho do palco pulsando no kick 140bpm
	var bp := beat_phase()
	if fever:
		bp = 1.0
	var cx := CENTER_X + sin(elapsed * 0.5) * 8.0
	draw_circle(Vector2(cx, 215), 250 + 26 * bp, Color(0.5, 0.1, 0.95, 0.10 + 0.10 * bp))
	draw_circle(Vector2(cx, 215), 150 + 14 * bp, Color(0.1, 0.8, 1.0, 0.10 + 0.12 * bp))
	draw_circle(Vector2(cx, 215), 80 + 8 * bp, Color(1.0, 0.35, 1.0, 0.14 + 0.14 * bp))
	draw_circle(Vector2(cx, 215), 34, Color(1, 1, 1, 0.25 + 0.3 * bp))
	# chao + multidao com palitos neon
	draw_rect(Rect2(0, 430, 1280, 290), Color("05010f"))
	for i in 70:
		var x := float(i) * 18.6
		var bounce := 0.5 + 0.5 * sin(elapsed * (5.0 + fmod(float(i), 3.0)) + float(i) * 1.7)
		var h := 14.0 + 22.0 * bounce * (0.4 + 0.6 * bp)
		draw_rect(Rect2(x, 486 - h * 0.35, 11, h), Color(0.09, 0.03, 0.18))
		if fmod(float(i), 4.0) == 0.0:
			var stick_col: Color = LANE_COLORS[i % 4]
			var sy := 452.0 - bounce * 26.0
			draw_line(Vector2(x + 5, sy + 12), Vector2(x + 5, sy - 8), Color(stick_col.r, stick_col.g, stick_col.b, 0.8), 2.0)
			draw_circle(Vector2(x + 5, sy - 10), 3.0, stick_col)
	# equalizador lateral
	for i in range(eq.size()):
		var e = eq[i]
		var v := 0.5 + 0.5 * sin(elapsed * float(e["sp"]) + float(e["ph"]) + song_time * 2.0)
		var h2 := 20.0 + 90.0 * v * (0.35 + 0.65 * bp)
		var lx := 30.0 + float(i % 14) * 12.0
		var rx := 1250.0 - float(i % 14) * 12.0
		var yy := 420.0 - h2 if i < 14 else 420.0 - h2 * 0.7
		draw_rect(Rect2(lx, yy, 7, h2), Color(0.2, 0.9, 1.0, 0.35))
		draw_rect(Rect2(rx, yy, 7, h2), Color(1.0, 0.3, 0.9, 0.35))

func _draw_lasers() -> void:
	var bp := beat_phase()
	var top := Vector2(CENTER_X, 215)
	for k in 4:
		var ang := sin(elapsed * (0.6 + float(k) * 0.23) + float(k) * 1.7) * 500.0
		var col: Color = LANE_COLORS[k]
		draw_line(top, Vector2(CENTER_X + ang, 470), Color(col.r, col.g, col.b, 0.10 + 0.10 * bp), 3.0)

func _draw_highway() -> void:
	var top_y := SPAWN_Y - 12.0
	var bot_y := 702.0
	var glow := 0.5 + 0.5 * beat_phase()
	var poly := PackedVector2Array([
		Vector2(TOP_X[0] - 44, top_y), Vector2(TOP_X[3] + 44, top_y),
		Vector2(BASE_X[3] + 110, bot_y), Vector2(BASE_X[0] - 110, bot_y),
	])
	draw_colored_polygon(poly, Color(0.01, 0.01, 0.04, 1.0))
	# bordas neon animadas
	var bc := 2.5 + 2.0 * glow
	draw_line(poly[0], poly[3], Color(0.15, 0.9, 1.0, 0.9), bc)
	draw_line(poly[1], poly[2], Color(1.0, 0.25, 0.9, 0.9), bc)
	draw_line(poly[0], poly[3], Color(1, 1, 1, 0.25 * glow), bc + 6.0)
	draw_line(poly[1], poly[2], Color(1, 1, 1, 0.25 * glow), bc + 6.0)
	# faixas
	for lane in range(4):
		var tx: float = TOP_X[lane] + (15.0 if lane < 3 else 44.0)
		var bx: float = BASE_X[lane] + (84.0 if lane < 3 else 110.0)
		draw_line(Vector2(tx, top_y), Vector2(bx, bot_y), Color(1, 1, 1, 0.09), 2.0)
	# linha do horizonte
	draw_line(Vector2(TOP_X[0] - 44, top_y), Vector2(TOP_X[3] + 44, top_y), Color(1, 1, 1, 0.3 + 0.3 * glow), 2.0)

func lane_pos(lane: int, progress: float) -> Vector2:
	var p := clampf(progress, 0.0, 1.0)
	var pp := pow(p, 1.55)
	return Vector2(lerpf(float(TOP_X[lane]), float(BASE_X[lane]), pp), lerpf(SPAWN_Y, RECEPTOR_Y, pp))

func _draw_notes() -> void:
	for n in notes:
		if bool(n["hit"]) or bool(n["missed"]):
			continue
		var dt: float = float(n["time"]) - song_time
		if dt > APPROACH or dt < -0.25:
			continue
		var progress := 1.0 - dt / APPROACH
		var lane: int = int(n["lane"])
		var pos := lane_pos(lane, progress)
		var col: Color = LANE_COLORS[lane]
		var radius := lerpf(9.0, 26.0, progress)
		var rec := Vector2(float(BASE_X[lane]), RECEPTOR_Y)
		var w := lerpf(2.0, 7.0, progress)
		draw_line(pos, rec, Color(col.r, col.g, col.b, 0.30), w)
		draw_line(pos, rec, Color(1, 1, 1, 0.10), w * 0.4)
		draw_circle(pos, radius + 11.0, Color(col.r, col.g, col.b, 0.16))
		draw_circle(pos, radius + 4.0, Color(col.r, col.g, col.b, 0.5))
		draw_circle(pos, radius, col)
		draw_circle(pos, radius * 0.62, Color(0, 0, 0, 0.85))
		draw_circle(pos, radius * 0.55, Color(1, 1, 1, 0.95))
		_draw_symbol(pos, lane, radius * 0.42, Color(col.r * 0.15, col.g * 0.15, col.b * 0.15), 2.5)
		draw_arc(pos, radius, 0, TAU, 26, Color(1, 1, 1, 0.9), 2.0)

# Simbolos dos botoes: 0 espiral / 1 olho / 2 sol / 3 triskel
func _draw_symbol(c: Vector2, lane: int, s: float, col: Color, w: float) -> void:
	if lane == 0:
		# espiral verde
		var pts := PackedVector2Array()
		var turns := 2.6
		var steps := 40
		for i in range(steps + 1):
			var a := float(i) / float(steps) * turns * TAU
			var r := s * float(i) / float(steps)
			pts.append(c + Vector2(cos(a), sin(a)) * r)
		draw_polyline(pts, col, w)
	elif lane == 1:
		# olho azul: amendoa + pupila
		var pts_top := PackedVector2Array()
		var pts_bot := PackedVector2Array()
		for i in range(17):
			var t := float(i) / 16.0
			var x := lerpf(-s, s, t)
			var y_top := -sin(t * PI) * s * 0.62
			var y_bot := sin(t * PI) * s * 0.62
			pts_top.append(c + Vector2(x, y_top))
			pts_bot.append(c + Vector2(x, y_bot))
		draw_polyline(pts_top, col, w)
		draw_polyline(pts_bot, col, w)
		draw_circle(c, s * 0.32, col)
		draw_circle(c, s * 0.13, Color.WHITE)
	elif lane == 2:
		# sol amarelo: nucleo + 12 raios
		draw_circle(c, s * 0.35, col)
		draw_arc(c, s * 0.35, 0, TAU, 20, col, w * 0.8)
		for k in 12:
			var a := float(k) / 12.0 * TAU + 0.26
			var p1 := c + Vector2(cos(a), sin(a)) * s * 0.52
			var p2 := c + Vector2(cos(a), sin(a)) * s * 0.95
			draw_line(p1, p2, col, w * 0.8)
	elif lane == 3:
		# triskel vermelho: 3 virgulas em 120 graus
		for k in 3:
			var a0 := float(k) / 3.0 * TAU
			var cc := c + Vector2(cos(a0), sin(a0)) * s * 0.30
			draw_arc(cc, s * 0.45, a0 + PI * 0.5, a0 + PI * 1.7, 14, col, w)
			var tip := cc + Vector2(cos(a0 + PI * 1.7), sin(a0 + PI * 1.7)) * s * 0.45
			draw_circle(tip, w * 0.7, col)

func _draw_receptors() -> void:
	var font: Font = ThemeDB.fallback_font
	var bp := beat_phase()
	for lane in 4:
		var col: Color = LANE_COLORS[lane]
		var pos := Vector2(float(BASE_X[lane]), RECEPTOR_Y)
		var press: float = float(press_anim[lane])
		var burst: float = float(burst_anim[lane])
		var r: float = 52.0 + 9.0 * press + 4.0 * bp
		draw_circle(pos, r + 16 + burst * 26.0, Color(col.r, col.g, col.b, 0.14 + 0.22 * press + 0.20 * burst))
		draw_circle(pos, r + 5, Color(0, 0, 0, 0.92))
		draw_circle(pos, r, Color(col.r * 0.22, col.g * 0.22, col.b * 0.22))
		# anel duplo quando fever
		if fever:
			draw_arc(pos, r + 8, elapsed * 3.0, elapsed * 3.0 + PI * 1.5, 32, Color(1, 1, 1, 0.7), 3.0)
		draw_arc(pos, r, 0, TAU, 48, col, 5.0 + 4.0 * press)
		_draw_symbol(pos, lane, 24.0 + 4.0 * press, Color.WHITE, 3.5)
		var key_txt := "DFJK"[lane]
		var ks := font.get_string_size(key_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 20)
		draw_string(font, pos + Vector2(-ks.x * 0.5, 64), key_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1, 0.85))

func _draw_fx() -> void:
	for s in sparks:
		var life: float = float(s["life"])
		var a := clampf(life / 0.8, 0.0, 1.0)
		var c: Color = s["color"]
		draw_circle(s["pos"], float(s["size"]) * (0.5 + a), Color(c.r, c.g, c.b, a))
		draw_circle(s["pos"], float(s["size"]) * 0.5, Color(1, 1, 1, a))
	for rg in rings:
		var c2: Color = LANE_COLORS[int(rg["lane"])]
		var a2 := clampf(float(rg["life"]) / 0.45, 0.0, 1.0)
		draw_arc(rg["pos"], float(rg["rad"]), 0, TAU, 40, Color(c2.r, c2.g, c2.b, a2), 4.0)
