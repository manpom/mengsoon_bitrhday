extends Node2D

# The character root is always its feet. This makes collision, depth cues and
# interaction distance agree in the 3/4 top-down room.
const GLOVE_STAND := Vector2(1040, 530)
const SPEED := 240.0
const ARRIVE_DISTANCE := 10.0
const IDLE_DOWN := preload("res://assets/sprites/characters/mengdol/mengdol_down_idle.png")
const WALK_DOWN_1 := preload("res://assets/sprites/characters/mengdol/mengdol_down_walk1.png")
const WALK_DOWN_2 := preload("res://assets/sprites/characters/mengdol/mengdol_down_walk2.png")
const IDLE_UP := preload("res://assets/sprites/characters/mengdol/mengdol_up_idle.png")
const WALK_UP_1 := preload("res://assets/sprites/characters/mengdol/mengdol_up_walk1.png")
const WALK_UP_2 := preload("res://assets/sprites/characters/mengdol/mengdol_up_walk2.png")
const WALK_SHEET := preload("res://assets/sprites/characters/mengdol/mengdol_walk_8dir_10f.png")
const WALK_CELL_SIZE := Vector2(140.2, 140.25)
const WALK_FRAME_SIZE := Vector2(140.2, 132.0)

@onready var player: CharacterBody2D = $Player
@onready var body: Sprite2D = $Player/Body
@onready var prompt: Label = $UI/Prompt
@onready var objective: Label = $UI/Objective
@onready var dialogue_box: Panel = $UI/DialogueBox
@onready var dialogue_text: Label = $UI/DialogueBox/Text
@onready var indicators: Node2D = $Indicators

var target := Vector2.INF
var animation_time := 0.0
var facing_up := false
var facing_row := 0
var opening_index := 0
var opening_active := true
var pending_interaction := ""

const OPENING_LINES := [
	"도로롱... 도로롱...",
	"으음...",
	"여기가... 어디지?",
	"내 집인가? 기억이 나질 않아.",
	"주위를 둘러봐야겠어."
]
const INTERACTIONS := {
	"bed": {"position": Vector2(230, 350), "lines": ["포근한 침대다.", "방금 전까지 여기서 자고 있었던 것 같다."]},
	"table": {"position": Vector2(755, 260), "lines": ["따뜻한 찻잔이 놓여 있다.", "누군가와 함께 마셨던 기억이... 잘 떠오르지 않는다."]},
	"gloves": {"position": GLOVE_STAND, "lines": []}
}

func _ready() -> void:
	create_room_props()
	body.texture = WALK_SHEET
	body.region_enabled = true
	body.region_rect = Rect2(Vector2.ZERO, WALK_FRAME_SIZE)
	body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.scale = Vector2(1.35, 1.35)
	body.visible = false
	indicators.visible = false
	objective.visible = false
	prompt.visible = false
	dialogue_box.visible = true
	dialogue_text.text = OPENING_LINES[opening_index]
	if "--preview-player" in OS.get_cmdline_user_args():
		opening_active = false
		body.visible = true
		indicators.visible = false
		dialogue_box.visible = false
		objective.visible = true
		objective.text = "이동 애니메이션 프레임 검수"

func create_room_props() -> void:
	var props := [
		["bed", "res://assets/sprites/props/bed_base.png", Vector2(220, 270), Vector2(1.35, 1.35), Vector2(180, 70)],
		["gloves", "res://assets/sprites/props/glove.png", Vector2(1020, 160), Vector2(0.8, 0.8), Vector2(80, 34)],
		["bookshelf", "res://assets/sprites/props/shelf.png", Vector2(960, 285), Vector2(1.5, 1.5), Vector2(110, 46)],
		["table", "res://assets/sprites/props/desk.png", Vector2(670, 400), Vector2(0.7, 0.7), Vector2(110, 52)],
		["lamp", "res://assets/sprites/props/clock.png", Vector2(830, 285), Vector2(1.1, 1.1), Vector2(48, 26)],
		["plant", "res://assets/sprites/props/plant.png", Vector2(1120, 430), Vector2(0.65, 0.65), Vector2(60, 30)]
	]
	for item in props:
		var sprite := Sprite2D.new()
		sprite.name = item[0]
		sprite.texture = load(item[1])
		sprite.position = item[2]
		sprite.scale = item[3]
		sprite.offset = Vector2(0, -120)
		add_child(sprite)
		var solid := StaticBody2D.new()
		solid.position = item[2]
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = item[4]
		collision.shape = shape
		collision.position = Vector2(0, -10)
		solid.add_child(collision)
		add_child(solid)

func _unhandled_input(event: InputEvent) -> void:
	if opening_active:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			advance_opening()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("interact"):
			advance_opening()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var world: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * event.position
		var name := nearest_interactable(world)
		if not name.is_empty() and player.global_position.distance_to(INTERACTIONS[name].position) < 92.0:
			begin_interaction(name)
		else:
			target = Vector2(clampf(world.x, 70.0, 1200.0), clampf(world.y, 390.0, 650.0))
			pending_interaction = name
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		var name := nearest_interactable(player.global_position)
		if not name.is_empty():
			begin_interaction(name)

func _physics_process(delta: float) -> void:
	if opening_active:
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		target = Vector2.INF
	elif target != Vector2.INF:
		var to_target := target - player.global_position
		if to_target.length() <= ARRIVE_DISTANCE:
			target = Vector2.INF
		else:
			direction = to_target.normalized()
	player.velocity = direction * SPEED
	player.move_and_slide()
	update_walk(direction, delta)
	if not pending_interaction.is_empty() and player.global_position.distance_to(INTERACTIONS[pending_interaction].position) < 92.0:
		begin_interaction(pending_interaction)
	var near_gloves := player.global_position.distance_to(GLOVE_STAND) < 92.0
	var nearby := nearest_interactable(player.global_position)
	prompt.visible = not nearby.is_empty()
	if prompt.visible:
		prompt.text = "탭 또는 SPACE · 조사"

func update_walk(direction: Vector2, delta: float) -> void:
	body.texture = WALK_SHEET
	body.region_enabled = true
	body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.scale = Vector2(1.35, 1.35)
	if direction != Vector2.ZERO:
		facing_row = direction_to_row(direction)
		animation_time = fmod(animation_time + delta, 1.0)
	var frame := int(animation_time * 10.0) % 10 if direction != Vector2.ZERO else 0
	body.region_rect = Rect2(Vector2(frame * WALK_CELL_SIZE.x, facing_row * WALK_CELL_SIZE.y), WALK_FRAME_SIZE)

func direction_to_row(direction: Vector2) -> int:
	var angle := fposmod(direction.angle() + TAU, TAU)
	if angle < PI / 8.0 or angle >= TAU - PI / 8.0: return 2
	if angle < 3.0 * PI / 8.0: return 1
	if angle < 5.0 * PI / 8.0: return 0
	if angle < 7.0 * PI / 8.0: return 7
	if angle < 9.0 * PI / 8.0: return 6
	if angle < 11.0 * PI / 8.0: return 5
	if angle < 13.0 * PI / 8.0: return 4
	return 3

func nearest_interactable(point: Vector2) -> String:
	var closest := ""
	var distance := 110.0
	for key in INTERACTIONS:
		var candidate_distance: float = point.distance_to(INTERACTIONS[key].position)
		if candidate_distance < distance:
			closest = key
			distance = candidate_distance
	return closest

func begin_interaction(name: String) -> void:
	pending_interaction = ""
	target = Vector2.INF
	if name == "gloves":
		get_tree().change_scene_to_file("res://scenes/minigame_one.tscn")
		return
	opening_active = true
	dialogue_box.visible = true
	dialogue_text.text = "\n".join(INTERACTIONS[name].lines)

func advance_opening() -> void:
	if opening_index == 0:
		body.visible = true
		player.global_position = Vector2(230, 280)
	elif opening_index == 1:
		var climb_down := create_tween()
		climb_down.tween_property(player, "global_position", Vector2(285, 390), 0.45)
	if opening_index < OPENING_LINES.size() - 1:
		opening_index += 1
		dialogue_text.text = OPENING_LINES[opening_index]
		return
	opening_active = false
	dialogue_box.visible = false
	indicators.visible = true
	objective.visible = true
	objective.text = "주변의 느낌표가 뜬 사물을 살펴보자"
