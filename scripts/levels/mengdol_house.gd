extends Node2D
## 맹돌이의 집 — 게임의 첫 장면
##
## [b]흐름[/b]
##   1. 까만 화면에서 시작 → 졸린 눈을 두 번 껌뻑이며 뜬다 (#1)
##   2. "(으음...)" "(여기가... 어디지?)"
##   3. 침대에서 내려온다 (카메라도 같이 뒤로 빠진다) (#2)
##   4. "(내 집인가...?)" "(왜 아무것도 기억이 나질 않지?)" "(주변을 둘러봐야겠어)"
##   5. 조작권을 넘겨준다. 이제 WASD 로 걷고 Space/클릭 으로 물건을 조사할 수 있다.
##
## [b]노드 구조[/b]
##   MengdolHouse (Node2D)      <- 이 스크립트
##     ├─ Floor                 <- 바닥에 깔리는 것들. 항상 캐릭터보다 뒤에 그려짐
##     │    (배경 · 러그 · 액자 · 창문 · 침대틀)
##     ├─ Props   ★Y-Sort 켜짐  <- 캐릭터와 앞뒤 관계가 생기는 것들
##     │    (이불 · 옷장 · 문 · 책상 · 의자 · 플레이어)
##     ├─ Walls                 <- 방 밖으로 못 나가게 막는 사각형 4개
##     ├─ UI  (CanvasLayer 5)   <- 조작 안내
##     └─ Fx  (CanvasLayer 20)  <- 암전용 검은 사각형 (대사창보다 위)
##
## [b]왜 침대틀은 Floor 에 있고 이불만 Props 에 있나?[/b]
##   Y-Sort 는 "아래에 있는 것을 앞에" 그립니다. 침대틀의 기준점(발치)은
##   맹돌이보다 아래에 있어서, 같이 정렬하면 침대가 맹돌이를 덮어 버립니다.
##   그래서 침대틀은 항상 뒤에 두고, "덮여야 하는" 이불만 Y-Sort 에 넣었습니다.
##   이불 기준점(y=296)이 자고 있는 맹돌이(y=262)보다 아래라서 이불이 앞에 그려지고,
##   침대에서 내려오면 맹돌이가 더 아래로 가므로 자동으로 앞에 서게 됩니다.

## 방의 크기(픽셀). 카메라가 이 밖의 빈 공간을 비추지 않게 막습니다.
@export var room_size: Vector2i = Vector2i(640, 330)

## 오프닝에서 맹돌이가 누워 있는 자리 (베개 위에 머리가 오도록 맞춰 둔 값)
const BED_POS := Vector2(88, 265)
## 침대에서 내려와 서는 자리
const WAKE_POS := Vector2(215, 292)

## #1 눈을 떴을 때
const LINES_WAKE := [
	"(으음...)",
	"(여기가... 어디지?)",
]
## #2 침대에서 내려온 뒤
const LINES_OUT_OF_BED := [
	"(내 집인가...?)",
	"(왜 아무것도 기억이 나질 않지?)",
	"(주변을 둘러봐야겠어)",
]

@onready var player: CharacterBody2D = $Props/Player
@onready var quilt: Sprite2D = $Props/Quilt
@onready var hint: Label = $UI/Hint
@onready var fade: ColorRect = $Fx/Fade

var _hint_tween: Tween


func _ready() -> void:
	_setup_camera()
	hint.modulate.a = 0.0
	player.interacted.connect(_on_player_interacted)

	# 노란 느낌표가 붙은 물건들을 한 군데에서 받아 둡니다.
	for node in get_tree().get_nodes_in_group("interactable"):
		var prop := node as Prop
		if prop != null and prop.marker_kind == Prop.MarkerKind.STORY:
			prop.story_triggered.connect(_on_story_triggered)

	if GameState.get_flag("intro_done"):
		# 이미 오프닝을 본 적이 있으면 (나중에 이 방으로 되돌아왔을 때)
		# 바로 조작할 수 있게 합니다.
		player.position = WAKE_POS
		fade.color.a = 0.0
		_begin_play()
	else:
		_play_intro()


## 카메라가 방 밖의 빈 공간을 비추지 않도록 경계를 정해 줍니다.
func _setup_camera() -> void:
	var camera: Camera2D = player.get_node("Camera2D")
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = room_size.x
	camera.limit_bottom = room_size.y
	camera.make_current()


# ------------------------------------------------------------ 오프닝

func _play_intro() -> void:
	var camera: Camera2D = player.get_node("Camera2D")
	player.control_enabled = false
	player.position = BED_POS
	# 잠에서 깰 때는 카메라가 침대 쪽으로 바짝 붙어 있다가 서서히 물러납니다.
	camera.zoom = Vector2(1.35, 1.35)
	# 위치를 순간이동시키는 동안에는 부드러운 따라오기를 꺼 둡니다.
	camera.position_smoothing_enabled = false
	camera.reset_smoothing()
	fade.color.a = 1.0

	await get_tree().create_timer(0.7).timeout

	# --- #1 눈을 뜬다: 졸린 눈을 두 번 껌뻑이고 나서 완전히 뜬다
	await _fade_to(0.55, 0.50)
	await _fade_to(1.00, 0.22)
	await _fade_to(0.30, 0.45)
	await _fade_to(0.85, 0.20)
	await _fade_to(0.00, 0.80)

	camera.position_smoothing_enabled = true
	await get_tree().create_timer(0.35).timeout

	Dialogue.say(LINES_WAKE)
	await Dialogue.finished
	await get_tree().create_timer(0.25).timeout

	# --- #2 침대에서 내려온다
	await _get_out_of_bed()

	Dialogue.say(LINES_OUT_OF_BED)
	await Dialogue.finished

	GameState.set_flag("intro_done", true)
	_begin_play()


## 검은 화면의 투명도를 target 까지 duration 초에 걸쳐 바꿉니다.
func _fade_to(target: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade, "color:a", target, duration).set_trans(Tween.TRANS_SINE)
	await tween.finished


## 침대에서 내려오는 연출. 몸이 옆으로 미끄러지듯 이동하면서 한 번 통 튑니다.
func _get_out_of_bed() -> void:
	var sprite: AnimatedSprite2D = player.body
	var camera: Camera2D = player.get_node("Camera2D")
	var base_offset: float = sprite.offset.y

	# 내려서는 반동 (위로 살짝 떴다가 착지)
	var hop := create_tween()
	hop.tween_property(sprite, "offset:y", base_offset - 8.0, 0.28) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	hop.tween_property(sprite, "offset:y", base_offset, 0.34) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	var move := create_tween().set_parallel(true)
	move.tween_property(player, "position", WAKE_POS, 0.75) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# 이불이 발치로 조금 밀려 내려갑니다.
	# (옆으로 밀면 침대 나무틀 밖으로 삐져나오므로 아래로만 움직입니다)
	move.tween_property(quilt, "position:y", quilt.position.y + 5.0, 0.6) \
		.set_trans(Tween.TRANS_SINE)
	# 카메라는 천천히 뒤로 빠지면서 방 전체를 보여 줍니다.
	move.tween_property(camera, "zoom", Vector2.ONE, 1.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await move.finished


# ------------------------------------------------------------ 조작 시작

func _begin_play() -> void:
	player.control_enabled = true
	_show_hint()


## 조작 안내를 잠깐 띄웠다가 스스로 사라지게 합니다.
func _show_hint() -> void:
	if _hint_tween:
		_hint_tween.kill()
	_hint_tween = create_tween()
	_hint_tween.tween_property(hint, "modulate:a", 1.0, 0.4)
	_hint_tween.tween_interval(8.0)
	_hint_tween.tween_property(hint, "modulate:a", 0.0, 0.8)


## ★ 노란 느낌표 물건을 조사했을 때 여기로 들어옵니다.
##
## 지금은 대사만 나오고 끝납니다. 미니게임이 만들어지면 여기서
##   get_tree().change_scene_to_file("res://scenes/minigames/xxx.tscn")
## 처럼 미니게임 씬으로 넘기고, 클리어하면 사진 2장을 해금한 뒤
## 이 방으로 돌아오게 하면 됩니다.
## (GameState.get_flag("intro_done") 덕분에 돌아와도 오프닝은 다시 안 나옵니다)
func _on_story_triggered(prop: Node) -> void:
	await Dialogue.finished
	GameState.set_flag("story_" + prop.name, true)


## 뭔가를 한 번이라도 조사했다면 안내는 할 일을 다 한 것이므로 먼저 지웁니다.
func _on_player_interacted(_prop: Node) -> void:
	if _hint_tween:
		_hint_tween.kill()
	_hint_tween = create_tween()
	_hint_tween.tween_property(hint, "modulate:a", 0.0, 0.4)
