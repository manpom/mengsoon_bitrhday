extends Node2D
## 미니게임 1 「원 투 뿡!」 — 리듬 파트
##
## 욕실 컷신([code]one_two_bboong.gd[/code])이 암전으로 끝나면 이 씬이 이어받습니다.
##
## [b]무대[/b]
##   맹돌이가 가운데에서 눈물 흘리며 웃고 있고, 맹순이는 뒤에서 보고 있습니다.
##   맹돌이 둘레 세 군데(왼쪽 · 위 · 오른쪽)에 판정 링이 있고, 노트가 위에서
##   떨어져 링에 닿는 순간 그 레인의 키를 누릅니다.
##
##   왼쪽  글러브 노트 → [b]←[/b] (또는 A) → 맹돌이가 "원"
##   오른쪽 글러브 노트 → [b]→[/b] (또는 D) → 맹돌이가 "투"
##   위    맹순이 얼굴 → [b]스페이스[/b] (또는 ↑) → 맹돌이가 "뿡"
##
##   아이폰에는 키보드가 없으므로 화면을 세로로 삼등분해서 씁니다.
##   왼쪽 36% = 원, 오른쪽 36% = 투, 가운데 = 뿡.
##
## [b]왜 키를 셋으로 나눴나[/b]
##   버튼 하나면 같은 박에 노트를 두 개 놓을 수가 없습니다. 어느 쪽을 친
##   것인지 구별할 방법이 없기 때문입니다. 키를 나누니 "←와 →를 거의 동시에"
##   같은 리듬이 가능해졌습니다 (채보의 ★ 표시 마디).
##
## [b]박자는 어디서 오나[/b]
##   [code]one_two_chart.gd[/code] 는 [code]tools/build_bgm.ps1[/code] 이
##   음악과 함께 구워 낸 자동 생성 파일입니다. 채보를 바꾸려면 그 스크립트의
##   [code]$BARS[/code] 표를 고치고 다시 실행하세요. 음악과 노트가 같이 바뀝니다.
##
## [b]흐름[/b]
##   페이드인 → 시범(맹돌이가 혼자 원 투 뿡) → 연습(플레이어가 따라함)
##   → 3 2 1 → 본편 32초 → 결과 → 방으로 복귀

# ============================================================
#  ★ 화면에 뜨는 글자는 전부 여기 있습니다. 고칠 땐 여기만 보면 됩니다.
#  (리듬 파트에는 대사창이 없고, 화면 아래 한 줄짜리 안내만 뜹니다)
# ============================================================
const M_WATCH := "맹돌이가 놀리고 있다."
const M_KEYS := "←  원        →  투        스페이스  뿡"
const M_LOOK := "원, 투, 뿡!  박자를 잘 봐."
const M_YOUR_TURN := "이번엔 네가."

## %d 자리에 점수 · 최대 콤보 · 정확도(%) 가 순서대로 들어갑니다
const M_RESULT := "%d점   최대 %d콤보   %d%%"
const M_CLEAR := "맹돌이는 그렇게 한 시간을 더 웃었다."
const M_RETRY := "...다시 해볼래?"

const Chart := preload("res://scripts/minigames/one_two_chart.gd")

## 노트가 화면 위에서 링까지 내려오는 데 걸리는 시간(초).
## 레인마다 거리가 다르므로 속도가 아니라 [b]시간[/b]을 고정합니다.
## 그래야 어느 레인이든 "떨어지는 걸 보고 반응할 시간"이 똑같습니다.
const APPROACH := 1.55
const SPAWN_Y := -88.0

## 링 위치. Chart.LEFT / UP / RIGHT 순서와 같습니다.
const RING_POS: Array[Vector2] = [
	Vector2(220, 352),   # 왼쪽  - 원
	Vector2(480, 192),   # 위    - 뿡
	Vector2(740, 352),   # 오른쪽 - 투
]

## 판정 창(초). 정박에서 얼마나 벗어났는지로 나눕니다.
const W_GREAT := 0.052
const W_GOOD := 0.105
const W_COOL := 0.175

const POINTS := { "GREAT": 100, "GOOD": 60, "COOL": 30 }

## 맹돌이는 위 링 바로 아래 가운데. 맹순이는 그보다 위(=뒤)에 서서 구경합니다.
## 셋 다 노트가 내려오는 세 줄(x = 110 / 240 / 370)을 비켜 있어야 합니다.
const MENGDOL_HOME := Vector2(480, 480)
const MENGSOON_HOME := Vector2(357, 408)

## 방귀가 나오는 자리 (맹돌이 기준). 구름 그림의 꼬리 끝이 여기 붙습니다.
const BBOONG_FROM := Vector2(-34, -36)

const POSE := {
	"idle": preload("res://assets/sprites/characters/mengdol/mengdol_nude_lol.png"),
	"one": preload("res://assets/sprites/characters/mengdol/mengdol_nude_lol_punch1.png"),
	"two": preload("res://assets/sprites/characters/mengdol/mengdol_nude_lol_punch2.png"),
	"fart": preload("res://assets/sprites/characters/mengdol/mengdol_nude_lol_fart.png"),
}
const NOTE_TEX := [
	preload("res://assets/sprites/stages/note_glove.png"),
	preload("res://assets/sprites/stages/note_face.png"),
	preload("res://assets/sprites/stages/note_glove.png"),
]
const RING_TEX := preload("res://assets/sprites/stages/ring.png")
const RING_LIT := preload("res://assets/sprites/stages/ring_lit.png")
const FART_PUFF := [
	preload("res://assets/sprites/stages/fart1.png"),
	preload("res://assets/sprites/stages/fart2.png"),
	preload("res://assets/sprites/stages/fart3.png"),
]

const SFX_GREAT := preload("res://assets/audio/sfx/hit_great.wav")
const SFX_GOOD := preload("res://assets/audio/sfx/hit_good.wav")
const SFX_COOL := preload("res://assets/audio/sfx/hit_cool.wav")
const SFX_MISS := preload("res://assets/audio/sfx/miss.wav")
const SFX_BBOONG := preload("res://assets/audio/sfx/bboong2.wav")
const SFX_TICK := preload("res://assets/audio/sfx/tick.wav")
const SFX_TOCK := preload("res://assets/audio/sfx/tock.wav")

@onready var mengdol: Sprite2D = $Stage/Mengdol
@onready var mengsoon: Sprite2D = $Stage/Mengsoon
@onready var fart: Sprite2D = $Stage/Fart
@onready var notes_root: Node2D = $Notes
@onready var rings: Array[Sprite2D] = [$Rings/RingL, $Rings/RingU, $Rings/RingR]
@onready var judge_label: Label = $Ui/Judge
@onready var combo_label: Label = $Ui/Combo
@onready var score_label: Label = $Ui/Score
@onready var msg_label: Label = $Ui/Msg
@onready var fade: ColorRect = $Fx/Fade
@onready var music: AudioStreamPlayer = $Music
@onready var sfx: AudioStreamPlayer = $Sfx
@onready var sfx2: AudioStreamPlayer = $Sfx2

## 지금 이 판의 시계(초). 연습 중에는 직접 더하고, 본편에서는 음악의
## 재생 위치에서 읽어 옵니다. 노트는 전부 이 값 하나만 봅니다.
var _time := 0.0
var _running := false
var _use_music_clock := false

## 아직 처리되지 않은 노트들. 각 항목은
##   { "t": 판정 시각(초), "lane": 0/1/2, "node": Sprite2D 또는 null, "done": bool }
var _pending: Array[Dictionary] = []

var _score := 0
var _combo := 0
var _best_combo := 0
var _hits := 0
var _total := 0
var _pose_timer := 0.0
var _bob := 0.0


func _ready() -> void:
	fade.color.a = 1.0
	mengdol.position = MENGDOL_HOME
	mengdol.texture = POSE["idle"]
	mengsoon.position = MENGSOON_HOME
	fart.visible = false
	judge_label.modulate.a = 0.0
	msg_label.modulate.a = 0.0
	_refresh_hud()
	_play()


func _play() -> void:
	await get_tree().create_timer(0.3).timeout
	await _fade_to(0.0, 0.8)
	await _tutorial()
	await _countdown()
	_start_song()


# ------------------------------------------------------------ 매 프레임

func _process(delta: float) -> void:
	# 맹돌이는 박에 맞춰 통통 튑니다. 음악이 없을 때도 같은 박으로 흔들리게
	# _time 만 보고 계산합니다.
	_bob = _time * Chart.BPM / 60.0
	var lift := absf(sin(_bob * PI)) * 8.0
	mengdol.position.y = MENGDOL_HOME.y - lift
	mengsoon.position.y = MENGSOON_HOME.y - absf(sin(_bob * PI * 0.5)) * 4.0

	if _pose_timer > 0.0:
		_pose_timer -= delta
		if _pose_timer <= 0.0:
			mengdol.texture = POSE["idle"]
	if not _running:
		return

	if _use_music_clock:
		_time = _song_time()
	else:
		_time += delta

	_spawn_due()
	_move_notes()
	_drop_missed()


## 음악의 재생 위치를 오디오 출력 지연까지 빼서 읽습니다.
## 이걸 안 하면 소리보다 그림이 몇 십 ms 앞서 보입니다.
func _song_time() -> float:
	var t := music.get_playback_position() + AudioServer.get_time_since_last_mix()
	return t - AudioServer.get_output_latency()


func _spawn_due() -> void:
	for n in _pending:
		if n["node"] != null or n["done"]:
			continue
		if _time < n["t"] - APPROACH:
			continue
		var s := Sprite2D.new()
		s.texture = NOTE_TEX[n["lane"]]
		s.position = Vector2(RING_POS[n["lane"]].x, SPAWN_Y)
		notes_root.add_child(s)
		n["node"] = s


func _move_notes() -> void:
	for n in _pending:
		# ★ 순서 주의: done 을 먼저 봅니다.
		# 맞은 노트는 사라지는 트윈이 끝나면 queue_free 되는데, 그때부터
		# n["node"] 는 "이미 해제된 인스턴스"입니다. 그걸 Sprite2D 로 받는
		# 순간(대입 자체에서) 에러가 납니다 - if 문까지 가지도 못합니다.
		if n["done"] or n["node"] == null or not is_instance_valid(n["node"]):
			continue
		var s: Sprite2D = n["node"]
		var target: Vector2 = RING_POS[n["lane"]]
		var k: float = clampf((_time - (n["t"] - APPROACH)) / APPROACH, 0.0, 1.4)
		s.position = Vector2(target.x, lerpf(SPAWN_Y, target.y, k))
		# 링에 가까워질수록 또렷해집니다
		s.modulate.a = clampf(k * 2.5, 0.0, 1.0)


func _drop_missed() -> void:
	for n in _pending:
		if n["done"]:
			continue
		if _time <= n["t"] + W_COOL:
			continue
		_resolve(n, "")


# ------------------------------------------------------------ 입력

## 레인마다 키가 따로입니다.
##   ←(또는 A) 왼쪽 글러브 "원"   ·   →(또는 D) 오른쪽 글러브 "투"
##   스페이스(또는 ↑) 위의 맹순이 얼굴 "뿡"
##
## 버튼 하나였을 때는 같은 박에 노트를 두 개 놓을 수가 없었습니다. 키를 셋으로
## 나눠서 "거의 동시에 눌러야 하는" 리듬이 가능해졌습니다 (채보의 ★ 표시 마디).
##
## 아이폰에는 키보드가 없으므로 화면을 세로로 삼등분해서 씁니다.
## 왼쪽 36% = 원, 오른쪽 36% = 투, 가운데 = 뿡.
func _unhandled_input(event: InputEvent) -> void:
	if not _running:
		return
	var lane := -1
	if event.is_action_pressed("lane_left"):
		lane = Chart.LEFT
	elif event.is_action_pressed("lane_right"):
		lane = Chart.RIGHT
	elif event.is_action_pressed("lane_up"):
		lane = Chart.UP
	elif event is InputEventMouseButton and event.pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		# ★ InputEventScreenTouch 은 일부러 안 봅니다.
		#   프로젝트 설정의 emulate_mouse_from_touch 가 켜져 있어서(기본값),
		#   손가락 한 번에 터치 이벤트와 마우스 이벤트가 [b]둘 다[/b] 옵니다.
		#   양쪽을 다 처리하면 한 번 탭에 노트가 두 개 사라집니다.
		#   방 안의 이동/조사도 마우스 쪽만 보므로 여기서도 마우스만 봅니다.
		lane = _lane_at((event as InputEventMouseButton).position.x)
	if lane < 0:
		return
	get_viewport().set_input_as_handled()
	_hit_lane(lane)


## 화면 x 좌표 하나를 레인 번호로 바꿉니다 (터치 전용).
func _lane_at(px: float) -> int:
	var w := float(get_viewport().get_visible_rect().size.x)
	if px < w * 0.36:
		return Chart.LEFT
	if px > w * 0.64:
		return Chart.RIGHT
	return Chart.UP


## 그 레인에서 지금 시각에 가장 가까운, 아직 안 친 노트를 판정합니다.
## 다른 레인 노트는 쳐다보지 않습니다 - 그래야 "왼쪽을 눌렀는데 위 노트가
## 사라지는" 일이 안 생깁니다.
func _hit_lane(lane: int) -> void:
	var best: Dictionary = {}
	var best_dt := INF
	for n in _pending:
		if n["done"] or int(n["lane"]) != lane:
			continue
		var dt: float = absf(_time - n["t"])
		if dt < best_dt:
			best_dt = dt
			best = n
	if best.is_empty() or best_dt > W_COOL:
		return       # 허공에 친 것은 그냥 무시합니다 (감점까지 하면 너무 맵습니다)
	var grade := "COOL"
	if best_dt <= W_GREAT:
		grade = "GREAT"
	elif best_dt <= W_GOOD:
		grade = "GOOD"
	_resolve(best, grade)


## 노트 하나를 끝냅니다. $grade 가 빈 문자열이면 놓친 것입니다.
func _resolve(n: Dictionary, grade: String) -> void:
	n["done"] = true
	var lane: int = n["lane"]
	# 해제된 인스턴스는 "대입" 자체가 에러라서, 받기 전에 확인합니다.
	var s: Node2D = null
	if n["node"] != null and is_instance_valid(n["node"]):
		s = n["node"]

	if grade.is_empty():
		_combo = 0
		_show_judge("MISS", Color(0.85, 0.45, 0.5))
		_play_sfx(sfx, SFX_MISS)
		if s != null:
			_fade_note(s, false)
		_refresh_hud()
		return

	_hits += 1
	_score += POINTS[grade]
	_combo += 1
	_best_combo = maxi(_best_combo, _combo)

	match grade:
		"GREAT":
			_show_judge("GREAT!", Color(1.0, 0.88, 0.35))
			_play_sfx(sfx, SFX_GREAT)
		"GOOD":
			_show_judge("GOOD", Color(0.62, 0.92, 1.0))
			_play_sfx(sfx, SFX_GOOD)
		_:
			_show_judge("COOL", Color(0.78, 0.84, 0.95))
			_play_sfx(sfx, SFX_COOL)

	if s != null:
		_fade_note(s, true)
	_flash_ring(lane)
	_react(lane)
	_refresh_hud()


# ------------------------------------------------------------ 연출

## 맞은 노트는 살짝 커지면서 흐려집니다. 놓친 노트는 그냥 아래로 흘러내립니다.
func _fade_note(s: Node2D, hit: bool) -> void:
	var tw := create_tween().set_parallel(true)
	if hit:
		tw.tween_property(s, "scale", Vector2(1.7, 1.7), 0.22) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(s, "modulate:a", 0.0, 0.22)
	else:
		tw.tween_property(s, "position:y", s.position.y + 52.0, 0.35)
		tw.tween_property(s, "modulate:a", 0.0, 0.35)
	tw.chain().tween_callback(s.queue_free)


func _flash_ring(lane: int) -> void:
	var r: Sprite2D = rings[lane]
	r.texture = RING_LIT
	r.scale = Vector2(1.25, 1.25)
	var tw := create_tween()
	tw.tween_property(r, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
	tw.tween_callback(func() -> void: r.texture = RING_TEX)


## 맹돌이의 반응. 왼쪽이면 원, 오른쪽이면 투, 위쪽이면 뿡.
func _react(lane: int) -> void:
	match lane:
		Chart.LEFT:
			mengdol.texture = POSE["one"]
			_play_sfx(sfx2, SFX_TICK)
		Chart.RIGHT:
			mengdol.texture = POSE["two"]
			_play_sfx(sfx2, SFX_TOCK)
		Chart.UP:
			mengdol.texture = POSE["fart"]
			_play_sfx(sfx2, SFX_BBOONG)
			_puff()
	_pose_timer = 0.22


## 방귀 구름이 세 단계로 부풀었다 사라집니다.
##
## ★ 구름 그림은 [b]꼬리 끝[/b]이 항상 오른쪽 아래에서 (6, 6) 픽셀에
##   있도록 그려져 있습니다. 그래서 스프라이트 offset 을 (6 - w/2, 6 - h/2)
##   로 잡으면 노드 위치가 곧 꼬리 끝이 되고, 그림이 커져도 그 점은 안
##   움직입니다. 위치를 한 번만 정해 두면 세 단계 내내 똥꼬에 붙어 있습니다.
##   (예전에는 가운데 기준이라 커질 때마다 손으로 밀어야 했고, 그래도 어긋났습니다)
func _puff() -> void:
	fart.position = mengdol.position + BBOONG_FROM
	fart.visible = true
	fart.modulate.a = 1.0
	fart.scale = Vector2.ONE
	for i in FART_PUFF.size():
		fart.texture = FART_PUFF[i]
		var s: Vector2 = FART_PUFF[i].get_size()
		fart.offset = Vector2(6.0 - s.x * 0.5, 6.0 - s.y * 0.5)
		await get_tree().create_timer(0.07).timeout
	var tw := create_tween()
	tw.tween_property(fart, "modulate:a", 0.0, 0.45)
	await tw.finished
	fart.visible = false


func _show_judge(text: String, color: Color) -> void:
	judge_label.text = text
	judge_label.modulate = color
	judge_label.modulate.a = 1.0
	judge_label.scale = Vector2(0.5, 0.5)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(judge_label, "scale", Vector2(1.15, 1.15), 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(judge_label, "scale", Vector2.ONE, 0.08)
	tw.parallel().tween_property(judge_label, "modulate:a", 0.0, 0.45).set_delay(0.22)


func _refresh_hud() -> void:
	score_label.text = str(_score)
	combo_label.text = ("%d COMBO" % _combo) if _combo >= 2 else ""


func _say(text: String, hold: float) -> void:
	msg_label.text = text
	var tw := create_tween()
	tw.tween_property(msg_label, "modulate:a", 1.0, 0.25)
	tw.tween_interval(hold)
	tw.tween_property(msg_label, "modulate:a", 0.0, 0.25)
	await tw.finished


func _play_sfx(player: AudioStreamPlayer, stream: AudioStream) -> void:
	player.stream = stream
	player.play()


func _fade_to(target: float, duration: float) -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", target, duration).set_trans(Tween.TRANS_SINE)
	await tw.finished


# ------------------------------------------------------------ 튜토리얼

## 시범 두 번 → 따라하기. 전부 실제 노트 시스템을 그대로 씁니다.
## 여기서 쓰는 시계는 음악이 아니라 _process 의 delta 입니다.
func _tutorial() -> void:
	var spb := 60.0 / Chart.BPM

	await _say(M_WATCH, 1.1)
	await _say(M_KEYS, 2.0)
	await _say(M_LOOK, 1.3)

	# --- 시범: 노트가 떨어지고, 맹돌이가 알아서 친다
	for round_i in 2:
		_begin_phase([[0.0, Chart.LEFT], [1.0, Chart.RIGHT], [2.0, Chart.UP]], spb)
		await _demo_phase()
		await get_tree().create_timer(0.5).timeout

	await _say(M_YOUR_TURN, 1.2)

	# --- 따라하기: 점수는 안 셉니다. 마지막 두 마디에서 동시 누르기를 미리 겪습니다.
	_begin_phase([[0.0, Chart.LEFT], [1.0, Chart.RIGHT], [2.0, Chart.UP],
		[4.0, Chart.LEFT], [5.0, Chart.RIGHT], [6.0, Chart.UP],
		[8.0, Chart.LEFT], [8.0, Chart.RIGHT], [10.0, Chart.UP]], spb)
	await _wait_phase()
	_score = 0
	_combo = 0
	_best_combo = 0
	_hits = 0
	_total = 0
	_refresh_hud()


## 박 단위 목록을 초 단위 노트로 바꿔서 걸어 둡니다.
func _begin_phase(beats: Array, spb: float) -> void:
	_clear_notes()
	_time = 0.0
	_use_music_clock = false
	for b in beats:
		_pending.append({ "t": (float(b[0]) + 2.0) * spb, "lane": int(b[1]), "node": null, "done": false })
	_total += beats.size()
	_running = true


## 시범: 플레이어 대신 정확한 박에 우리가 쳐 줍니다.
func _demo_phase() -> void:
	while _has_live_notes():
		for n in _pending:
			if not n["done"] and _time >= n["t"]:
				_resolve(n, "GREAT")
		await get_tree().process_frame
	_running = false
	# 시범은 점수가 아닙니다
	_score = 0
	_combo = 0
	_hits = 0
	_total = 0
	_refresh_hud()


func _wait_phase() -> void:
	while _has_live_notes():
		await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout
	_running = false


func _has_live_notes() -> bool:
	for n in _pending:
		if not n["done"]:
			return true
	return false


func _clear_notes() -> void:
	for n in _pending:
		if n["node"] != null and is_instance_valid(n["node"]):
			n["node"].queue_free()
	_pending.clear()


func _countdown() -> void:
	_clear_notes()
	var spb := 60.0 / Chart.BPM
	for n in [3, 2, 1]:
		_show_judge(str(n), Color(1, 1, 1))
		_play_sfx(sfx, SFX_TICK)
		await get_tree().create_timer(spb * 2.0).timeout
	_show_judge("START!", Color(1.0, 0.85, 0.4))
	_play_sfx(sfx, SFX_GREAT)
	await get_tree().create_timer(spb).timeout


# ------------------------------------------------------------ 본편

func _start_song() -> void:
	_clear_notes()
	var spb := 60.0 / Chart.BPM
	for n in Chart.NOTES:
		_pending.append({ "t": float(n[0]) * spb, "lane": int(n[1]), "node": null, "done": false })
	_total = Chart.NOTES.size()
	_score = 0
	_combo = 0
	_best_combo = 0
	_hits = 0
	_refresh_hud()

	_time = 0.0
	_use_music_clock = true
	music.play()
	_running = true
	# 곡이 끝나거나 남은 노트가 다 없어지면 마무리합니다.
	# music.finished 하나만 믿지 않는 이유: wav 길이와 채보 길이가 몇 십 ms
	# 어긋나거나 재생이 중간에 끊겨도 게임이 멈춰 서면 안 됩니다.
	while music.playing and (_has_live_notes() or _time < Chart.LENGTH - 0.3):
		await get_tree().process_frame
	_running = false
	await _finish()


func _finish() -> void:
	_clear_notes()
	var rate := 0.0 if _total == 0 else float(_hits) / float(_total)
	await get_tree().create_timer(0.6).timeout
	await _say(M_RESULT % [_score, _best_combo, roundi(rate * 100.0)], 2.0)

	if rate >= 0.6:
		await _say(M_CLEAR, 2.0)
		GameState.unlock_photo("clover")
		GameState.unlock_photo("king_mengsoon")
		GameState.set_flag("minigame1_done", true)
	else:
		await _say(M_RETRY, 1.6)

	GameState.set_flag("minigame1_score", _score)
	await _fade_to(1.0, 0.9)
	get_tree().change_scene_to_file("res://scenes/levels/mengdol_house.tscn")
