class_name DialogueBox
extends PanelContainer

signal dialogue_finished

var lines: PackedStringArray
var line_index := 0
var body_label: Label
var continue_label: Label


func _ready() -> void:
	position = Vector2(420.0, 820.0)
	size = Vector2(1080.0, 150.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("3d2a22e8")
	style.border_color = Color("d7ab62")
	style.set_border_width_all(3)
	style.set_corner_radius_all(20)
	style.content_margin_left = 36.0
	style.content_margin_right = 36.0
	style.content_margin_top = 20.0
	style.content_margin_bottom = 18.0
	add_theme_stylebox_override("panel", style)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	add_child(content)
	body_label = Label.new()
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 31)
	body_label.add_theme_color_override("font_color", Color("fff5df"))
	content.add_child(body_label)
	continue_label = Label.new()
	continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	continue_label.text = "Space"
	continue_label.add_theme_font_size_override("font_size", 18)
	continue_label.add_theme_color_override("font_color", Color("f3d76c"))
	content.add_child(continue_label)
	hide()


func show_lines(new_lines: PackedStringArray) -> void:
	lines = new_lines
	line_index = 0
	body_label.text = lines[line_index]
	show()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed("interact"):
		return
	get_viewport().set_input_as_handled()
	line_index += 1
	if line_index >= lines.size():
		hide()
		dialogue_finished.emit()
	else:
		body_label.text = lines[line_index]
