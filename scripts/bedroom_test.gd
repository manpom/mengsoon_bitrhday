extends Node2D

const DialogueBoxScene := preload("res://scripts/dialogue_box.gd")

enum PlayerState { SLEEPING, WAKING, PLAYING }

const SLEEP_FRAME_PATH := "res://assets/characters/runtime/maengdol/bed/maengdol_sleep_%d.png"
const WALK_FRAME_PATH := "res://assets/characters/runtime/maengdol/walk/maengdol_walk_%s_%d.png"
const WALK_DIRECTIONS := [&"s", &"se", &"e", &"ne", &"n", &"nw", &"w", &"sw"]
const WALK_VISUAL_SOURCES := {
	&"s": { "animation": &"walk_s", "flip_h": false },
	&"se": { "animation": &"walk_se", "flip_h": false },
	&"e": { "animation": &"walk_e", "flip_h": false },
	&"ne": { "animation": &"walk_ne", "flip_h": false },
	&"n": { "animation": &"walk_n", "flip_h": false },
	# The authored west-facing diagonals point toward the wrong screen side.
	# Mirror the matching east-facing source instead; this keeps stride timing and
	# the visual heading symmetric without touching CharacterBody2D movement.
	&"nw": { "animation": &"walk_ne", "flip_h": true },
	&"w": { "animation": &"walk_e", "flip_h": true },
	&"sw": { "animation": &"walk_se", "flip_h": true },
}

@export_category("Game Flow")
@export_range(0.0, 10.0, 0.1) var sleep_seconds := 1.8
@export_range(20.0, 800.0, 5.0) var walk_speed := 260.0
@export var movement_bounds_min := Vector2(105.0, 485.0)
@export var movement_bounds_max := Vector2(1815.0, 950.0)
@export_range(0.0, 2.0, 0.05) var wake_fade_to_black_duration := 0.4
@export_range(0.0, 2.0, 0.05) var wake_fade_from_black_duration := 0.4
@export_range(80.0, 400.0, 5.0) var boxing_glove_interaction_distance := 220.0

@export_category("Bed Animation Fine Tuning")
@export var sleep_frame_offsets: Array[Vector2] = [
	Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO,
]

@export_category("Walk Animation Fine Tuning")
# Matches every direction to the same foot baseline. The runtime frames were
# center-aligned during slicing, so diagonals otherwise appear about 45 px high.
# Order: s, se, e, ne, n, nw, w, sw.
@export var walk_direction_offsets: Array[Vector2] = [
	Vector2(0.0, 0.0), Vector2(0.0, 50.0), Vector2(0.0, 4.0), Vector2(0.0, 46.0),
	Vector2(0.0, -6.0), Vector2(0.0, 46.0), Vector2(0.0, 4.0), Vector2(0.0, 50.0),
]

@onready var bed: Node2D = %Bed
@onready var sleep_anchor: Marker2D = %MaengdolSleepAnchor
@onready var exit_anchor: Marker2D = %MaengdolExitAnchor
@onready var player: CharacterBody2D = %Maengdol
@onready var player_collision: CollisionShape2D = %MaengdolCollision
@onready var bed_pose_visual: Node2D = %BedPoseVisual
@onready var bed_pose_preview: Sprite2D = %BedPosePreview
@onready var bed_pose_sprite: AnimatedSprite2D = %BedPoseAnimation
@onready var walk_visual: Node2D = %WalkVisual
@onready var walk_preview: Sprite2D = %WalkPreview
@onready var walk_sprite: AnimatedSprite2D = %WalkAnimation
@onready var boxing_glove_area: Area2D = %BoxingGloveInteractionArea

var player_state := PlayerState.SLEEPING
var touch_pressed := {"left": false, "right": false, "up": false, "down": false}
var status_label: Label
var fade_overlay: ColorRect
var last_walk_direction: StringName = &"s"
var walk_is_moving := false
var dialogue_box: DialogueBox
var dialogue_active := false


func _ready() -> void:
	# Preview sprites stay visible in the editor so the visual nodes can be
	# arranged directly. Runtime animations replace them when play begins.
	bed_pose_preview.hide()
	walk_preview.hide()
	var frames := _build_all_player_frames()
	bed_pose_sprite.sprite_frames = frames
	walk_sprite.sprite_frames = frames
	bed_pose_sprite.animation = &"sleep"
	bed_pose_sprite.play()
	walk_sprite.animation = &"walk_s"
	walk_sprite.frame = 0
	walk_sprite.pause()

	player.global_position = sleep_anchor.global_position
	bed_pose_visual.show()
	walk_visual.hide()
	bed_pose_sprite.frame_changed.connect(_apply_bed_frame_offset)
	_apply_bed_frame_offset()
	_build_touch_controls()
	_build_dialogue_box()

	var args := OS.get_cmdline_user_args()
	if "--capture-sleep" in args:
		await get_tree().create_timer(0.6).timeout
		await _save_capture("bedroom_sleep_corner.png")
		get_tree().quit()
	elif "--capture-awake" in args:
		_start_wake_sequence()
		await get_tree().create_timer(2.4).timeout
		await _save_capture("bedroom_awake_corner.png")
		get_tree().quit()
	elif "--smoke-test" in args:
		_start_wake_sequence()
		await get_tree().create_timer(2.2).timeout
		assert(player_state == PlayerState.PLAYING and not dialogue_active, "Player did not reach PLAYING state")
		_assert_walk_visual_mapping()
		var start_x := player.position.x
		touch_pressed["right"] = true
		await get_tree().create_timer(0.35).timeout
		touch_pressed["right"] = false
		assert(player.position.x > start_x + 20.0, "Player did not move right")
		assert(walk_sprite.animation == &"walk_e", "8-direction animation did not switch to east")
		print("SMOKE_TEST_PASS: sleep -> fade transition -> standing exit position -> walk_e")
		get_tree().quit()
	elif "--dialogue-test" in args:
		_start_wake_sequence()
		await get_tree().create_timer(1.1).timeout
		assert(dialogue_active and dialogue_box.body_label.text == "으음... 여기가 어디지?", "Wake dialogue did not begin")
		for line in ["왜 아무 기억도 나질 않지?", "주변을 둘러봐야겠어"]:
			dialogue_box._unhandled_input(_interact_event())
			assert(dialogue_box.body_label.text == line, "Wake dialogue order is incorrect")
		dialogue_box._unhandled_input(_interact_event())
		await get_tree().process_frame
		assert(not dialogue_active, "Wake dialogue did not unlock input")
		_unhandled_input(_interact_event())
		assert(not dialogue_active, "Far interaction unexpectedly started")
		player.global_position = boxing_glove_area.global_position - player_collision.position
		await get_tree().physics_frame
		_unhandled_input(_interact_event())
		assert(dialogue_active and dialogue_box.body_label.text == "복싱 글러브다...", "Near interaction did not begin")
		dialogue_box._unhandled_input(_interact_event())
		assert(dialogue_box.body_label.text == "누군가에게 복싱을 알려준 적이 있던 것 같다...", "Glove dialogue order is incorrect")
		dialogue_box._unhandled_input(_interact_event())
		await get_tree().process_frame
		assert(not dialogue_active, "Glove dialogue did not unlock input")
		print("DIALOGUE_TEST_PASS: wake dialogue -> range-gated glove interaction -> input unlock")
		get_tree().quit()
	else:
		await get_tree().create_timer(sleep_seconds).timeout
		_start_wake_sequence()


func _physics_process(_delta: float) -> void:
	if player_state != PlayerState.PLAYING or dialogue_active:
		return

	var input_direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	input_direction += Vector2(
		float(touch_pressed["right"]) - float(touch_pressed["left"]),
		float(touch_pressed["down"]) - float(touch_pressed["up"])
	)
	if Input.is_key_pressed(KEY_A): input_direction.x -= 1.0
	if Input.is_key_pressed(KEY_D): input_direction.x += 1.0
	if Input.is_key_pressed(KEY_W): input_direction.y -= 1.0
	if Input.is_key_pressed(KEY_S): input_direction.y += 1.0
	input_direction = input_direction.limit_length(1.0)

	player.velocity = input_direction * walk_speed
	player.move_and_slide()
	_update_walk_animation(input_direction)


func _unhandled_input(event: InputEvent) -> void:
	if player_state != PlayerState.PLAYING or dialogue_active:
		return
	if event.is_action_pressed("interact") and _is_near_boxing_gloves():
		get_viewport().set_input_as_handled()
		_start_dialogue(PackedStringArray([
			"복싱 글러브다...",
			"누군가에게 복싱을 알려준 적이 있던 것 같다...",
		]))


func _is_near_boxing_gloves() -> bool:
	# The Area2D is the authoritative interaction range. The distance fallback
	# uses the same collision-center anchor so it remains reliable immediately
	# after the player stops at the edge of a wall collision.
	var player_collision_center := player.global_position + player_collision.position
	return boxing_glove_area.has_overlapping_bodies() or player_collision_center.distance_to(boxing_glove_area.global_position) <= boxing_glove_interaction_distance


func _build_all_player_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"sleep")
	frames.set_animation_speed(&"sleep", 3.0)
	frames.set_animation_loop(&"sleep", true)
	for frame_number in range(1, 6):
		var texture := load(SLEEP_FRAME_PATH % frame_number) as Texture2D
		assert(texture != null, "Missing sleep animation frame")
		frames.add_frame(&"sleep", texture)

	for direction in WALK_DIRECTIONS:
		var animation_name := StringName("walk_%s" % direction)
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, 12.0)
		frames.set_animation_loop(animation_name, true)
		for frame_number in range(1, 11):
			var texture := load(WALK_FRAME_PATH % [direction, frame_number]) as Texture2D
			assert(texture != null, "Missing walk animation frame")
			frames.add_frame(animation_name, texture)
	return frames


func _apply_bed_frame_offset() -> void:
	if bed_pose_sprite.animation != &"sleep":
		return
	bed_pose_sprite.position = sleep_frame_offsets[bed_pose_sprite.frame] if bed_pose_sprite.frame < sleep_frame_offsets.size() else Vector2.ZERO


func _start_wake_sequence() -> void:
	if player_state != PlayerState.SLEEPING:
		return
	player_state = PlayerState.WAKING
	for direction_name in touch_pressed:
		touch_pressed[direction_name] = false
	_run_wake_fade_transition()


func _run_wake_fade_transition() -> void:
	status_label.text = "맹돌이가 눈을 뜨고 있어요…"
	var fade_to_black := create_tween()
	fade_to_black.set_trans(Tween.TRANS_SINE)
	fade_to_black.set_ease(Tween.EASE_IN_OUT)
	fade_to_black.tween_property(fade_overlay, "color:a", 1.0, wake_fade_to_black_duration)
	await fade_to_black.finished
	if player_state != PlayerState.WAKING:
		return

	# This swap happens only under a fully opaque overlay.
	bed_pose_sprite.stop()
	bed_pose_sprite.position = Vector2.ZERO
	bed_pose_visual.hide()
	player.global_position = exit_anchor.global_position
	walk_visual.show()
	walk_sprite.animation = &"walk_s"
	walk_sprite.frame = 0
	walk_sprite.pause()
	player_collision.set_deferred("disabled", false)
	await get_tree().physics_frame

	var fade_from_black := create_tween()
	fade_from_black.set_trans(Tween.TRANS_SINE)
	fade_from_black.set_ease(Tween.EASE_IN_OUT)
	fade_from_black.tween_property(fade_overlay, "color:a", 0.0, wake_fade_from_black_duration)
	await fade_from_black.finished
	if player_state != PlayerState.WAKING:
		return
	player_state = PlayerState.PLAYING
	if "--smoke-test" in OS.get_cmdline_user_args():
		status_label.text = "방향키 · WASD · 화면 버튼으로 움직여 보세요"
	else:
		_start_dialogue(PackedStringArray([
			"으음... 여기가 어디지?",
			"왜 아무 기억도 나질 않지?",
			"주변을 둘러봐야겠어",
		]))


func _update_walk_animation(direction: Vector2) -> void:
	if direction.length_squared() < 0.01:
		if walk_is_moving:
			walk_sprite.pause()
			walk_sprite.frame = 0
			walk_sprite.frame_progress = 0.0
			walk_is_moving = false
		return

	var visual_direction := _direction_name(direction)
	var source: Dictionary = WALK_VISUAL_SOURCES[visual_direction]
	var animation_name: StringName = source["animation"]
	var flip_h: bool = source["flip_h"]
	if walk_sprite.animation != animation_name or walk_sprite.flip_h != flip_h:
		var preserved_frame := walk_sprite.frame
		var preserved_progress := walk_sprite.frame_progress
		walk_sprite.animation = animation_name
		walk_sprite.flip_h = flip_h
		walk_sprite.frame = mini(preserved_frame, walk_sprite.sprite_frames.get_frame_count(animation_name) - 1)
		walk_sprite.frame_progress = preserved_progress
	walk_sprite.position = _walk_offset_for(visual_direction)
	walk_sprite.play()
	walk_is_moving = true


func _direction_name(direction: Vector2) -> StringName:
	var abs_x := absf(direction.x)
	var abs_y := absf(direction.y)
	var was_diagonal := last_walk_direction in [&"ne", &"nw", &"se", &"sw"]
	# Hysteresis avoids flip-flopping when an analog/touch input sits near a
	# cardinal/diagonal boundary. It only changes the displayed direction.
	var diagonal_threshold := 0.48 if was_diagonal else 0.66
	var is_diagonal := abs_x >= abs_y * diagonal_threshold and abs_y >= abs_x * diagonal_threshold
	if is_diagonal:
		last_walk_direction = &"se" if direction.x > 0.0 and direction.y > 0.0 else \
			&"ne" if direction.x > 0.0 else &"sw" if direction.y > 0.0 else &"nw"
	elif abs_x > abs_y:
		last_walk_direction = &"e" if direction.x > 0.0 else &"w"
	else:
		last_walk_direction = &"s" if direction.y > 0.0 else &"n"
	return last_walk_direction


func _walk_offset_for(direction: StringName) -> Vector2:
	var direction_index := WALK_DIRECTIONS.find(direction)
	return walk_direction_offsets[direction_index] if direction_index >= 0 and direction_index < walk_direction_offsets.size() else Vector2.ZERO


func _assert_walk_visual_mapping() -> void:
	var visual_only_position := player.global_position
	var checks := [
		{ "input": Vector2(0.0, -1.0), "animation": &"walk_n", "flip_h": false },
		{ "input": Vector2(-1.0, -1.0), "animation": &"walk_ne", "flip_h": true },
		{ "input": Vector2(1.0, -1.0), "animation": &"walk_ne", "flip_h": false },
		{ "input": Vector2(-1.0, 0.0), "animation": &"walk_e", "flip_h": true },
		{ "input": Vector2(1.0, 0.0), "animation": &"walk_e", "flip_h": false },
		{ "input": Vector2(-1.0, 1.0), "animation": &"walk_se", "flip_h": true },
		{ "input": Vector2(1.0, 1.0), "animation": &"walk_se", "flip_h": false },
		{ "input": Vector2(0.0, 1.0), "animation": &"walk_s", "flip_h": false },
	]
	for check in checks:
		_update_walk_animation(check["input"])
		assert(walk_sprite.animation == check["animation"] and walk_sprite.flip_h == check["flip_h"], "Incorrect visual direction mapping")
		assert(player.global_position == visual_only_position, "Visual selection moved the player root")
	_update_walk_animation(Vector2.RIGHT)
	walk_sprite.frame = 4
	walk_sprite.frame_progress = 0.5
	_update_walk_animation(Vector2(1.0, -1.0))
	assert(walk_sprite.frame == 4 and is_equal_approx(walk_sprite.frame_progress, 0.5), "Direction switch reset walk phase")


func _build_touch_controls() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "TouchControls"
	add_child(canvas)

	status_label = Label.new()
	status_label.position = Vector2(610.0, 26.0)
	status_label.size = Vector2(700.0, 50.0)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 26)
	status_label.add_theme_color_override("font_color", Color("5b4636"))
	status_label.text = "맹돌이가 잠들어 있어요…"
	canvas.add_child(status_label)

	var controls := {
		"left": [Vector2(62.0, 878.0), "◀"],
		"right": [Vector2(238.0, 878.0), "▶"],
		"up": [Vector2(150.0, 790.0), "▲"],
		"down": [Vector2(150.0, 966.0), "▼"],
	}
	for direction_name in controls:
		var values: Array = controls[direction_name]
		var button := Button.new()
		button.name = "%sButton" % direction_name.capitalize()
		button.position = values[0]
		button.size = Vector2(78.0, 70.0)
		button.text = values[1]
		button.add_theme_font_size_override("font_size", 28)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.32, 0.25, 0.20, 0.42)
		style.corner_radius_top_left = 28
		style.corner_radius_top_right = 28
		style.corner_radius_bottom_left = 28
		style.corner_radius_bottom_right = 28
		button.add_theme_stylebox_override("normal", style)
		button.button_down.connect(_set_touch_pressed.bind(direction_name, true))
		button.button_up.connect(_set_touch_pressed.bind(direction_name, false))
		canvas.add_child(button)

	fade_overlay = ColorRect.new()
	fade_overlay.name = "FadeOverlay"
	fade_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_overlay.z_index = 100
	canvas.add_child(fade_overlay)


func _build_dialogue_box() -> void:
	dialogue_box = DialogueBoxScene.new()
	dialogue_box.name = "DialogueBox"
	$TouchControls.add_child(dialogue_box)


func _start_dialogue(lines: PackedStringArray) -> void:
	if dialogue_active:
		return
	dialogue_active = true
	for direction_name in touch_pressed:
		touch_pressed[direction_name] = false
	status_label.text = ""
	dialogue_box.show_lines(lines)
	await dialogue_box.dialogue_finished
	dialogue_active = false
	status_label.text = "방향키 · WASD · 화면 버튼으로 움직여 보세요"


func _set_touch_pressed(direction_name: String, pressed: bool) -> void:
	touch_pressed[direction_name] = pressed


func _interact_event() -> InputEventAction:
	var event := InputEventAction.new()
	event.action = &"interact"
	event.pressed = true
	return event


func _save_capture(filename: String) -> void:
	for frame_index in range(4):
		await get_tree().process_frame
	var output_dir := ProjectSettings.globalize_path("res://qa")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var capture := get_viewport().get_texture().get_image()
	var result := capture.save_png(output_dir.path_join(filename))
	if result != OK:
		push_error("Could not save Godot QA capture: %s" % error_string(result))
