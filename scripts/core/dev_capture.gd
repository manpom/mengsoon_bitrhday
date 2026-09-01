extends Node
## 개발용 스크린샷 도구 (Autoload 이름: [b]DevCapture[/b])
##
## 평소에는 아무 일도 하지 않습니다. 명령줄에 --capture 를 줬을 때만 깨어나서
## 정해진 시각에 게임 화면을 PNG 로 저장하고 게임을 끕니다.
## 오프닝처럼 "한 번 흘러가면 다시 보기 번거로운" 장면을 확인할 때 편합니다.
##
## [b]쓰는 법[/b] (프로젝트 폴더에서)
##   [codeblock]
##   godot --path . -- --capture 1,3.5,8 --capture-dir shots --autoplay
##   [/codeblock]
##   --capture      초 단위 시각들. 쉼표로 구분.
##   --capture-dir  저장 폴더 (없으면 user:// 안에 만듭니다)
##   --autoplay     1.6초마다 상호작용 키를 대신 눌러 줍니다 (대사 넘기기용)
##   --autoplay-count  위 자동 누르기를 N번만 하고 멈춤
##   --click        화면 찍기. "화면x,화면y,시각초" (기준 해상도 480x270 좌표)
##   --hold         키를 누르고 있기. "액션이름,시작초,누르는시간" (여러 번 써도 됨)
##                  예) --hold move_right,13,1.4  → 13초에 D 를 1.4초 누른 효과
##
## [b]`--` 가 왜 필요한가[/b]: 그 뒤의 인자는 Godot 이 자기 옵션으로 해석하지
## 않고 게임에게 그대로 넘겨줍니다. OS.get_cmdline_user_args() 로 받습니다.

const AUTOPLAY_INTERVAL := 1.6

var _times: Array[float] = []
var _dir := "user://shots"
var _autoplay := false
var _holds: Array[Dictionary] = []
var _autoplay_left := -1     # -1 = 무제한
var _clicks: Array[Dictionary] = []


func _ready() -> void:
	_parse_args()
	if _times.is_empty():
		return
	_run()


func _parse_args() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		match args[i]:
			"--capture":
				i += 1
				if i < args.size():
					for piece in args[i].split(",", false):
						_times.append(float(piece))
			"--capture-dir":
				i += 1
				if i < args.size():
					_dir = args[i]
			"--autoplay":
				_autoplay = true
			"--autoplay-count":
				i += 1
				if i < args.size():
					_autoplay_left = int(args[i])
			"--click":
				i += 1
				if i < args.size():
					var c := args[i].split(",")
					if c.size() == 3:
						_clicks.append({
							"x": float(c[0]), "y": float(c[1]), "at": float(c[2]),
						})
			"--hold":
				i += 1
				if i < args.size():
					var parts := args[i].split(",")
					if parts.size() == 3:
						_holds.append({
							"action": parts[0],
							"start": float(parts[1]),
							"duration": float(parts[2]),
						})
		i += 1
	_times.sort()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(_dir)
	if _autoplay:
		_start_autoplay()
	for click in _clicks:
		_run_click(click)
	for hold in _holds:
		_run_hold(hold)   # await 하지 않고 각자 따로 흘러가게 둡니다

	var elapsed := 0.0
	for index in _times.size():
		var wait: float = _times[index] - elapsed
		if wait > 0.0:
			await get_tree().create_timer(wait).timeout
		elapsed = _times[index]
		# 그려진 뒤에 읽어야 지금 화면이 나옵니다.
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		var path := "%s/shot_%02d.png" % [_dir, index]
		image.save_png(path)
		print("[capture] %s  @ %.2fs" % [path, elapsed])

	get_tree().quit()


func _start_autoplay() -> void:
	var timer := Timer.new()
	timer.wait_time = AUTOPLAY_INTERVAL
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(_press_interact)


## 화면의 한 지점을 마우스로 클릭한 것처럼 만들어 줍니다.
## 아이폰 터치도 Godot 이 마우스 클릭으로 바꿔 보내므로, 이걸로 터치 조작을
## 그대로 시험해 볼 수 있습니다.
func _run_click(click: Dictionary) -> void:
	await get_tree().create_timer(float(click["at"])).timeout
	var at := Vector2(float(click["x"]), float(click["y"]))
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = at
		event.global_position = at
		Input.parse_input_event(event)
		await get_tree().process_frame


## 이동은 Input 의 눌림 상태만 보면 되므로 action_press/release 로 충분합니다.
func _run_hold(hold: Dictionary) -> void:
	await get_tree().create_timer(float(hold["start"])).timeout
	Input.action_press(String(hold["action"]))
	await get_tree().create_timer(float(hold["duration"])).timeout
	Input.action_release(String(hold["action"]))


## InputEventAction 은 진짜 키를 누른 것처럼 입력 처리 경로를 타고 흐릅니다.
## (Input.action_press() 는 상태만 바꿔서 _unhandled_input 까지 가지 않습니다)
func _press_interact() -> void:
	if _autoplay_left == 0:
		return
	if _autoplay_left > 0:
		_autoplay_left -= 1
	var press := InputEventAction.new()
	press.action = "interact"
	press.pressed = true
	Input.parse_input_event(press)
	# 뗀 것까지 보내야 다음 눌림이 "새로 누른 것"으로 잡힙니다.
	# (안 떼면 is_action_just_pressed 가 한 번만 참이 됩니다)
	await get_tree().process_frame
	var release := InputEventAction.new()
	release.action = "interact"
	release.pressed = false
	Input.parse_input_event(release)
