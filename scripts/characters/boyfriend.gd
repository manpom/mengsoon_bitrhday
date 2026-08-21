extends CharacterBody2D
## 남자친구 맹꽁이 (플레이어)
##
## [b]역할[/b]
##   방향키 / WASD 입력을 받아 위·아래·좌·우로 움직이는 캐릭터입니다.
##   키 181cm, 듬직한 체격이라 여자친구보다 스프라이트가 큽니다.
##
## [b]노드 구조[/b]
##   Boyfriend (CharacterBody2D)  <- 이 스크립트. "움직이고 부딪히는 몸"
##     ├─ Sprite2D                <- 눈에 보이는 그림
##     ├─ CollisionShape2D        <- 실제로 벽에 걸리는 판정(발밑 사각형)
##     └─ Camera2D                <- 이 캐릭터를 따라다니는 카메라
##
## CharacterBody2D 는 "직접 코드로 움직이는 물리 몸체"입니다.
## velocity(속도)를 정해주고 move_and_slide() 를 부르면
## Godot 이 벽에 부딪힌 부분을 알아서 미끄러뜨려 줍니다.

## 최고 이동 속도 (픽셀/초). 에디터 인스펙터에서 바로 조절할 수 있습니다.
@export var speed: float = 130.0
## 가속 (얼마나 빨리 최고 속도에 도달하는지)
@export var acceleration: float = 900.0
## 감속 (키를 뗐을 때 얼마나 빨리 멈추는지)
@export var friction: float = 1200.0

## @onready = 씬의 자식 노드가 모두 준비된 뒤에 값을 채워라
@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D

## 걸을 때 위아래로 통통 튀는 연출용 타이머
var _bob_time: float = 0.0
## 스프라이트의 원래 위치(offset). 통통 튄 뒤 여기로 돌아옵니다.
var _base_offset: Vector2


func _ready() -> void:
	_base_offset = sprite.offset


## _physics_process 는 물리 계산용 함수로, 초당 60번 일정하게 호출됩니다.
## 이동/충돌 처리는 _process 가 아니라 여기에 쓰는 것이 정석입니다.
func _physics_process(delta: float) -> void:
	# Input.get_vector 는 네 개의 입력을 묶어서 -1~1 범위의 방향 벡터로 만들어 줍니다.
	# (대각선으로 눌러도 속도가 빨라지지 않도록 자동으로 정규화해 줍니다)
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	# velocity 값을 실제 이동으로 바꿔주는 한 줄. 벽 충돌 처리까지 포함됩니다.
	move_and_slide()

	_update_appearance(delta)


## 이동 상태에 맞춰 스프라이트를 좌우 반전하고 통통 튀게 만듭니다.
func _update_appearance(delta: float) -> void:
	# 좌우로 움직일 때만 바라보는 방향을 바꿉니다.
	if absf(velocity.x) > 5.0:
		sprite.flip_h = velocity.x < 0.0

	if velocity.length() > 5.0:
		_bob_time += delta * 12.0
		# sin 값의 절댓값 -> 0에서 1 사이를 통통 튀는 모양으로 오갑니다.
		sprite.offset = _base_offset + Vector2(0.0, -absf(sin(_bob_time)) * 1.5)
	else:
		_bob_time = 0.0
		sprite.offset = sprite.offset.lerp(_base_offset, 12.0 * delta)
