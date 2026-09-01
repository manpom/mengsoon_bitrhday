extends Node
## 게임 진행 상태 (Autoload 이름: [b]GameState[/b])
##
## [b]역할[/b]
##   "어디까지 진행했는가"를 기억하는 아주 얇은 창고입니다.
##   씬을 바꿔도 살아남기 때문에, 오프닝을 이미 봤는지 · 어떤 기억(사진)을
##   해금했는지 같은 정보를 여기에 넣습니다.
##
## [b]쓰는 법[/b]
##   [codeblock]
##   GameState.set_flag("intro_done")          # 켜기
##   if GameState.get_flag("intro_done"):      # 확인
##   [/codeblock]
##
## Autoload(자동 로드)란 게임이 시작될 때 자동으로 만들어져서 끝날 때까지
## 살아 있는 노드입니다. project.godot 의 [autoload] 항목에 등록돼 있습니다.
##
## [b]아직 없는 것[/b]: 저장/불러오기. 나중에 user:// 에 JSON 으로 떨구면 됩니다.
## (save() / load_from_disk() 자리만 아래에 비워 뒀습니다)

## 플래그가 바뀔 때마다 알려 줍니다. UI 가 이걸 듣고 갱신할 수 있습니다.
signal flag_changed(flag: String, value: Variant)

## 모든 진행 상태가 여기 한 군데에 모입니다.
var flags: Dictionary = {}


func set_flag(flag: String, value: Variant = true) -> void:
	if flags.get(flag) == value:
		return
	flags[flag] = value
	flag_changed.emit(flag, value)


func get_flag(flag: String, fallback: Variant = false) -> Variant:
	return flags.get(flag, fallback)


func has_flag(flag: String) -> bool:
	return flags.has(flag)


## 오프닝을 다시 보고 싶을 때 씁니다. (디버그용)
func reset() -> void:
	flags.clear()
