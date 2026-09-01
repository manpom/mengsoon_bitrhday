extends CanvasLayer
## 대화창 (Autoload 이름: [b]Dialogue[/b])
##
## [b]역할[/b]
##   화면 아래에 뜨는 말풍선 하나. 게임 전체에서 딱 하나만 존재하고,
##   어느 씬에서든 [code]Dialogue.say([...])[/code] 한 줄로 부를 수 있습니다.
##
## [b]쓰는 법[/b]
##   [codeblock]
##   Dialogue.say(["(으음...)", "(여기가... 어디지?)"])
##   await Dialogue.finished          # 대사가 다 끝날 때까지 기다림
##   [/codeblock]
##   말하는 사람 이름을 붙이고 싶으면 두 번째 인자를 줍니다.
##   [codeblock]
##   Dialogue.say(["안녕!"], "맹순이")
##   [/codeblock]
##
## [b]조작[/b]
##   Space / Enter / 마우스 왼쪽 클릭 = 다음으로.
##   글자가 찍히는 도중에 누르면 그 줄을 즉시 다 보여 줍니다(스킵).
##
## [b]다른 코드가 알아야 하는 것[/b]
##   [code]Dialogue.is_active[/code]    대사창이 떠 있는 동안 true → 이동 잠그기
##   [code]Dialogue.is_blocking()[/code] 위 + 닫힌 직후 잠깐 → 상호작용 잠그기
##   (닫는 그 클릭이 곧바로 다음 상호작용을 또 발동시키는 걸 막습니다)

## 마지막 줄까지 다 읽고 창이 닫히면 발생합니다.
signal finished

## 초당 몇 글자를 찍을지. 올리면 빨라집니다.
const CHARS_PER_SEC := 34.0
## 창이 닫힌 뒤 상호작용을 다시 받기까지의 여유 시간(초).
const CLOSE_COOLDOWN := 0.18

## 글자 소리를 이 간격보다 자주 내지는 않습니다 (너무 촘촘하면 시끄러움).
const BLIP_GAP := 0.055

@onready var box: Panel = $Box
@onready var text_label: RichTextLabel = $Box/Text
@onready var next_arrow: Label = $Box/Next
@onready var name_tag: Label = $Box/NameTag
@onready var blip: AudioStreamPlayer = $Blip

## 대사창이 떠 있는가.
var is_active := false

var _lines: PackedStringArray = []
var _index := 0
var _typing := false
var _revealed := 0.0
var _total := 0
var _cooldown := 0.0
var _shown := 0            # 지금까지 몇 글자가 나왔는지
var _since_blip := 0.0

# .tscn 에 적어 둔 원래 위치. 창을 아래에서 밀어 올리는 연출에 씁니다.
var _off_top := 0.0
var _off_bottom := 0.0

var _tween: Tween
var _arrow_tween: Tween


func _ready() -> void:
	_off_top = box.offset_top
	_off_bottom = box.offset_bottom
	box.visible = false
	box.modulate.a = 0.0
	next_arrow.modulate.a = 0.0
	name_tag.visible = false
	# 게임을 일시정지시켜도 대사창은 계속 돌아가야 합니다.
	process_mode = Node.PROCESS_MODE_ALWAYS


## 대사 여러 줄을 순서대로 보여 줍니다.
func say(lines: Array, speaker: String = "") -> void:
	if lines.is_empty():
		return
	_lines = PackedStringArray(lines)
	_index = 0
	_cooldown = 0.0
	_set_speaker(speaker)
	if not is_active:
		is_active = true
		_open()
	_start_line()


## 이동은 풀어도 되지만 상호작용은 아직 막아야 하는 구간까지 포함.
func is_blocking() -> bool:
	return is_active or _cooldown > 0.0


## 다음 줄로 (또는 찍히는 중이면 그 줄을 즉시 완성).
func advance() -> void:
	if not is_active:
		return
	if _typing:
		_complete_line()
		return
	_index += 1
	if _index >= _lines.size():
		_close()
	else:
		_start_line()


func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		advance()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown = maxf(_cooldown - delta, 0.0)
	if not _typing:
		return
	_since_blip += delta
	_revealed += CHARS_PER_SEC * delta
	text_label.visible_characters = int(_revealed)
	if int(_revealed) > _shown:
		_shown = int(_revealed)
		_blip_at(_shown - 1)
	if int(_revealed) >= _total:
		_complete_line()


## 방금 나온 글자에 맞춰 "톡" 소리를 냅니다.
## 공백·마침표는 건너뛰어서, 말이 끊기는 곳에서 소리도 같이 쉽니다.
func _blip_at(index: int) -> void:
	if _since_blip < BLIP_GAP or _index >= _lines.size():
		return
	var line: String = _lines[_index]
	if index < 0 or index >= line.length():
		return
	var ch := line[index]
	if ch == " " or ch == "." or ch == "," or ch == "(" or ch == ")":
		return
	_since_blip = 0.0
	blip.pitch_scale = randf_range(0.94, 1.09)
	blip.play()


# ---------------------------------------------------------------- 내부 동작

func _set_speaker(speaker: String) -> void:
	if speaker.is_empty():
		name_tag.visible = false
		return
	name_tag.text = speaker
	name_tag.visible = true
	# 이름표 폭을 글자 길이에 맞춰 줄입니다(Label 은 알아서 줄지 않습니다).
	name_tag.size = name_tag.get_combined_minimum_size()


func _start_line() -> void:
	var line: String = _lines[_index]
	text_label.text = line
	_total = text_label.get_total_character_count()
	if _total <= 0:
		_total = line.length()
	text_label.visible_characters = 0
	_revealed = 0.0
	_shown = 0
	_since_blip = BLIP_GAP
	_typing = true
	if _arrow_tween:
		_arrow_tween.kill()
	next_arrow.modulate.a = 0.0


func _complete_line() -> void:
	_typing = false
	text_label.visible_characters = -1    # -1 = 전부 보이기
	_blink_arrow()


func _blink_arrow() -> void:
	if _arrow_tween:
		_arrow_tween.kill()
	next_arrow.modulate.a = 1.0
	_arrow_tween = create_tween().set_loops()
	_arrow_tween.tween_property(next_arrow, "modulate:a", 0.25, 0.45).set_trans(Tween.TRANS_SINE)
	_arrow_tween.tween_property(next_arrow, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE)


func _open() -> void:
	box.visible = true
	box.modulate.a = 0.0
	# 12px 아래에서 시작해서 제자리로 밀어 올립니다.
	box.offset_top = _off_top + 12.0
	box.offset_bottom = _off_bottom + 12.0
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(box, "modulate:a", 1.0, 0.16)
	_tween.tween_property(box, "offset_top", _off_top, 0.20)
	_tween.tween_property(box, "offset_bottom", _off_bottom, 0.20)


func _close() -> void:
	is_active = false
	_typing = false
	_cooldown = CLOSE_COOLDOWN
	if _arrow_tween:
		_arrow_tween.kill()
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(box, "modulate:a", 0.0, 0.13)
	_tween.tween_property(box, "offset_top", _off_top + 8.0, 0.13)
	_tween.tween_property(box, "offset_bottom", _off_bottom + 8.0, 0.13)
	await _tween.finished
	box.visible = false
	box.offset_top = _off_top
	box.offset_bottom = _off_bottom
	name_tag.visible = false
	finished.emit()
