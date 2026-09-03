# ============================================================
#  UI 아이콘 — 디오라마 버전
# ------------------------------------------------------------
#     powershell -ExecutionPolicy Bypass -File tools\build_ui_soft.ps1
#
#  결과 -> assets/sprites/ui/
#     prompt.png        48x58  하얀 느낌표  = 그냥 둘러볼 수 있는 것
#     prompt_story.png  48x58  노란 느낌표  = 이야기가 진행되는 것 (미니게임)
#     tap.png           64x32  찍은 자리에 뜨는 동그라미
#
#  ★ 예전 도트판(build_room.ps1 안에 있었습니다)을 대체합니다. 크기가 2배입니다.
#
#  ★ 새 스타일에는 외곽선이 없습니다. 그런데 UI 마커는 어떤 배경 위에도
#    올라가므로 무언가로 떠 있어야 합니다. 선 대신 [b]부드러운 그림자[/b]로
#    띄웁니다. 선을 두르면 이 화면에서 혼자만 도트처럼 보입니다.
# ============================================================

. (Join-Path $PSScriptRoot '_soft.ps1')

$Root = Split-Path -Parent $PSScriptRoot
$UiDir = Join-Path $Root 'assets\sprites\ui'
if (-not (Test-Path $UiDir)) { New-Item -ItemType Directory -Force -Path $UiDir | Out-Null }

Write-Output 'assets/sprites/ui/'

# ---------- 느낌표 말풍선 ----------
function Draw-Prompt([string]$fill, [string]$lit, [string]$shade, [string]$ink) {
    New-Soft 48 58
    # 꼬리 먼저 (몸통이 이음매를 덮습니다)
    $tail = BlobPath @((Pt 17 34), (Pt 30 34), (Pt 23 52)) 0.2
    DropShadow $tail 0 3 '#3A2C22' 0.22 5
    FillPath $tail $shade
    $body = RoundRectPath 4 3 40 36 15
    DropShadow $body 0 3 '#3A2C22' 0.22 6
    FillPath $body $fill
    ShadeTopOnly $body $lit 19 14
    # 느낌표
    FillPath (RoundRectPath 21 10 6 15 3) $ink
    FillPath (EllipsePath 24 30 3.4 3.4) $ink
}

Draw-Prompt '#FBF3E2' '#FFFFFF' '#E7DCC6' '#6B5344'
Save-Soft (Join-Path $UiDir 'prompt.png')

Draw-Prompt '#FFD87E' '#FFEFC0' '#E9BC57' '#6B4A21'
Save-Soft (Join-Path $UiDir 'prompt_story.png')

# ============================================================
#  tap.png — 걸어갈 자리를 찍었을 때 잠깐 뜨는 동그라미
#  바닥에 놓인 것이므로 [b]눌린 타원[/b]입니다. 정원으로 그리면
#  화면에 붙은 스티커처럼 보여서 바닥으로 안 읽힙니다.
# ============================================================
New-Soft 64 32
StrokePath (EllipsePath 32 16 27 12) '#F6EBD0' 5
StrokePath (EllipsePath 32 16 18 8) '#F6EBD0' 3
Save-Soft (Join-Path $UiDir 'tap.png')
