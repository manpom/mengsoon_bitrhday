extends Node2D
## 미니게임 1 「원 투 뿡!」 — 추억 1 (원투 방구 사건)
##
## [b]지금 들어 있는 것: 도입 컷신까지.[/b]
##   페이드인 → 대화 → 맹돌이가 원·투 시범 → 맹순이가 따라하다 뿡 →
##   맹순이 얼굴 빨개짐 → 맹돌이 폭소 → 페이드아웃
## 그 다음에 붙을 리듬 게임은 아래 _start_rhythm_game() 자리입니다.
##
## [b]리듬 게임 설계 방향 (닌텐도 리듬천국 방식)[/b]
##   - 떨어지는 노트 레인을 만들지 않습니다. 소리와 캐릭터 동작이 곧 박자입니다.
##   - 입력은 탭 하나. (아이폰에서 손가락 하나로 되어야 하니까)
##   - 콜 앤 리스폰스: 맹돌이가 "원, 투!" 하면 플레이어가 "원, 투, 뿡!" 으로 답합니다.
##     실제 사건이 원래 이 구조라서 소재와 장르가 그대로 포개집니다.
##
## [b]화면[/b]
##   미니게임 화면은 카메라가 움직이지 않습니다. 배경(640x270)을 x=-80 에 놓아
##   기준 화면(480x270) 가운데에 욕실이 오게 하고, 남는 좌우는 화면이 더 넓은
##   기기에서 벽 타일이 계속 이어져 보이도록 쓰입니다.

# ============================================================
#  ★ 대사는 전부 여기 있습니다. 고칠 땐 여기만 보면 됩니다.
# ------------------------------------------------------------
#  대괄호 [ ] 안의 문자열 하나 = 대사창 한 번입니다.
#  한 배열에 여러 줄을 넣으면 같은 사람이 이어서 말합니다.
#      const L_어쩌고 := ["첫 번째 창", "두 번째 창"]
#  쉼표와 따옴표만 안 빠뜨리면 됩니다.
# ============================================================

## 대사창 왼쪽 위에 뜨는 이름표
const NAME_D := "맹돌이"
const NAME_S := "맹순이"

const L_D_ASK := ["...어때, 이제 복싱에 대해 조금 알겠어?"]
const L_S_ASK := ["조금 어려워. 직접 보여줄 수 있어?"]
const L_D_SURE := ["당연하지. 잘 보고 따라해봐."]
const L_D_YOUR_TURN := ["따라해봐."]
const L_D_LAUGH := ["푸하하하하!", "야, 그거 원 투 뿡이잖아!"]
const L_S_DONT_LOOK := ["...슬리퍼 끄는 소리야!"]

## 주먹을 지를 때 화면 가운데에 크게 뜨는 글자 (대사창이 아닙니다)
const SHOUT_ONE := "원!"
const SHOUT_TWO := "투!"
const SHOUT_BBOONG := "뿡!"
const SHOUT_WHAT := "뿡?!"

# 두 사람이 서는 자리
const MENGDOL_POS := Vector2(300, 214)
const MENGSOON_POS := Vector2(196, 214)

## 방귀가 나오는 자리 (맹순이 기준). 구름 그림의 꼬리 끝이 여기 붙습니다.
const BBOONG_FROM := Vector2(-16, -6)

@onready var mengdol: Sprite2D = $Cast/Mengdol
@onready var mengsoon: Sprite2D = $Cast/Mengsoon
@onready var fart: Sprite2D = $Cast/Fart
@onready var sparkle: Sprite2D = $Cast/Sparkle
@onready var shout: Label = $Ui/Shout
@onready var fade: ColorRect = $Fx/Fade
@onready var sfx: AudioStreamPlayer = $Sfx

# 나체 포즈들. 컷신에서 이 그림들을 갈아 끼우는 것이 곧 연기입니다.
const POSE := {
	"d_stand": preload("res://assets/sprites/characters/mengdol/mengdol_nude_stand.png"),
	"d_guard": preload("res://assets/sprites/characters/mengdol/mengdol_nude_guard.png"),
	"d_punch1": preload("res://assets/sprites/characters/mengdol/mengdol_nude_punch1.png"),
	"d_punch2": preload("res://assets/sprites/characters/mengdol/mengdol_nude_punch2.png"),
	"d_laugh": preload("res://assets/sprites/characters/mengdol/mengdol_nude_laugh.png"),
	"s_stand": preload("res://assets/sprites/characters/mengsoon/mengsoon_nude_stand.png"),
	"s_guard": preload("res://assets/sprites/characters/mengsoon/mengsoon_nude_guard.png"),
	"s_punch1": preload("res://assets/sprites/characters/mengsoon/mengsoon_nude_punch1.png"),
	"s_punch2": preload("res://assets/sprites/characters/mengsoon/mengsoon_nude_punch2.png"),
	"s_surprise": preload("res://assets/sprites/characters/mengsoon/mengsoon_nude_surprise.png"),
	"s_shy": preload("res://assets/sprites/characters/mengsoon/mengsoon_nude_shy.png"),
}
const FART_PUFF := [
	preload("res://assets/sprites/stages/fart1.png"),
	preload("res://assets/sprites/stages/fart2.png"),
	preload("res://assets/sprites/stages/fart3.png"),
]
const SFX_TICK := preload("res://assets/audio/sfx/tick.wav")
const SFX_TOCK := preload("res://assets/audio/sfx/tock.wav")
const SFX_BBOONG := preload("res://assets/audio/sfx/bboong.wav")
const SFX_DING := preload("res://assets/audio/sfx/ding.wav")


func _ready() -> void:
	fade.color.a = 1.0
	fart.visible = false
	sparkle.visible = false
	shout.modulate.a = 0.0
	mengdol.texture = POSE["d_stand"]
	mengsoon.texture = POSE["s_stand"]
	mengdol.position = MENGDOL_POS
	mengsoon.position = MENGSOON_POS
	_play_intro()


# ------------------------------------------------------------ 도입 컷신

func _play_intro() -> void:
	await get_tree().create_timer(0.3).timeout
	await _fade_to(0.0, 0.9)
	await get_tree().create_timer(0.4).timeout

	Dialogue.say(L_D_ASK, NAME_D)
	await Dialogue.finished
	Dialogue.say(L_S_ASK, NAME_S)
	await Dialogue.finished
	Dialogue.say(L_D_SURE, NAME_D)
	await Dialogue.finished

	# --- 맹돌이의 시범
	mengdol.texture = POSE["d_guard"]
	await get_tree().create_timer(0.6).timeout
	await _jab(mengdol, "d_punch1", SHOUT_ONE, SFX_TICK)
	await _jab(mengdol, "d_punch2", SHOUT_TWO, SFX_TOCK)
	mengdol.texture = POSE["d_stand"]
	await get_tree().create_timer(0.3).timeout

	Dialogue.say(L_D_YOUR_TURN, NAME_D)
	await Dialogue.finished

	# --- 맹순이가 따라한다
	mengsoon.texture = POSE["s_guard"]
	await get_tree().create_timer(0.7).timeout
	await _jab(mengsoon, "s_punch1", SHOUT_ONE, SFX_TICK)
	await _jab(mengsoon, "s_punch2", SHOUT_TWO, SFX_TOCK)

	# --- 그리고 뿡
	await _bboong()

	# --- 맹순이는 새빨개지고, 맹돌이는 주저앉아 웃는다
	mengsoon.texture = POSE["s_surprise"]
	_shout(SHOUT_WHAT, Color(1, 1, 1))
	await get_tree().create_timer(0.7).timeout
	mengsoon.texture = POSE["s_shy"]
	await get_tree().create_timer(0.5).timeout

	mengdol.texture = POSE["d_laugh"]
	_pop_sparkle()
	sfx.stream = SFX_DING
	sfx.play()
	_shake(mengdol, 1.4)
	await get_tree().create_timer(1.6).timeout

	Dialogue.say(L_D_LAUGH, NAME_D)
	await Dialogue.finished
	Dialogue.say(L_S_DONT_LOOK, NAME_S)
	await Dialogue.finished

	await _fade_to(1.0, 0.9)
	await get_tree().create_timer(0.4).timeout
	_start_rhythm_game()


## 주먹 한 번: 포즈를 바꾸고, 글자를 띄우고, 소리를 낸다.
func _jab(who: Sprite2D, pose_key: String, text: String, sound: AudioStream) -> void:
	who.texture = POSE[pose_key]
	sfx.stream = sound
	sfx.play()
	_shout(text, Color(1, 0.95, 0.8))
	# 주먹을 뻗을 때 몸이 살짝 앞으로 나갔다 돌아온다
	var punch := create_tween()
	punch.tween_property(who, "position:y", who.position.y - 3.0, 0.07)
	punch.tween_property(who, "position:y", who.position.y, 0.13)
	await get_tree().create_timer(0.55).timeout


## 방귀. 보라색 구름이 뒤에서 세 단계로 퍼집니다.
##
## ★ 구름 그림은 꼬리 끝이 항상 오른쪽 아래에서 (6, 6) 픽셀에 있습니다.
##   offset 을 (6 - w/2, 6 - h/2) 로 잡으면 노드 위치 = 꼬리 끝이 되어,
##   구름이 커져도 똥꼬에서 안 떨어집니다.
func _bboong() -> void:
	sfx.stream = SFX_BBOONG
	sfx.play()
	_shout(SHOUT_BBOONG, Color(0.85, 0.7, 1.0))
	fart.position = mengsoon.position + BBOONG_FROM
	fart.visible = true
	fart.modulate.a = 1.0
	for i in FART_PUFF.size():
		fart.texture = FART_PUFF[i]
		var s: Vector2 = FART_PUFF[i].get_size()
		fart.offset = Vector2(6.0 - s.x * 0.5, 6.0 - s.y * 0.5)
		await get_tree().create_timer(0.16).timeout
	var out := create_tween()
	out.tween_property(fart, "modulate:a", 0.0, 0.7)
	await out.finished
	fart.visible = false


# ------------------------------------------------------------ 연출 도구

func _shout(text: String, color: Color) -> void:
	shout.text = text
	shout.modulate = color
	shout.modulate.a = 1.0
	shout.scale = Vector2(0.6, 0.6)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(shout, "scale", Vector2.ONE, 0.16) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(shout, "modulate:a", 0.0, 0.5).set_delay(0.3)


func _pop_sparkle() -> void:
	sparkle.position = mengdol.position + Vector2(0, -70)
	sparkle.visible = true
	sparkle.scale = Vector2(0.4, 0.4)
	sparkle.modulate.a = 1.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(sparkle, "scale", Vector2(1.6, 1.6), 0.5)
	tw.tween_property(sparkle, "modulate:a", 0.0, 0.5)


## 웃느라 몸이 들썩이는 연출
func _shake(who: Sprite2D, seconds: float) -> void:
	var home := who.position
	var tw := create_tween().set_loops(int(seconds / 0.16))
	tw.tween_property(who, "position:y", home.y - 3.0, 0.08)
	tw.tween_property(who, "position:y", home.y, 0.08)


func _fade_to(target: float, duration: float) -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", target, duration).set_trans(Tween.TRANS_SINE)
	await tw.finished


# ------------------------------------------------------------ 다음 단계

## 도입 컷신이 끝나면 리듬 파트로 넘어갑니다.
## 컷신은 암전으로 끝나고 리듬 파트는 암전에서 시작하므로 그대로 이어집니다.
func _start_rhythm_game() -> void:
	get_tree().change_scene_to_file("res://scenes/minigames/one_two_rhythm.tscn")
