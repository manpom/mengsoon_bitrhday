extends Node2D
## 프로토타입 방 (레벨 씬의 루트)
##
## [b]역할[/b]
##   배경 · 벽 · 두 캐릭터를 한자리에 모아 놓은 "무대"입니다.
##   게임을 실행하면 project.godot 의 run/main_scene 설정에 따라
##   이 씬이 가장 먼저 열립니다.
##
## [b]노드 구조[/b]
##   PrototypeRoom (Node2D)   <- 이 스크립트
##     ├─ Background          <- 벽 / 바닥 / 러그 / 액자 (그림만, 충돌 없음)
##     ├─ Walls               <- 화면 밖으로 못 나가게 막는 StaticBody2D 4개
##     ├─ Characters          <- Y-Sort 켜짐. 아래에 있는 캐릭터가 앞에 그려짐
##     │    ├─ Girlfriend     <- girlfriend.tscn 을 불러온 것(인스턴스)
##     │    └─ Boyfriend      <- boyfriend.tscn 을 불러온 것(인스턴스)
##     └─ UI (CanvasLayer)    <- 카메라와 무관하게 화면에 고정되는 층
##
## 나중에 미니게임을 추가할 때는
##   scenes/minigames/xxx.tscn 을 만들고 여기서 불러오거나,
##   장면 전체를 get_tree().change_scene_to_file() 로 바꾸면 됩니다.

## 이 방의 크기(픽셀). 카메라가 이 범위 밖의 빈 공간을 비추지 않게 막습니다.
@export var room_size: Vector2i = Vector2i(1280, 720)

@onready var boyfriend: CharacterBody2D = $Characters/Boyfriend
@onready var girlfriend: CharacterBody2D = $Characters/Girlfriend


func _ready() -> void:
	# 플레이어를 "player" 그룹에 넣어 둡니다.
	# 그러면 맹순이의 감지 영역이 "이게 플레이어구나" 하고 알아볼 수 있습니다.
	boyfriend.add_to_group("player")

	_setup_camera()
	_report_heights()


## 카메라가 방 밖을 비추지 않도록 경계를 정해 줍니다.
func _setup_camera() -> void:
	var camera: Camera2D = boyfriend.get_node("Camera2D")
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = room_size.x
	camera.limit_bottom = room_size.y
	camera.make_current()


## 두 캐릭터의 화면상 키를 출력해서 비율이 맞는지 확인합니다.
## (에디터 아래쪽 [출력] 패널에 찍힙니다)
func _report_heights() -> void:
	var bf_h: float = _visual_height(boyfriend)
	var gf_h: float = _visual_height(girlfriend)
	print("[키 비교] 남자친구 %.0fpx / 여자친구 %.0fpx  ->  비율 %.3f (실제 153/181 = 0.845)"
		% [bf_h, gf_h, gf_h / bf_h])

## 스프라이트가 화면에서 실제로 차지하는 세로 픽셀 수를 구합니다.
## 32x32 그림 안에서 위쪽 투명한 여백은 빼고 재야 정확합니다.
func _visual_height(character: Node2D) -> float:
	var sprite: Sprite2D = character.get_node("Sprite2D")
	var image: Image = sprite.texture.get_image()
	var used: Rect2i = image.get_used_rect()   # 투명하지 않은 픽셀들의 범위
	return used.size.y * sprite.scale.y
