# 맹꽁의 기억 (가제)

미니게임을 하나씩 클리어할 때마다 실제 커플 사진이 "기억"으로 해금되는 2D 픽셀아트 웹게임.

- 엔진: **Godot 4.7**
- 목표 플랫폼: **Web Export → iPhone Safari**
- 목표 완성일: **2026년 10월 20일**
- 분량 목표: **미니게임 5개 × 사진 2장 = 총 10장 해금**
  (그래서 맹돌이 방 벽에 걸린 빈 액자도 5개입니다. 액자 하나 = 미니게임 하나)

> 현재 단계: **1장 오프닝**. 눈을 뜨고 → 침대에서 내려오고 → 방 안의 물건을 조사하는 데까지.
> 미니게임 · 사진 앨범 · 저장 시스템은 아직 없습니다.

---

## 1. 실행하는 법

1. Godot 4.7 에디터를 켠다
2. **[가져오기(Import)]** 버튼 → 이 폴더의 `project.godot` 선택
3. 열리면 **F5** (또는 우상단 ▶ 재생 버튼)

| 조작 | 키보드 | 포인터 (마우스 · 아이폰 터치) |
|---|---|---|
| 이동 | **W A S D** / 방향키 | 바닥을 **찍으면** 그리로 걸어감 |
| 조사 | **Space**, **Enter** | 물건을 **찍으면** 그 앞까지 걸어가서 자동으로 조사 |
| 대사 넘기기 | **Space**, **Enter** | 아무 데나 클릭/탭 |

두 방식이 항상 같이 살아 있습니다. 키보드를 누르면 찍어둔 목적지는 즉시 취소됩니다.

게임을 켜면 검은 화면에서 시작해 눈을 두 번 껌뻑이며 오프닝이 자동으로 흘러갑니다.

---

## 2. Godot의 기본 개념 (Scene / Node / Autoload)

### Node (노드)
기능 한 조각.

| 노드 | 하는 일 |
|---|---|
| `Node2D` | 위치·회전만 가진 가장 기본 2D 노드. 폴더처럼도 씀 |
| `Sprite2D` | 이미지 한 장을 화면에 그림 |
| `AnimatedSprite2D` | 여러 장을 순서대로 넘겨서 애니메이션을 만듦 |
| `CharacterBody2D` | 코드로 직접 움직이는 물리 몸체 (플레이어·NPC용) |
| `StaticBody2D` | 움직이지 않고 막기만 하는 몸체 (벽·가구) |
| `CollisionShape2D` | 위 몸체들의 "실제 충돌 판정 모양" |
| `Area2D` | 부딪히진 않고 **겹쳤는지만** 감지 (조사 범위) |
| `Camera2D` | 화면을 어디를 비출지 결정 |
| `CanvasLayer` | 카메라가 움직여도 화면에 고정되는 UI 층 |
| `AudioStreamPlayer` | 소리 한 개를 재생 |

### Scene (씬)
**노드들을 부모-자식으로 조립해서 저장한 것**이 씬(`.tscn`)입니다.
씬은 다른 씬 안에 **부품처럼 끼워 넣을 수 있습니다**(인스턴스).

```
mengdol_house.tscn  (무대)
   ├─ mengdol.tscn  을 끼워 넣음      ← 플레이어
   └─ prop.tscn     을 6번 끼워 넣음  ← 침대 / 옷장 / 창문 / 문 / 책상 / 의자
```

### Autoload (자동 로드)
게임이 켜져 있는 내내 살아 있어서, **어느 씬에서든 이름으로 부를 수 있는 노드**입니다.
`project.godot` 의 `[autoload]` 에 등록돼 있습니다.

| 이름 | 하는 일 |
|---|---|
| `GameState` | 어디까지 진행했는지 기억 (`GameState.set_flag("intro_done")`) |
| `Dialogue` | 화면 아래 대사창. `Dialogue.say(["안녕"])` 한 줄로 어디서든 호출 |
| `DevCapture` | 개발용 스크린샷 도구. 평소엔 아무 일도 안 함 (10번 항목) |

---

## 3. 폴더 구조

```
맹순/
├── project.godot                  ← "여기가 프로젝트 루트"임을 알리는 파일 + 각종 설정
├── meng.png                       ← ★ 캐릭터 레퍼런스 시트 (원본 디자인)
│
├── assets/
│   ├── fonts/
│   │   ├── Galmuri11.ttf          ← ★ 한글 픽셀 폰트 (OFL, 웹 배포 가능)
│   │   ├── Galmuri11-Bold.ttf / Galmuri9.ttf
│   │   └── OFL.txt                ← 라이선스 전문 (지우지 마세요)
│   ├── audio/sfx/
│   │   ├── type.wav               ← 글자 찍히는 소리
│   │   ├── step1.wav / step2.wav  ← 발소리 2종
│   │   └── bump.wav               ← (아직 안 씀) 벽에 부딪히는 소리
│   ├── sprites/
│   │   ├── characters/
│   │   │   ├── mengdol/           ← ★ 맹돌이 14장 (아래 5번 항목)
│   │   │   ├── mengsoon/          ← ★ 맹순이 14장 (아직 등장 안 함)
│   │   │   └── *_idle.png         ← 초기 프로토타입 잔재
│   │   ├── props/                 ← 방 배경 + 가구 (build_room.ps1 이 만듦)
│   │   └── ui/
│   │       ├── prompt.png         ← 하얀 느낌표 (그냥 둘러보기)
│   │       ├── prompt_story.png   ← ★ 노란 느낌표 (스토리 진행 / 미니게임)
│   │       └── tap.png            ← 찍은 자리에 뜨는 동그라미
│   └── themes/pixel_ui.tres       ← 모든 UI 의 기본 테마 (폰트 지정)
│
├── scenes/
│   ├── characters/mengdol.tscn    ← ★ 플레이어
│   ├── objects/prop.tscn          ← ★ 방 안의 물건 하나
│   ├── levels/mengdol_house.tscn  ← ★★ 게임 시작 씬
│   ├── ui/dialogue_box.tscn       ← 대사창 (Autoload)
│   └── minigames/                 ← (비어 있음) 미니게임 5개가 들어갈 자리
│
├── scripts/
│   ├── core/game_state.gd         ← 진행 상태 (Autoload)
│   ├── core/dev_capture.gd        ← 개발용 스크린샷 (Autoload)
│   ├── ui/dialogue_box.gd
│   ├── objects/prop.gd            ← class_name Prop
│   ├── characters/mengdol.gd      ← ★ 이동 · 조사 · 애니메이션
│   └── levels/mengdol_house.gd    ← ★ 오프닝 연출 + 무대 관리
│
└── tools/                         ← 게임에 포함되지 않는 개발 도구
    ├── _pixlib.ps1                 공용 픽셀 함수
    ├── build64.ps1                 ★ 캐릭터 한 장을 글자 그림으로 그림
    ├── build_char.ps1              ★ 위를 14번 돌려서 전 프레임 PNG 굽기
    ├── build_room.ps1              ★ 방 배경 + 가구 PNG
    ├── build_sfx.ps1               ★ 효과음 WAV 를 코드로 합성
    ├── generate_sprites.ps1        art/*.txt → PNG
    ├── zoom.ps1 / variants.ps1 / concepts.ps1   캐릭터 비교 시트
    └── art/                        글자로 그린 도트 원본
```

---

## 4. 씬 구조 자세히

### `mengdol_house.tscn` — 맹돌이의 집 (게임 시작 씬)
```
MengdolHouse (Node2D)             ← mengdol_house.gd
├── Floor                         그림만. 항상 캐릭터보다 뒤에 그려짐
│   ├── Background                room_bg.png (640x330)
│   ├── Rug
│   ├── Frame1 ~ Frame5           ★ 빈 액자 5개 = 미니게임 5개 자리
│   ├── Window (Prop)             창문 (새벽 하늘)
│   ├── Door (Prop)               ★ 문 — 벽의 일부라서 여기 있습니다 (아래 설명)
│   └── Bed (Prop)                침대틀 + 매트리스 + 베개
├── Props            ★Y-Sort 켜짐  아래에 있는 것이 앞에 그려짐
│   ├── Quilt                     이불
│   ├── Wardrobe / Desk / Chair   (Prop)
│   └── Player                    mengdol.tscn
├── Walls                         방 밖으로 못 나가게 막는 사각형 4개
├── UI  (CanvasLayer 5)           조작 안내
└── Fx  (CanvasLayer 20)          암전용 검은 사각형 (대사창보다 위에)
```

> **왜 침대틀은 `Floor` 에 있고 이불만 `Props` 에 있나?**
> Y-Sort 는 "화면에서 아래에 있는 것을 앞에" 그립니다.
> 침대틀의 기준점(발치, y=300)은 자고 있는 맹돌이(y=262)보다 아래라서,
> 같이 정렬하면 **침대가 맹돌이를 덮어 버립니다.**
> 그래서 침대틀은 아예 뒤 레이어에 고정하고, **덮여야 하는 이불만** Y-Sort 에 넣었습니다.
> 이불 기준점(y=296) > 맹돌이(y=262) → 이불이 앞에 그려짐 → "이불 덮고 누워 있음".
> 침대에서 내려오면 맹돌이가 더 아래로 가므로 **자동으로** 앞에 서게 됩니다.

### `mengdol.tscn` — 플레이어
```
Mengdol (CharacterBody2D)         ← mengdol.gd
├── Shadow                        발밑 그림자
├── Body (AnimatedSprite2D)       앞/뒤/옆 × 서기/걷기 + 표정 5종
├── CollisionShape2D              발밑 30x10 사각형 (몸 전체가 아니라 발밑만!)
├── Interactor (Area2D)           반지름 30 원. 주변 물건 감지
├── Step (AudioStreamPlayer)      발소리
├── TapMark                       찍은 자리에 뜨는 동그라미 (top_level)
└── Camera2D
```

> **왜 충돌 판정이 발밑만인가?**
> 위에서 내려다보는 시점에서는 "바닥에 발이 닿는 면적"만 막으면 자연스럽습니다.

---

## 5. 맹돌이 그림 (앞·뒤·옆 / 걷기 / 표정)

한 명당 **14장**이 자동으로 만들어집니다.

| 파일 | 내용 |
|---|---|
| `mengdol_down_idle/walk1/walk2` | 앞모습 (우리 쪽을 봄) |
| `mengdol_up_idle/walk1/walk2` | **뒷모습** (위로 걸어갈 때) |
| `mengdol_side_idle/walk1/walk2` | 옆모습 (얼굴이 오른쪽으로 돌아감. 왼쪽은 좌우반전) |
| `mengdol_face_happy` | 😊 눈을 ^^ 로 감고 웃음 |
| `mengdol_face_surprise` | 😲 눈 커지고 입이 동그래짐 |
| `mengdol_face_sad` | 😢 눈꺼풀이 처지고 눈물 한 방울 |
| `mengdol_face_angry` | 😠 눈썹이 안쪽으로 내려감 |
| `mengdol_face_sleepy` | 😪 반쯤 감긴 눈 |

```bash
powershell -ExecutionPolicy Bypass -File tools\build_char.ps1
```
→ `assets/sprites/characters/mengdol/` · `mengsoon/` 에 굽고
   `tools/char_preview.png` 로 28장을 한 장에 모아 보여 줍니다.

### 걷기는 어떻게 굴러가나
`mengdol.tscn` 의 `Body` 노드 안에 애니메이션이 등록돼 있습니다.
걷기는 **walk1 → 서기 → walk2 → 서기** 4프레임을 초당 9장으로 돌립니다.
`mengdol.gd` 가 속도를 보고 방향을 정합니다.

```gdscript
if absf(velocity.x) > absf(velocity.y):
    _facing = "side";  body.flip_h = velocity.x < 0.0
else:
    _facing = "down" if velocity.y > 0.0 else "up"
```

**발소리**는 "발을 딛는 프레임(0번·2번)"으로 넘어갈 때마다 납니다.
그림과 소리가 저절로 맞으므로 따로 타이머를 돌릴 필요가 없습니다.

### 표정 쓰는 법
```gdscript
player.show_face("surprise")   # happy / surprise / sad / angry / sleepy
await get_tree().create_timer(1.0).timeout
player.show_face("")           # 원래 얼굴로
```
표정을 짓고 있는 동안에는 걸어도 그림이 안 바뀝니다(컷신용).

### 그림을 고치고 싶으면
`tools/build64.ps1` 이 캐릭터 한 장을 그립니다. 옵션이 넷입니다.

```bash
powershell -ExecutionPolicy Bypass -File tools\build64.ps1 -Who mengdol -Dir up -Step 1 -Face angry
```

| 옵션 | 값 |
|---|---|
| `-Who` | `mengdol` / `mengsoon` |
| `-Dir` | `down` 앞 / `up` 뒤 / `side` 옆 |
| `-Step` | `0` 서기 / `1` 왼발 듦 / `-1` 오른발 듦 |
| `-Face` | `normal` / `happy` / `surprise` / `sad` / `angry` / `sleepy` |
| `-Variant` | 얼굴 세부안 0~5 (현재 맹돌이 0, 맹순이 2) |

각 부위를 따로 그린 뒤 **부위마다 1px 외곽선을 두르고 겹쳐 쌓는** 방식이라,
머리가 몸 위에 올라가도 턱선이 뭉개지지 않습니다.

> **옆모습을 고칠 때 주의**: 머리를 돌리는 건 "눈만 옆으로 미는 것"이 아닙니다.
> 눈만 밀면 눈알이 머리 밖으로 삐져나와서 기괴해집니다.
> `build64.ps1` 은 **눈두덩(bump)을 먼저 옮기고, 눈은 각자 자기 눈두덩 한가운데에**
> 놓습니다. 멀리 있는 쪽 눈두덩은 `0.72배`로 줄어들고(원근), 눈은 `0.62배`로
> 납작해지며, 머리 윤곽 자체도 `2.5px` 가까운 쪽으로 기웁니다.
> 이 네 숫자를 같이 만져야 얼굴이 안 무너집니다.

| y | 부위 |
|---|---|
| 1~33 | 머리 (눈두덩 2개 + 크림색 턱) |
| 34~49 | 후드티 |
| 50~55 | 반바지(맹돌이) / 치마(맹순이) |
| 56~58 | 다리 |
| 59~63 | 신발 |

색은 `tools/art/_palette.txt` 에서 `글자 RRGGBB` 한 줄로 정의합니다.

> **PowerShell 함정**: 함수 이름을 `R`, `E`, `C`, `Erase`, `Clear` 로 짓지 마세요.
> PowerShell은 함수보다 **별칭(alias)을 먼저** 찾기 때문에
> `Invoke-History` / `Remove-Item` / `Clear-Host` 가 대신 불립니다.
> (그래서 이름이 `Fill` / `Oval` / `Hex` / `Punch` 입니다.)

---

## 6. 오프닝은 어떻게 흘러가나

`scripts/levels/mengdol_house.gd` 의 `_play_intro()` 하나만 보면 됩니다.

```gdscript
await _fade_to(0.55, 0.50)      # 눈을 반쯤 뜬다
await _fade_to(1.00, 0.22)      # 다시 감는다
await _fade_to(0.30, 0.45)      # 더 뜬다
await _fade_to(0.85, 0.20)      # 또 감는다
await _fade_to(0.00, 0.80)      # 완전히 뜬다

Dialogue.say(LINES_WAKE)        # (으음...) (여기가... 어디지?)
await Dialogue.finished

await _get_out_of_bed()         # 침대에서 내려온다 + 카메라가 뒤로 빠진다

Dialogue.say(LINES_OUT_OF_BED)  # (내 집인가...?) ...
await Dialogue.finished

_begin_play()                   # 조작권을 넘긴다
```

`await` 는 **"이게 끝날 때까지 기다렸다가 다음 줄"** 이라는 뜻입니다.
컷신 쓸 때 제일 편한 문법이라, 앞으로 다른 장면도 이 모양으로 쓰면 됩니다.

대사는 같은 파일 위쪽의 `LINES_WAKE` / `LINES_OUT_OF_BED` 만 고치면 됩니다.

**컷신 동안 조작이 잠기는 방식**: `player.control_enabled = false` 로 두면
`_physics_process` 자체가 꺼집니다. `move_and_slide()` 가 아예 안 돌아가므로,
맹돌이가 침대(=막힌 영역) 안에 서 있어도 물리에 밀려 튀어나오지 않습니다.

---

## 7. 물건 · 느낌표 · 미니게임 연결

### 하얀 느낌표 / 노란 느낌표
```
prompt.png        하양  = 그냥 둘러보는 물건. 대사만 나옴.
prompt_story.png  노랑  = ★ 조사하면 이야기가 진행되는 물건.
                          여기가 미니게임이 시작될 자리입니다.
```
`Prop` 의 `marker_kind` 를 `STORY` 로 두면 노란 느낌표가 붙고,
조사하는 순간 `story_triggered` 신호가 나갑니다.
지금은 **책상**이 노란 느낌표입니다(서랍 안에 뭔가 있다는 대사).

레벨 스크립트가 이걸 한 군데에서 받습니다.

```gdscript
func _on_story_triggered(prop: Node) -> void:
    await Dialogue.finished
    GameState.set_flag("story_" + prop.name, true)
    # ★ 여기서 미니게임 씬으로 넘기면 됩니다:
    # get_tree().change_scene_to_file("res://scenes/minigames/xxx.tscn")
```
미니게임을 클리어하면 사진 2장을 해금하고 이 방으로 돌아오면 됩니다.
`GameState.get_flag("intro_done")` 덕분에 돌아와도 오프닝은 다시 안 나옵니다.

### 물건을 하나 더 놓고 싶다면
에디터에서 `Props`(또는 `Floor`) 밑에 `scenes/objects/prop.tscn` 을 끌어다 놓고,
인스펙터에서 값만 채우면 끝입니다.

| 항목 | 뜻 |
|---|---|
| `texture` | 그림. **아래쪽 한가운데**가 노드 position 에 오도록 자동 배치 |
| `sprite_bottom_pad` | PNG 아래에 들어 있는 그림자 여백 (기본 6, 아래 설명) |
| `marker_kind` | `LOOK` 하양 / `STORY` 노랑 |
| `solid_size` / `solid_offset` | 못 지나가게 막을 사각형. `(0,0)` 이면 통과 가능 |
| `zone_size` / `zone_offset` | 이 안에 들어오면 조사 가능. `(0,0)` 이면 조사 불가 |
| `lines` | 조사했을 때 나올 대사. **한 줄 = 대사창 한 번** |
| `marker_offset` | 느낌표가 뜰 위치 |

> **기준점 규칙**: 모든 물건의 `position` 은 **바닥에 닿는 지점**입니다.
> `solid_offset` · `zone_offset` · `marker_offset` 은 전부 그 지점에서 잰 값이라
> 물건을 통째로 옮겨도 세 개가 같이 따라옵니다.

> **느낌표가 화면 위로 잘리는 문제**: 카메라는 방 밖을 안 비추기 때문에,
> 플레이어가 방 아래쪽에 있을 때 화면 맨 위는 대략 `y=60` 입니다.
> `marker_offset` 은 **월드 y 가 65 아래로 오도록** 잡아야 안 잘립니다.

---

## 8. 그림자와 명암

가구가 바닥에 떠 있어 보이지 않도록 **PNG 안에 접지 그림자를 같이 구워 둡니다.**
`build_room.ps1` 의 `Start-Prop` 이 캔버스를 좌우 4px, 아래 `$SHADOW_PAD`(=6)px
넓혀 놓고 거기에 타원 그림자를 먼저 깔아 줍니다.

```
   ┌──────────────┐  ← 캔버스 (물건보다 좌우 4px, 아래 6px 큼)
   │  ┌────────┐  │
   │  │  옷장  │  │
   │  └────────┘  │
   │   ~~~~~~~~   │  ← 그림자
   └──────────────┘
              ↑ PNG 의 진짜 아래끝
        ↑ 여기가 "바닥에 닿는 지점" = 노드 position
```

★ 그래서 **`prop.gd` 의 `sprite_bottom_pad` 와 `build_room.ps1` 의 `$SHADOW_PAD`
는 항상 같은 숫자여야 합니다.** 한쪽만 바꾸면 가구가 위아래로 어긋납니다.

벽에 **걸리는** 것(창문·액자)은 바닥 그림자 대신 `Start-Wall` 이 오른쪽 아래로
살짝 밀린 그림자를 그려서 벽에서 떠 있는 느낌을 냅니다.

**문은 다릅니다.** 문은 벽에 걸린 게 아니라 **벽에 뚫린 구멍**이라서,
그림자가 있으면 "벽 앞에 세워둔 판자"처럼 보입니다. 그래서 문만 세 가지가 다릅니다.

| | 문 | 옷장 같은 가구 |
|---|---|---|
| 그리는 함수 | `Start-Flat` (그림자 없음) | `Start-Prop` (접지 그림자) |
| 씬에서 어디에 | `Floor` (벽의 일부) | `Props` (Y-Sort 대상) |
| 세로 위치 | 아래끝이 **벽/바닥 경계선(y=152)** 에 딱 맞음 | 바닥 위에 섬 |
| 막기 | 없음 (방 위쪽 벽이 이미 막음) | 발치에 `solid_size` |

대신 문틀 **안쪽** 위·왼쪽에만 그늘을 넣어서 "벽에 움푹 들어간" 느낌을 냅니다.

캐릭터는 별도의 `shadow.png` 를 발밑에 깔고, 몸 자체의 명암은
`build64.ps1` 이 "위는 밝게(`L`) / 오른쪽과 턱 밑은 어둡게(`v`)" 칠합니다.

---

## 9. 소리

샘플을 받아 오지 않고 **코드로 파형을 만들어서 WAV로 굽습니다.** 라이선스 걱정이 없습니다.

```bash
powershell -ExecutionPolicy Bypass -File tools\build_sfx.ps1
```

| 파일 | 어떻게 만들었나 | 어디서 쓰나 |
|---|---|---|
| `type.wav` | 사각파 + 사인파를 섞어 42ms 만에 감쇠 | 대사 글자가 나올 때마다 |
| `step1/2.wav` | 필터 건 노이즈 + 낮은 사인 | 걷기 프레임이 발을 딛을 때 |
| `bump.wav` | 더 둔한 노이즈 | (아직 안 씀) |

글자 소리는 **공백·마침표·괄호에서는 쉽니다.** 그래서 말이 끊기는 곳에서 소리도 같이 쉬어
기계음처럼 들리지 않습니다. 간격은 `dialogue_box.gd` 의 `BLIP_GAP`(0.055초)로 조절합니다.

볼륨은 각 `AudioStreamPlayer` 노드의 `volume_db` 로 조절합니다
(지금 발소리 -7dB, 글자 소리 -13dB).

---

## 10. 개발용 스크린샷 도구 (`DevCapture`)

오프닝처럼 "한 번 흘러가면 다시 보기 번거로운" 장면을 이미지로 남길 때 씁니다.
명령줄에 `--capture` 를 주지 않으면 아무 일도 하지 않습니다.

```bash
godot --path . -- --capture 5,13,18 --capture-dir shots --autoplay --autoplay-count 8
```

| 옵션 | 뜻 |
|---|---|
| `--capture` | 캡처할 시각(초). 쉼표로 여러 개 |
| `--capture-dir` | 저장 폴더 |
| `--autoplay` | 1.6초마다 상호작용 키를 대신 눌러 줌 (대사 자동 넘김) |
| `--autoplay-count` | 위 자동 누르기를 N번만 |
| `--hold` | `액션,시작초,누르는시간` — 예: `--hold move_right,14,1.6` |
| `--click` | `x,y,시각초` — 화면 찍기. **창 좌표**(--resolution 값 기준)입니다 |

`--` 뒤의 인자는 Godot 이 자기 옵션으로 해석하지 않고 게임에 그대로 넘겨줍니다.

---

## 11. 대사창 (`Dialogue`)

```gdscript
Dialogue.say(["첫 줄", "둘째 줄"])          # 그냥 띄우기
Dialogue.say(["안녕!"], "맹순이")           # 이름표 달기
await Dialogue.finished                     # 다 끝날 때까지 기다리기
```

| 다른 코드가 알아야 하는 것 | 뜻 |
|---|---|
| `Dialogue.is_active` | 창이 떠 있는 동안 true → **이동**을 잠글 때 |
| `Dialogue.is_blocking()` | 위 + 닫힌 직후 0.18초 → **조사**를 잠글 때 |

`is_blocking()` 이 따로 있는 이유: 창을 닫는 그 클릭이 곧바로 **다음 조사까지 발동**시켜서
대사가 끊기지 않고 이어지는 버그를 막기 위해서입니다.

- 글자 속도 → `dialogue_box.gd` 의 `CHARS_PER_SEC`(34)
- 창 크기·색·테두리 → `dialogue_box.tscn` 의 `Box` 노드 하나
- 대사창은 bbcode 가 켜져 있어서 `[shake]놀랐다![/shake]` 같은 태그를 그대로 쓸 수 있습니다

---

## 12. 방 배경과 가구 고치기

캐릭터와 달리 **사각형과 타원을 쌓아서** 그립니다. 결과가 픽셀 단위로 딱 떨어집니다.

```bash
powershell -ExecutionPolicy Bypass -File tools\build_room.ps1
```

`tools/build_room.ps1` 위쪽에 색 팔레트가 모여 있고, 아래에 물건별 블록이 나뉘어 있습니다.
`Fill x y w h 색` / `Box x y w h 채움색 테두리색` / `Oval x y w h 색` 세 개면 다 그립니다.
확인용 `tools/room_preview.png` 도 같이 나옵니다.

---

## 13. 알아둘 점 / 다음 단계

### 한글 폰트 — ✅ 해결됨
**Galmuri11** (https://github.com/quiple/galmuri, SIL Open Font License 1.1) 을
`assets/fonts/` 에 넣어 두었습니다. 폰트 파일이 프로젝트 안에 있으므로
**웹으로 내보내도 글자가 깨지지 않습니다.**

> ★ **글자 크기는 11 의 배수로 쓰세요.** Galmuri11 은 11픽셀에 딱 맞게 그려진
> 폰트라, 12나 13으로 쓰면 미묘하게 뭉개집니다. 크게 쓰려면 22, 33 으로.
> 안티에일리어싱·힌팅은 `assets/fonts/*.ttf.import` 에서 이미 꺼 두었습니다.
> `OFL.txt` 는 라이선스 조건이라 **지우면 안 됩니다.**

### 아이폰 대비
- ✅ 렌더러 `gl_compatibility` → iOS Safari 의 WebGL2 에서 안정적
- ✅ 텍스처 필터 `Nearest` → 픽셀이 뿌옇게 안 번짐
- ✅ 화면 스트레치 `viewport` + `expand` → 기종별 화면 비율 대응
- ✅ 방(640x330)이 기준 해상도(480x270)보다 커서, 화면이 더 넓어도 방 밖이 안 보임
- ✅ **터치 조작** — 찍은 곳으로 걸어가기 + 물건 찍으면 자동 조사
  (Godot 이 터치를 마우스 클릭으로 바꿔 보내 주기 때문에 마우스 코드 하나로 둘 다 됩니다)

> 아직 안 해 본 것: **실제 아이폰에서 돌려보기.** 웹 내보내기를 한 번 해서
> 폰트·터치·프레임을 실기로 확인해 보는 게 좋습니다.

### 앞으로 붙일 것
- 저장 시스템 — `GameState.flags` 를 `user://` 에 JSON 으로 (자리는 이미 있음)
- 문을 열고 나가면 이어지는 다음 장면
- `scenes/minigames/*.tscn` — 미니게임 5개
- 사진 앨범 — 해금된 사진을 `Frame1`~`Frame5` 액자에 실제로 걸기
- BGM (지금은 효과음만 있음)
- 맹순이 등장 (그림은 이미 14장 다 구워져 있습니다)

---

## 14. Git

```bash
git add . && git commit -m "오프닝 + 대사/조사 시스템 + 걷기 애니메이션 + 한글 폰트 + 효과음"
```
