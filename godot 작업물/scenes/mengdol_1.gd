extends Node2D

var is_awake = false

func _input(event):
	# 모든 입력 이벤트를 수신
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_pos = get_global_mouse_position()
			# 맹돌이 위치(global_position)에서 80픽셀 이내 클릭 여부 확인
			if mouse_pos.distance_to(global_position) < 80:
				wake_up()

func wake_up():
	if is_awake:
		return
	is_awake = true
	print("맹돌이가 깨어났습니다!")
	var tween = create_tween()
	tween.tween_property(self, "position", position - Vector2(0, 30), 0.5)
