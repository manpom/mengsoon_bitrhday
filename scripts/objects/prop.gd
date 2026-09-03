@tool
class_name Prop
extends Node2D
## 방 안의 물건 하나 (침대 · 책상 · 창문 · 옷장 · 문 ...)
##
## 물건 하나에 보통 세 가지가 붙습니다. 셋 다 인스펙터에서 숫자만 바꾸면 됩니다.
##   1. 그림      texture
##   2. 막는 부분  solid_size / solid_offset   (0,0) 이면 통과할 수 있음
##   3. 조사 범위  zone_size  / zone_offset    (0,0) 이면 조사할 수 없음
##
## [b]기준점 규칙[/b]
##   이 노드의 position 은 [b]그림의 아래쪽 한가운데(= 물건이 바닥에 닿는 지점)[/b]입니다.
##   Y-Sort 가 "아래에 있는 것을 앞에 그린다"로 정렬하기 때문에,
##   모든 물건의 기준점을 바닥으로 맞춰 두면 앞뒤 관계가 저절로 맞습니다.
##   solid_offset / zone_offset / marker_offset 은 전부 이 기준점에서 잰 값입니다.
##
## [b]@tool 이란[/b]
##   에디터에서도 스크립트를 돌리라는 표시입니다. 덕분에 텍스처를 지정하면
##   게임을 실행하지 않아도 에디터 화면에 그림이 바로 보입니다.
##   충돌·감지 노드는 게임을 실행할 때만 만듭니다.

## 조사했을 때 이야기가 앞으로 나가는 물건인가?
##   LOOK  = 하얀 느낌표. 그냥 둘러보는 것. 대사만 나옴.
##   STORY = 노란 느낌표. 이걸 조사하면 이야기가 진행됩니다.
##           앞으로 미니게임이 시작될 자리가 바로 여기입니다.
enum MarkerKind { LOOK, STORY }

## 노란 느낌표 물건을 조사했을 때. 미니게임을 여기에 연결하면 됩니다.
signal story_triggered(prop: Node)

const MARK_LOOK: Texture2D = preload("res://assets/sprites/ui/prompt.png")
const MARK_STORY: Texture2D = preload("res://assets/sprites/ui/prompt_story.png")

## 물건의 그림. 아래쪽 한가운데가 이 노드의 position 에 오도록 자동 배치됩니다.
@export var texture: Texture2D:
	set(value):
		texture = value
		if is_node_ready():
			_apply_texture()

## PNG 아래쪽에 들어 있는 "그림자용 여백"의 높이.
## tools/build_room.ps1 의 $SHADOW_PAD 과 같은 값이어야 합니다.
## 이 값 덕분에 그림자를 그려 넣어도 물건이 바닥에 닿는 지점은 그대로입니다.
@export var sprite_bottom_pad: int = 12

@export_group("느낌표")
@export var marker_kind: MarkerKind = MarkerKind.LOOK

@export_group("막는 범위")
## 플레이어가 통과하지 못하는 사각형 크기. (0,0) 이면 안 막습니다.
@export var solid_size: Vector2 = Vector2.ZERO
## 위 사각형의 중심 (기준점에서 잰 값). 보통 물건 발치만 막습니다.
@export var solid_offset: Vector2 = Vector2.ZERO

@export_group("조사 범위")
## 플레이어가 이 안에 들어오면 조사할 수 있습니다. (0,0) 이면 조사 불가.
@export var zone_size: Vector2 = Vector2.ZERO
## 위 사각형의 중심 (기준점에서 잰 값).
@export var zone_offset: Vector2 = Vector2.ZERO
## 화면을 [b]찍었을 때[/b] "이 물건을 찍었다"로 볼 사각형. (0,0) 이면 zone_size 를
## 그대로 씁니다. 텍스처 없는 물건(방 그림에 이미 그려진 가구)은 대개 이 값이
## 필요합니다 - zone_size/zone_offset 은 "다가가서 서는 바닥 위치"이고,
## 그림 속 물건은 벽 위쪽처럼 [b]다른 높이[/b]에 그려져 있을 수 있기 때문입니다.
## (예: 복싱 글러브는 벽에 걸려 있어서, 서는 자리는 바닥인데 찍는 자리는 그 위쪽입니다.)
@export var click_size: Vector2 = Vector2.ZERO
## 위 사각형의 중심 (기준점에서 잰 값).
@export var click_offset: Vector2 = Vector2.ZERO
## 조사했을 때 나올 대사. 한 줄이 대사창 한 번입니다.
@export_multiline var lines: Array[String] = []
## 조사할 수 있을 때 뜨는 말풍선의 위치 (기준점에서 잰 값).
@export var marker_offset: Vector2 = Vector2(0, -80)

var _sprite: Sprite2D
var _marker: Sprite2D
var _marker_tween: Tween


func _ready() -> void:
	_sprite = $Sprite2D
	_marker = $Marker
	_apply_texture()
	_marker.texture = MARK_STORY if marker_kind == MarkerKind.STORY else MARK_LOOK
	_marker.position = marker_offset
	_marker.visible = false

	# 여기부터는 실제로 게임이 돌 때만 필요한 것들입니다.
	if Engine.is_editor_hint():
		return
	if solid_size != Vector2.ZERO:
		_build_solid()
	if zone_size != Vector2.ZERO:
		_build_zone()


## 플레이어가 조사 버튼을 눌렀을 때 불립니다.
func interact() -> void:
	if not lines.is_empty():
		Dialogue.say(lines)
	if marker_kind == MarkerKind.STORY:
		story_triggered.emit(self)


## 화면을 찍어서 이 물건으로 걸어올 때, 어디에 서면 되는지.
## 조사 범위의 한가운데입니다.
func stand_point() -> Vector2:
	return global_position + zone_offset


## 화면의 이 지점을 찍었을 때 "이 물건을 찍은 것"으로 볼지.
##
## ★ 텍스처가 있으면 눈에 보이는 그림 영역을 그대로 씁니다.
##   텍스처가 없는 물건(방 그림에 이미 그려진 가구)은 눈에 보이는 그림 영역이라는
##   게 없으므로, click_size/click_offset (없으면 zone_size/zone_offset) 사각형을
##   대신 씁니다. 이 사각형이 없으면 [b]그 물건은 절대 찍을 수 없습니다[/b] -
##   "물건을 찍으면 걸어가서 조사한다"가 텍스처 없는 물건에도 통하려면 필수입니다.
func contains_point(world: Vector2) -> bool:
	if texture != null:
		if zone_size == Vector2.ZERO:
			return false
		var w: float = texture.get_width()
		var h: float = texture.get_height()
		var top_left := global_position + Vector2(-w * 0.5, -(h - sprite_bottom_pad))
		return Rect2(top_left, Vector2(w, h)).has_point(world)

	var csize: Vector2 = click_size if click_size != Vector2.ZERO else zone_size
	if csize == Vector2.ZERO:
		return false
	var coffset: Vector2 = click_offset if click_size != Vector2.ZERO else zone_offset
	var top_left2 := global_position + coffset - csize * 0.5
	return Rect2(top_left2, csize).has_point(world)


## 조사 가능 상태 표시 (말풍선 + 살짝 밝아짐).
func set_highlighted(on: bool) -> void:
	if _marker == null:
		return
	_marker.visible = on
	if _sprite:
		_sprite.modulate = Color(1.14, 1.11, 1.04) if on else Color.WHITE
	if _marker_tween:
		_marker_tween.kill()
	if not on:
		_marker.position = marker_offset
		return
	# 말풍선이 위아래로 살짝 떠다니게
	_marker.position = marker_offset
	_marker_tween = create_tween().set_loops()
	_marker_tween.tween_property(_marker, "position:y", marker_offset.y - 6.0, 0.5) \
		.set_trans(Tween.TRANS_SINE)
	_marker_tween.tween_property(_marker, "position:y", marker_offset.y, 0.5) \
		.set_trans(Tween.TRANS_SINE)


# ------------------------------------------------------------ 내부

func _apply_texture() -> void:
	if _sprite == null:
		return
	_sprite.texture = texture
	_sprite.visible = texture != null
	if texture != null:
		# 아래쪽 한가운데(단, 그림자 여백은 빼고)를 원점으로
		_sprite.offset = Vector2(-texture.get_width() * 0.5, -(texture.get_height() - sprite_bottom_pad))


func _build_solid() -> void:
	var shape := RectangleShape2D.new()
	shape.size = solid_size
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position = solid_offset
	var body := StaticBody2D.new()
	body.name = "Solid"
	body.collision_layer = 1     # 1번 레이어 = World
	body.collision_mask = 0
	body.add_child(collider)
	add_child(body)


func _build_zone() -> void:
	var shape := RectangleShape2D.new()
	shape.size = zone_size
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position = zone_offset
	var area := Area2D.new()
	area.name = "Zone"
	area.collision_layer = 8     # 4번 레이어 = Interactable
	area.collision_mask = 0
	area.monitoring = false      # 감지는 플레이어 쪽에서 합니다
	area.monitorable = true
	area.add_child(collider)
	add_child(area)
	# 화면을 찍었을 때 플레이어가 후보를 훑어보는 목록
	add_to_group("interactable")
