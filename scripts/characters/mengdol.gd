extends CharacterBody2D
## 맹돌이 (플레이어)
##
## [b]노드 구조[/b]
##   Mengdol (CharacterBody2D)   <- 이 스크립트. "움직이고 벽에 걸리는 몸"
##     ├─ Shadow                 <- 발밑 그림자
##     ├─ Body (AnimatedSprite2D)<- 64x64 그림. 앞/뒤/옆 × 서기/걷기
##     ├─ CollisionShape2D       <- 실제 충돌 판정 (몸 전체가 아니라 발밑만!)
##     ├─ Interactor (Area2D)    <- 주변의 "조사할 수 있는 물건"을 감지
##     ├─ Step (AudioStreamPlayer)
##     ├─ TapMark                <- 찍은 자리에 잠깐 뜨는 동그라미 (top_level)
##     └─ Camera2D
##
## [b]조작 — 두 가지가 같이 됩니다[/b]
##   키보드 : WASD / 방향키로 이동, Space·Enter 로 눈앞의 물건 조사
##   포인터 : 화면을 찍으면 그리로 걸어감. 물건을 찍으면 그 앞까지 걸어가서
##            도착하는 순간 알아서 조사합니다. (아이폰 대응이 이쪽입니다)
##
## 아이폰 사파리에서는 Godot 이 터치를 마우스 클릭으로 바꿔서 보내 주기 때문에
## (프로젝트 설정 emulate_mouse_from_touch, 기본 켜짐) 마우스만 처리하면 됩니다.
##
## [b]control_enabled[/b]
##   컷신 동안에는 false 로 둡니다. false 면 _physics_process 자체가 꺼져서
##   move_and_slide() 가 아예 안 돌아갑니다. 그래서 오프닝에서 맹돌이가 침대
##   (=막힌 영역) 안에 서 있어도 물리에 밀려 튀어나오지 않습니다.

## 조사 버튼을 눌러 무언가를 실제로 조사했을 때.
signal interacted(prop: Node)

@export var speed: float = 92.0
@export var acceleration: float = 900.0
@export var friction: float = 1300.0

## 찍은 자리에 이만큼 가까워지면 "도착"으로 칩니다.
const ARRIVE_DIST := 6.0
## 벽에 막혀 제자리걸음만 하면 이만큼 뒤에 목적지를 포기합니다.
const STUCK_TIME := 0.4

@onready var body: AnimatedSprite2D = $Body
@onready var shadow: Sprite2D = $Shadow
@onready var interactor: Area2D = $Interactor
@onready var step_sfx: AudioStreamPlayer = $Step
@onready var tap_mark: Sprite2D = $TapMark
@onready var camera: Camera2D = $Camera2D

const STEP_A: AudioStream = preload("res://assets/audio/sfx/step1.wav")
const STEP_B: AudioStream = preload("res://assets/audio/sfx/step2.wav")

## 플레이어가 직접 조종할 수 있는 상태인가. 컷신 중에는 false.
var control_enabled: bool = false:
	set(value):
		control_enabled = value
		set_physics_process(value)
		set_process_unhandled_input(value)
		if not value:
			velocity = Vector2.ZERO
			_clear_target()
			_set_focus(null)

# 지금 조사하면 반응할 물건 (없으면 null)
var _focus: Node = null
# 찍어서 걸어가는 중일 때의 목적지
var _has_target := false
var _target_pos := Vector2.ZERO
var _target_prop: Node = null
var _stuck_time := 0.0
# 바라보는 방향: "down" 앞 / "up" 뒤 / "side" 옆
var _facing := "down"
var _step_flip := false
# 표정을 짓고 있는 동안에는 걷기/서기 그림으로 안 돌아갑니다
var _face := ""


func _ready() -> void:
	add_to_group("player")
	set_physics_process(false)
	set_process_unhandled_input(false)
	tap_mark.visible = false
	tap_mark.top_level = true          # 플레이어를 따라다니지 않고 찍은 자리에 머무름
	body.frame_changed.connect(_on_frame_changed)
	_play_anim("idle")


func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO

	# 대사창이 떠 있는 동안에는 입력을 아예 안 읽습니다.
	if not Dialogue.is_active:
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if direction != Vector2.ZERO:
			_clear_target()            # 키보드를 잡으면 찍어둔 목적지는 취소
		elif _has_target:
			direction = _steer_to_target(delta)

	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()

	_update_focus()
	_animate()


# ------------------------------------------------------------ 찍어서 이동

## 목적지 쪽 방향을 돌려줍니다. 도착했거나 벽에 막히면 목적지를 정리합니다.
func _steer_to_target(delta: float) -> Vector2:
	var to_target := _target_pos - global_position
	if to_target.length() <= ARRIVE_DIST:
		_arrive()
		return Vector2.ZERO

	# 벽 뒤를 찍었을 때 영원히 벽을 비비지 않도록
	if velocity.length() < 12.0:
		_stuck_time += delta
		if _stuck_time > STUCK_TIME:
			_arrive()
			return Vector2.ZERO
	else:
		_stuck_time = 0.0

	return to_target.normalized()


func _unhandled_input(event: InputEvent) -> void:
	if Dialogue.is_blocking():
		return

	# 키보드로 조사: 눈앞에 있는 물건에 바로 말을 겁니다.
	if event is InputEventKey and event.is_action_pressed("interact"):
		_try_interact()
		get_viewport().set_input_as_handled()
		return

	# 포인터(마우스/터치)로 찍기
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		# event.position 은 화면 좌표입니다. 카메라를 거꾸로 적용해서
		# "방 안의 어디"인지로 바꿉니다.
		var world: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * event.position
		_tap_at(world)
		get_viewport().set_input_as_handled()


func _tap_at(world: Vector2) -> void:
	var prop := _prop_at(world)
	if prop != null:
		_target_prop = prop
		_target_pos = prop.stand_point()
	else:
		_target_prop = null
		_target_pos = world
	_has_target = true
	_stuck_time = 0.0
	_show_tap_mark(_target_pos)

	# 이미 그 자리에 서 있었다면 곧바로 조사
	if global_position.distance_to(_target_pos) <= ARRIVE_DIST:
		_arrive()


## 찍은 지점에 걸쳐 있는 조사 가능한 물건 찾기 (가까운 것 우선)
func _prop_at(world: Vector2) -> Node:
	var best: Node = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("interactable"):
		if not node.has_method("contains_point") or not node.contains_point(world):
			continue
		var d: float = world.distance_squared_to(node.global_position)
		if d < best_distance:
			best_distance = d
			best = node
	return best


func _arrive() -> void:
	var prop := _target_prop
	_clear_target()
	if is_instance_valid(prop) and global_position.distance_to(prop.stand_point()) < 56.0:
		prop.interact()
		interacted.emit(prop)


func _clear_target() -> void:
	_has_target = false
	_target_prop = null
	_stuck_time = 0.0
	tap_mark.visible = false


func _show_tap_mark(world: Vector2) -> void:
	tap_mark.global_position = world
	tap_mark.visible = true
	tap_mark.modulate.a = 1.0
	tap_mark.scale = Vector2(0.6, 0.6)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(tap_mark, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(tap_mark, "modulate:a", 0.0, 0.55).set_delay(0.15)


# ------------------------------------------------------------ 조사

## 겹쳐 있는 물건 중 가장 가까운 것 하나를 골라 둡니다.
func _update_focus() -> void:
	var best: Node = null
	var best_distance := INF
	for area in interactor.get_overlapping_areas():
		var prop := area.get_parent()
		if prop == null or not prop.has_method("interact"):
			continue
		var d := global_position.distance_squared_to(prop.global_position)
		if d < best_distance:
			best_distance = d
			best = prop
	_set_focus(best)


func _set_focus(prop: Node) -> void:
	if prop == _focus:
		return
	if is_instance_valid(_focus) and _focus.has_method("set_highlighted"):
		_focus.set_highlighted(false)
	_focus = prop
	if is_instance_valid(_focus) and _focus.has_method("set_highlighted"):
		_focus.set_highlighted(true)


func _try_interact() -> void:
	if not is_instance_valid(_focus):
		return
	_clear_target()
	_focus.interact()
	interacted.emit(_focus)


# ------------------------------------------------------------ 겉모습 · 소리

## 그림 하나로 고정하기. 컷신에서 씁니다.
## 고정돼 있는 동안에는 걸어도 그림이 안 바뀝니다.
##   player.lock_anim("lie")   # 침대에 누운 그림
##   player.lock_anim("")      # 풀기 (다시 걷기/서기 그림으로)
func lock_anim(anim: String) -> void:
	_face = anim
	if anim.is_empty():
		_play_anim("idle")
	else:
		body.flip_h = false
		body.play(anim)


## 표정 짓기.
##   player.show_face("surprise")   # happy / surprise / sad / angry / sleepy / shy
##   player.show_face("")           # 원래 얼굴로
func show_face(face: String) -> void:
	lock_anim("" if face.is_empty() else "face_" + face)


## 속도를 보고 앞/뒤/옆 중 어느 그림을 쓸지 정합니다.
func _animate() -> void:
	if not _face.is_empty():
		return
	if velocity.length() > 8.0:
		if absf(velocity.x) > absf(velocity.y):
			_facing = "side"
			body.flip_h = velocity.x < 0.0
		else:
			_facing = "down" if velocity.y > 0.0 else "up"
			body.flip_h = false
		_play_anim("walk")
	else:
		_play_anim("idle")


func _play_anim(kind: String) -> void:
	var wanted := "%s_%s" % [kind, _facing]
	if body.animation != wanted or not body.is_playing():
		body.play(wanted)


## 걷기 그림이 "발을 딛는 프레임"으로 넘어갈 때마다 발소리를 냅니다.
func _on_frame_changed() -> void:
	if not body.animation.begins_with("walk"):
		return
	if body.frame != 0 and body.frame != 2:
		return
	_step_flip = not _step_flip
	step_sfx.stream = STEP_A if _step_flip else STEP_B
	step_sfx.pitch_scale = randf_range(0.94, 1.07)
	step_sfx.play()
