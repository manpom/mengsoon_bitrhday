extends CharacterBody2D
## 여자친구 맹순이 (NPC)
##
## [b]역할[/b]
##   지금은 움직이지 않고 그 자리에 서 있는 NPC입니다.
##   키 153cm, 통통하고 동글동글한 체형이라 남자친구보다 스프라이트가 작습니다.
##   남자친구가 가까이 오면 머리 위에 하트가 뜹니다.
##
## [b]노드 구조[/b]
##   Girlfriend (CharacterBody2D) <- 이 스크립트. 지금은 안 움직이지만
##     │                             나중에 같이 걷게 만들 수 있게 몸체로 둡니다.
##     ├─ Sprite2D                <- 그림
##     ├─ CollisionShape2D        <- 몸통 판정 (남자친구가 통과하지 못함)
##     ├─ Emote                   <- 머리 위 하트 아이콘 (평소엔 숨김)
##     └─ ProximityArea (Area2D)  <- "가까이 왔는지" 감지하는 투명한 원
##          └─ CollisionShape2D
##
## Area2D 는 부딪히지는 않고 "겹쳤는지"만 알려주는 노드입니다.
## 겹치기 시작하면 body_entered, 벗어나면 body_exited 신호(signal)를 보냅니다.

## 제자리에서 살짝 숨 쉬는 연출 속도
@export var breath_speed: float = 2.2

@onready var sprite: Sprite2D = $Sprite2D
@onready var emote: Sprite2D = $Emote
@onready var proximity_area: Area2D = $ProximityArea

var _breath_time: float = 0.0
var _base_offset: Vector2
var _emote_base_y: float
var _player_is_near: bool = false


func _ready() -> void:
	_base_offset = sprite.offset
	_emote_base_y = emote.position.y
	emote.visible = false

	# 신호 연결: "가까이 오면 _on_body_entered 를 실행해줘"
	# 에디터의 [노드] 탭에서 마우스로 연결할 수도 있지만,
	# 코드로 연결해 두면 어디서 무슨 일이 일어나는지 한눈에 보입니다.
	proximity_area.body_entered.connect(_on_body_entered)
	proximity_area.body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	_breath_time += delta * breath_speed
	# 아주 작게 위아래로 움직여서 "살아있는" 느낌을 냅니다.
	sprite.offset = _base_offset + Vector2(0.0, sin(_breath_time) * 0.5)

	if emote.visible:
		# 하트는 조금 더 크게 두둥실
		emote.position.y = _emote_base_y + sin(_breath_time * 1.6) * 3.0


func _on_body_entered(body: Node2D) -> void:
	# 벽이나 다른 물체가 아니라 플레이어일 때만 반응합니다.
	if not body.is_in_group("player"):
		return
	_player_is_near = true
	emote.visible = true
	# TODO(다음 단계): 여기서 대화창 / 미니게임 시작 UI를 띄우게 됩니다.


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_is_near = false
	emote.visible = false


## 나중에 스토리 시스템에서 "지금 말을 걸 수 있는 상태인가?" 물어볼 때 씁니다.
func is_player_near() -> bool:
	return _player_is_near
