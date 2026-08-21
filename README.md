# 맹꽁의 기억 (가제)

미니게임을 하나씩 클리어할 때마다 실제 커플 사진이 "기억"으로 해금되는 2D 픽셀아트 웹게임.

- 엔진: **Godot 4.x**
- 목표 플랫폼: **Web Export → iPhone Safari**
- 목표 완성일: **2026년 10월 20일**

> 현재 단계: **캐릭터 프로토타입**. 미니게임 · 사진 앨범 · 스토리 · 저장 시스템은 아직 없습니다.

---

## 1. 실행하는 법

1. Godot 4.x 에디터를 켠다
2. **[가져오기(Import)]** 버튼 → 이 폴더(`맹순`)의 `project.godot` 선택
3. 열리면 **F5** (또는 우상단 ▶ 재생 버튼)
4. 방향키 또는 **WASD** 로 남자친구 맹꽁이를 조작

에디터 아래 **[출력]** 패널에 두 캐릭터의 화면상 키가 찍힙니다. 비율이 실제 153/181 = 0.845 와 비슷하면 정상입니다.

---

## 2. Godot의 기본 개념 (Scene / Node)

Godot에는 딱 두 가지 개념만 알면 됩니다.

### Node (노드)
기능 한 조각. 예를 들어

| 노드 | 하는 일 |
|---|---|
| `Node2D` | 위치·회전만 가진 가장 기본 2D 노드. 그룹을 묶는 폴더처럼도 씀 |
| `Sprite2D` | 이미지 한 장을 화면에 그림 |
| `CharacterBody2D` | 코드로 직접 움직이는 물리 몸체 (플레이어·NPC용) |
| `StaticBody2D` | 움직이지 않고 막기만 하는 몸체 (벽·바닥) |
| `CollisionShape2D` | 위 몸체들의 "실제 충돌 판정 모양" |
| `Area2D` | 부딪히진 않고 **겹쳤는지만** 감지 (감지 범위·아이템 획득) |
| `Camera2D` | 화면을 어디를 비출지 결정 |
| `CanvasLayer` | 카메라가 움직여도 화면에 고정되는 UI 층 |

### Scene (씬)
**노드들을 부모-자식으로 조립해서 저장한 것**이 씬(`.tscn`)입니다.
씬은 다른 씬 안에 **부품처럼 끼워 넣을 수 있습니다**(인스턴스).

이 프로젝트에서는 이렇게 조립돼 있습니다.

```
prototype_room.tscn  (무대)
   └─ Characters
        ├─ girlfriend.tscn 을 끼워 넣음
        └─ boyfriend.tscn 을 끼워 넣음
```

`boyfriend.tscn` 을 한 번 고치면 이 씬을 쓰는 모든 곳에 반영됩니다.
→ 나중에 미니게임 10개를 만들어도 캐릭터는 한 곳에서만 관리하면 됩니다.

---

## 3. 폴더 구조

```
맹순/
├── project.godot                  ← "여기가 프로젝트 루트"임을 알리는 파일 + 각종 설정
├── icon.svg                       ← 프로젝트 아이콘
├── .gitignore                     ← Git이 무시할 파일 목록
│
├── assets/
│   └── sprites/characters/        ← 실제 게임에 쓰이는 PNG (자동 생성물)
│       ├── boyfriend_idle.png     (32x32)
│       ├── girlfriend_idle.png    (32x32)
│       └── emote_heart.png        (12x10)
│
├── scenes/                        ← 조립된 씬(.tscn)
│   ├── characters/
│   │   ├── boyfriend.tscn         ← 남자친구 부품
│   │   └── girlfriend.tscn        ← 여자친구 부품
│   ├── levels/
│   │   └── prototype_room.tscn    ← ★ 게임 시작 씬(무대)
│   ├── minigames/                 ← (비어 있음) 앞으로 미니게임 8~10개가 들어갈 자리
│   └── ui/                        ← (비어 있음) 대화창·메뉴 등이 들어갈 자리
│
├── scripts/                       ← 코드(.gd)
│   ├── characters/
│   │   ├── boyfriend.gd           ← 이동 조작
│   │   └── girlfriend.gd          ← NPC 반응(하트)
│   ├── levels/
│   │   └── prototype_room.gd      ← 카메라 범위 설정 등 무대 관리
│   └── core/                      ← (비어 있음) 나중에 저장·스토리 진행 관리자가 들어갈 자리
│
└── tools/                         ← 게임에 포함되지 않는 개발 도구
    ├── .gdignore                   ← Godot이 이 폴더를 무시하게 함(게임에 포함 안 됨)
    ├── art/*.txt                   ← ★ 도트 그림 원본 (글자로 그린 그림)
    ├── generate_sprites.ps1       ← 위 txt를 PNG로 굽는 스크립트
    └── preview.png                ← 확대 미리보기 (눈으로 확인용)
```

---

## 4. 씬 구조 자세히

### `prototype_room.tscn` — 무대
```
PrototypeRoom (Node2D)
├── Background (Node2D)          그림만. 충돌 없음
│   ├── Wall / WallTrim / Floor / Rug   (ColorRect = 단색 사각형)
│   └── Decor                    벽에 걸린 빈 액자 3개
│                                → 나중에 여기에 해금된 사진이 걸립니다
├── Walls (Node2D)               방 밖으로 못 나가게 막는 StaticBody2D 4개
├── Characters (Node2D)          ★ Y-Sort 켜짐
│   ├── Girlfriend               아래쪽에 있는 캐릭터가 자동으로 앞에 그려집니다
│   └── Boyfriend
└── UI (CanvasLayer)             카메라와 무관하게 화면에 고정
    └── HintLabel
```

### `boyfriend.tscn` — 남자친구 (플레이어)
```
Boyfriend (CharacterBody2D)      ← boyfriend.gd
├── Sprite2D                     32x32 그림을 2배 확대 → 화면상 64px
├── CollisionShape2D             발밑 36x14 사각형 (몸 전체가 아니라 발밑만!)
└── Camera2D                     캐릭터를 부드럽게 따라감
```

> **왜 충돌 판정이 발밑만인가?**
> 위에서 내려다보는 시점에서는 "바닥에 발이 닿는 면적"만 막으면 자연스럽습니다.
> 몸 전체를 판정으로 잡으면 머리가 벽에 닿아서 못 지나가는 어색한 느낌이 납니다.

### `girlfriend.tscn` — 여자친구 (NPC)
```
Girlfriend (CharacterBody2D)     ← girlfriend.gd (지금은 이동 코드 없음)
├── Sprite2D                     32x32 중 실제로 그려진 건 27px → 화면상 54px
├── CollisionShape2D
├── Emote                        머리 위 하트 (평소엔 숨김)
└── ProximityArea (Area2D)       반지름 64px 원. 플레이어가 들어오면 하트 표시
    └── CollisionShape2D
```

---

## 5. 두 캐릭터의 키 차이

| | 실제 키 | 그려진 픽셀 | 화면상(2배) |
|---|---|---|---|
| 남자친구 맹꽁이 | 181cm | 32px | 64px |
| 여자친구 맹순이 | 153cm | 27px | 54px |

비율 **27 / 32 = 0.844** ≒ 실제 **153 / 181 = 0.845**. 거의 정확히 맞췄습니다.

두 캐릭터를 같은 `y` 좌표(=같은 바닥선)에 세워 두었기 때문에 나란히 서면 키 차이가 바로 보입니다.

**실루엣 구분 포인트**
- 여자친구: 작고 동글동글 / **아주 큰 앞니** / 안경 / 분홍 볼 / 밝은 연두
- 남자친구: 크고 어깨가 넓음 / 앞니 없음 / 남색 조끼+벨트 / 진한 초록

---

## 6. 도트 그림을 수정하는 법

PNG를 직접 그리지 않고, **글자로 그린 그림**을 PNG로 굽는 방식입니다. 수정이 훨씬 쉽습니다.

1. `tools/art/girlfriend_idle.txt` 를 메모장으로 연다 (32줄 × 32글자)
2. 글자를 바꾼다 — 글자 하나 = 픽셀 하나

   | 글자 | 색 |
   |---|---|
   | `.` | 투명 |
   | `o` | 외곽선(진한 초록) |
   | `G` `g` `d` `D` | 밝은/중간/어두운/가장 어두운 초록 |
   | `B` `b` | 배(크림색) |
   | `W` | 흰색 (눈·앞니) |
   | `K` | 검정 (눈동자) |
   | `P` | 분홍 볼 |
   | `Y` | 안경테 |
   | `N` `n` | 남색 조끼 / 벨트 |
   | `R` `r` | 하트 빨강 |

   색을 추가하고 싶으면 `tools/art/_palette.txt` 에 `글자 RRGGBB` 한 줄 추가.

3. 아래 명령으로 다시 굽는다

```bash
powershell -ExecutionPolicy Bypass -File tools\generate_sprites.ps1
```

4. `tools/preview.png` 로 확인 → Godot 에디터로 돌아가면 자동 반영됩니다.

> 줄 길이가 다 같아야 합니다. 안 맞으면 그림이 밀립니다.

---

## 7. 알아둘 점 / 다음 단계

### 한글 폰트
Godot의 **기본 폰트에는 한글이 없습니다.** 그래서 지금 화면 안내 문구는 영어입니다.
한글 UI가 필요해지면 무료 한글 픽셀 폰트(예: **Galmuri**, OFL 라이선스)를 받아
`assets/fonts/` 에 넣고 프로젝트 설정의 기본 테마 폰트로 지정하면 됩니다.
웹 배포까지 생각하면 **라이선스가 재배포를 허용하는 폰트**를 골라야 합니다.

### 아이폰 사파리 대비 (이미 반영해 둔 것)
- 렌더러를 `gl_compatibility` 로 설정 → iOS Safari의 WebGL2 에서 안정적
- 텍스처 필터를 `Nearest` 로 설정 → 픽셀이 뿌옇게 번지지 않음
- 화면 스트레치 `viewport` + `expand` → 기종별 화면 비율 대응

> 아직 안 한 것: **터치 조작**. 지금은 키보드 전용이라 아이폰에서는 움직일 수 없습니다.
> 다음 단계에서 화면 조이스틱이나 미니게임별 탭 조작을 넣어야 합니다.

### 앞으로 붙일 것 (아직 없음)
- `scripts/core/game_state.gd` — 어떤 기억이 해금됐는지 관리 (Autoload)
- `scenes/ui/dialogue_box.tscn` — 대화창
- `scenes/minigames/*.tscn` — 미니게임 8~10개
- 저장 시스템 (`user://` 에 JSON)

---

## 8. Git

아직 커밋이 하나도 없는 상태입니다. 시작하려면:

```bash
git add . && git commit -m "캐릭터 프로토타입: 두 맹꽁이 + 이동 + 방"
```
