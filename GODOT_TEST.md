# Godot 침실 합성 테스트

## 레이어 순서

1. `EmptyRoomBackground`: 벽·바닥만 있는 16:9 배경
2. `BedBase`: 왼쪽 위 벽에 수평으로 놓인 가로형 빈 침대
3. `Maengdol`: 보정된 5프레임 수면 → 5프레임 기상 → 침대 하차 → 8방향 걷기

침대 충돌은 이미지와 분리된 `StaticBody2D`이며 맹돌이는 `CharacterBody2D`로 이동한다. 방향키·WASD와 화면 왼쪽 아래 터치 방향 버튼을 모두 지원한다.

## Scene Tree와 Inspector 편집

침대와 맹돌이는 실행 시 코드가 생성하지 않고 `scenes/bedroom_test.tscn`에 실제 노드로 저장된다. 자주 조절할 항목은 다음 노드를 선택해 2D 화면에서 드래그하거나 Inspector의 Transform 값을 수정한다.

- `Props/Bed`: 침대 위치·크기·회전
- `Bed/PlacementGuides/MaengdolSleepAnchor`: 잠자는 위치
- `Bed/PlacementGuides/MaengdolExitAnchor`: 내려오는 위치
- `Actors/Maengdol/BedPoseVisual`: 침대 위 맹돌이 크기·회전
- `Actors/Maengdol/WalkVisual`: 보행 맹돌이 크기·회전
- `Actors/Maengdol/MaengdolCollision`: 플레이어 충돌 크기

편집기에서 캐릭터를 보면서 조절할 수 있도록 각 Visual 아래에 Preview 노드가 있다. Preview는 게임 실행 시 자동으로 숨겨진다.

## 실행

```powershell
& 'C:\Users\POM\Desktop\pom\AI\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe' --path . --editor
```

Godot의 헤드리스 더미 렌더러는 화면 텍스처를 만들지 않으므로 QA 캡처는 실제 Windows 렌더러로 만든다. 창은 화면 밖에서 열리고 캡처 직후 자동 종료된다.

```powershell
& 'C:\Users\POM\Desktop\pom\AI\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe' --path . 'res://scenes/bedroom_test.tscn' --resolution 1920x1080 --position 10000,10000 --quit-after 300 -- --capture-sleep
& 'C:\Users\POM\Desktop\pom\AI\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe' --path . 'res://scenes/bedroom_test.tscn' --resolution 1920x1080 --position 10000,10000 --quit-after 360 -- --capture-awake
& '.\scripts\verify_room_bed_assets.ps1'
```
