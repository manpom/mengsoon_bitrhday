extends Node2D

const LANE_LEFT := 0
const LANE_CENTER := 1
const LANE_RIGHT := 2
const PATTERN := [LANE_LEFT, LANE_RIGHT, LANE_CENTER, LANE_LEFT, LANE_RIGHT, LANE_CENTER]
const NAMES := ["원", "뿡", "투"]

@onready var rings: Array[Sprite2D] = [$Rings/Left, $Rings/Center, $Rings/Right]
@onready var cue: Label = $UI/Cue
@onready var progress: Label = $UI/Progress
@onready var hint: Label = $UI/Hint
@onready var hit: AudioStreamPlayer = $Hit

var index := 0
var accepting := true

func _ready() -> void:
	_update_round()

func _unhandled_input(event: InputEvent) -> void:
	if not accepting:
		if event is InputEventMouseButton and event.pressed:
			get_tree().change_scene_to_file("res://scenes/room.tscn")
		return
	var lane: int = -1
	if event.is_action_pressed("lane_left"):
		lane = LANE_LEFT
	elif event.is_action_pressed("lane_right"):
		lane = LANE_RIGHT
	elif event.is_action_pressed("lane_center"):
		lane = LANE_CENTER
	elif event is InputEventMouseButton and event.pressed:
		var x: float = event.position.x
		lane = LANE_LEFT if x < 320.0 else (LANE_RIGHT if x > 640.0 else LANE_CENTER)
	if lane >= 0:
		_attempt(lane)
		get_viewport().set_input_as_handled()

func _attempt(lane: int) -> void:
	if lane != PATTERN[index]:
		cue.text = "다시 박자를 맞춰보자"
		return
	rings[lane].scale = Vector2(1.25, 1.25)
	var tw := create_tween()
	tw.tween_property(rings[lane], "scale", Vector2.ONE, 0.18)
	hit.play()
	index += 1
	if index >= PATTERN.size():
		accepting = false
		GameState.minigame1_done = true
		cue.text = "첫 번째 기억을 되찾았다!"
		hint.text = "화면을 탭해 방으로 돌아가기"
		progress.text = "COMPLETE"
		return
	_update_round()

func _update_round() -> void:
	for ring in rings:
		ring.modulate = Color(1, 1, 1, 0.42)
	var lane: int = PATTERN[index]
	rings[lane].modulate = Color(1, 1, 1, 1)
	cue.text = NAMES[lane] + "!"
	progress.text = "%d / %d" % [index + 1, PATTERN.size()]
