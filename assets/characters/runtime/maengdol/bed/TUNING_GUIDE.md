# 맹돌이·침대 배치 수정 방법

Godot에서 `scenes/bedroom_test.tscn`을 열고 Scene Tree의 노드를 선택한 뒤 Inspector와 2D 화면에서 직접 조절한다.

## Scene Tree에서 조절할 곳

- `Props/Bed`: 침대 전체 위치, 크기, 회전
- `Props/Bed/BedBase`: 침대 이미지만 미세 조절
- `Props/Bed/BedCollision/Footprint`: 침대 충돌 영역 점 편집
- `Props/Bed/PlacementGuides/MaengdolSleepAnchor`: 잠자는 맹돌이의 월드 위치
- `Props/Bed/PlacementGuides/MaengdolExitAnchor`: 기상 후 내려올 위치
- `Actors/Maengdol/BedPoseVisual`: 침대 위 맹돌이의 크기와 회전
- `Actors/Maengdol/WalkVisual`: 바닥에서 걷는 맹돌이의 크기와 회전
- `Actors/Maengdol/MaengdolCollision`: 맹돌이 충돌 크기

`BedPosePreview`와 `WalkPreview`는 편집 화면에서 배율을 확인하기 위한 이미지다. 실행할 때 자동으로 숨겨지고 실제 애니메이션으로 교체된다. `WalkVisual`은 기본적으로 숨겨져 있으므로 바닥 맹돌이 크기를 수정할 때 Scene Tree의 눈 아이콘으로 잠시 표시한다.

## 수면 프레임별 흔들림 조절

Scene Tree에서 최상위 `BedroomTest`를 선택하면 Inspector의 `Bed Animation Fine Tuning`에 `Sleep Frame Offsets`가 나타난다. 수면 배열은 이미지 1~5의 5개 항목이다. 기상은 프레임 애니메이션 대신 검은 화면 페이드 전환을 사용한다.

- 가로 양수: 오른쪽
- 가로 음수: 왼쪽
- 세로 양수: 아래
- 세로 음수: 위

예를 들어 수면 3번 프레임만 왼쪽 4px, 위 2px 옮기려면 `Sleep Frame Offsets`의 2번 값을 `(-4, -2)`로 바꾼다.

## 게임 값

최상위 `BedroomTest`의 Inspector에서 다음 값도 수정한다.

- `Sleep Seconds`: 자동으로 눈을 뜨기 전 기다리는 시간
- `Wake Fade To Black Duration`: 화면이 검어지는 시간
- `Wake Fade From Black Duration`: 화면이 다시 밝아지는 시간
- `Walk Speed`: 이동 속도
- `Movement Bounds Min/Max`: 걸을 수 있는 화면 범위

## 걷기 시각 보정

최상위 `BedroomTest`의 Inspector `Walk Animation Fine Tuning`에서 `Walk Direction Offsets`를 조절할 수 있다. 순서는 `s, se, e, ne, n, nw, w, sw`이며, 이는 `WalkAnimation`의 로컬 시각 위치만 보정한다. 맹돌이 루트의 월드 위치, 이동 범위, 충돌에는 영향을 주지 않는다.

원본 프레임은 각각 독립된 `512×512` PNG이며 동일한 중심점과 바닥 기준점을 사용한다. 애니메이션 시트를 직접 자를 필요가 없다.
