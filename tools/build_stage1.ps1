# ============================================================
#  미니게임 1 「원 투 뿡!」 무대 그림
# ------------------------------------------------------------
#  추억 1 (원투 방구 사건) 의 배경인 깔끔한 욕실과, 컷신에 쓰는
#  작은 이펙트들을 굽습니다.
#
#  실행 (프로젝트 폴더에서):
#     powershell -ExecutionPolicy Bypass -File tools\build_stage1.ps1
#
#  결과 -> assets/sprites/stages/
#     bath_bg.png     480x270  욕실 배경 (미니게임 화면은 스크롤이 없어서
#                              기준 해상도와 딱 같은 크기입니다)
#     fart1~3.png              보라색 방귀 구름 (커지는 3단계)
#     sparkle.png              "빵 터짐" 효과선
#     note_glove/note_face     리듬 파트의 노트 두 종류
#     ring / ring_lit          리듬 파트의 판정 링
# ============================================================

$Root     = Split-Path -Parent $PSScriptRoot
$StageDir = Join-Path $Root 'assets\sprites\stages'
if (-not (Test-Path $StageDir)) { New-Item -ItemType Directory -Force -Path $StageDir | Out-Null }

. (Join-Path $PSScriptRoot '_draw.ps1')

# ---------- 팔레트 ----------
$LINE   = '2B3540'   # 어두운 외곽선 (욕실은 방보다 차가운 색)
$TILE_A = 'DCE6EA'   # 벽 타일
$TILE_B = 'CBD8DE'
$GROUT  = 'AEBEC6'   # 줄눈
$FL_A   = 'B9C7CE'   # 바닥 타일
$FL_B   = 'AABAC2'
$FL_LN  = '8FA1AB'
$WALL_S = 'BFCED4'   # 벽 아래쪽 그늘
$PORC   = 'F7FBFC'   # 도기 (세면대·변기)
$PORC_D = 'D8E4E8'
$CHROME = 'A9B7BF'   # 크롬
$CHROME_L = 'E4EDF1'
$MIRROR = 'AFC9D6'
$MIRROR_L = 'D3E6EE'
$TOWEL  = 'E8A0A8'   # 분홍 수건
$TOWEL_D = 'C77F8C'
$FART_1 = 'C9A5E6'   # 방귀 (밝은 보라)
$FART_2 = 'A87FD1'
$FART_3 = '7E5AA8'
$SPARK  = 'FFE9A8'

Write-Output 'assets/sprites/stages/'

# ============================================================
#  bath_bg.png - 480x270
#  위 절반은 타일 벽, 아래는 타일 바닥. 왼쪽에 세면대와 거울,
#  오른쪽에 샤워기. 가운데는 두 캐릭터가 설 자리라 비워 둡니다.
# ============================================================
$W = 640; $H = 270; $WALL_H = 168
# 아이폰처럼 화면이 더 넓어도 욕실 밖이 안 보이도록 640 으로 그리고,
# 씬에서 x = -80 에 놓아 가운데 480 이 기준 화면과 맞게 합니다.
$OX = 80
Start-Img $W $H

# --- 벽 타일 (32x24 격자)
Fill 0 0 $W $WALL_H $TILE_A
for ($y = 0; $y -lt $WALL_H; $y += 24) {
    for ($x = 0; $x -lt $W; $x += 32) {
        if ((($x / 32) + ($y / 24)) % 2 -eq 0) { Fill $x $y 32 24 $TILE_B }
    }
    Fill 0 ($y + 23) $W 1 $GROUT
}
for ($x = 0; $x -lt $W; $x += 32) { Fill $x 0 1 $WALL_H $GROUT }
# 바닥과 만나는 곳은 조금 어둡게
Fill 0 ($WALL_H - 16) $W 16 $WALL_S
Fill 0 ($WALL_H - 16) $W 1 $GROUT

# --- 바닥 타일 (원근 없이 방과 같은 방식)
$row = 0
for ($y = $WALL_H; $y -lt $H; $y += 16) {
    if ($row % 2 -eq 0) { $c = $FL_A } else { $c = $FL_B }
    Fill 0 $y $W 15 $c
    Fill 0 ($y + 15) $W 1 $FL_LN
    $off = @(0, 24)[$row % 2]
    for ($x = $off; $x -lt $W; $x += 48) { Fill $x $y 1 15 $FL_LN }
    $row++
}
Fill 0 $WALL_H $W 4 '9FB0B8'          # 벽 밑 그림자

# --- 거울 (왼쪽 위)
Box (26 + $OX) 26 84 62 $MIRROR $LINE
Fill (30 + $OX) 30 76 26 $MIRROR_L    # 유리 반사
Fill (30 + $OX) 62 34 4 $MIRROR_L
Fill (24 + $OX) 86 88 4 $CHROME       # 거울 선반

# --- 세면대
Box (34 + $OX) 100 68 14 $PORC $LINE  # 상판
Box (44 + $OX) 112 48 16 $PORC_D $LINE # 기둥
Fill (62 + $OX) 96 6 8 $CHROME        # 수도꼭지
Fill (60 + $OX) 94 12 3 $CHROME_L
Fill (56 + $OX) 100 4 4 $CHROME       # 손잡이
Fill (76 + $OX) 100 4 4 $CHROME

# --- 수건걸이 (가운데 왼쪽)
Fill (150 + $OX) 40 3 34 $CHROME
Fill (194 + $OX) 40 3 34 $CHROME
Fill (150 + $OX) 40 47 3 $CHROME
Box (156 + $OX) 46 34 40 $TOWEL $LINE # 분홍 수건
Fill (160 + $OX) 50 26 3 $TOWEL_D
Fill (160 + $OX) 62 26 3 $TOWEL_D

# --- 샤워기 (오른쪽)
Fill (404 + $OX) 22 4 26 $CHROME
Fill (386 + $OX) 46 40 8 $CHROME
Fill (388 + $OX) 54 36 4 $CHROME_L
for ($x = 392 + $OX; $x -lt 424 + $OX; $x += 6) { Fill $x 58 2 3 $CHROME }
Box (398 + $OX) 150 64 4 $CHROME $LINE  # 샤워 부스 턱
Fill (340 + $OX) 26 4 142 $GROUT      # 유리 칸막이 선
Fill (344 + $OX) 26 116 4 $GROUT

Save-Img $StageDir 'bath_bg'

# ============================================================
# ============================================================
# ============================================================
#  fart1~3.png - 만화식 방귀 구름. 세 장을 순서대로 보여주면 퍼집니다.
#
#  방귀로 읽히게 하는 건 이 셋입니다.
#    1. 크기가 다른 동그라미 여섯 개를 겹친 울퉁불퉁한 뭉게구름
#    2. 나온 자리로 이어지는 [b]꼬리[/b] - 말풍선 꼬리처럼 점점 가늘어짐
#    3. 전체를 한 번에 두르는 1px 외곽선 (Edge)
#
#  ★ 꼬리 끝은 [b]세 장 모두 오른쪽 아래에서 (6, 6) 픽셀[/b]에 있습니다.
#    구름이 커져도 그 점은 안 움직입니다. 씬 쪽에서 스프라이트 offset 을
#    (6 - w/2, 6 - h/2) 로 잡으면 노드 위치가 곧 꼬리 끝이 되어,
#    구름이 세 단계로 부풀어도 똥꼬에서 안 떨어집니다.
#    (예전에는 가운데를 기준으로 놓고 매번 손으로 밀었는데, 크기가 커질수록
#     어긋났습니다)
#
#  ★ 덩어리는 캔버스 안쪽 2px 를 비우고 그립니다. Edge 가 바깥으로 1px 을
#    더 그리므로, 가장자리까지 꽉 채우면 외곽선이 잘립니다.
# ============================================================
$FART_O = '3A2255'   # 외곽선
$PAD = 3             # 사방 여백 (외곽선 + 여유)

# 구름 덩어리 (cx, cy, rx, ry) - 여백을 뺀 안쪽 상자에 대한 비율.
# 꼬리가 오른쪽 아래로 나가므로 구름은 왼쪽 위에 몰려 있습니다.
$LOBES = @(
    @(0.28, 0.34, 0.24, 0.29),
    @(0.51, 0.25, 0.22, 0.24),
    @(0.70, 0.40, 0.21, 0.25),
    @(0.43, 0.55, 0.24, 0.28),
    @(0.16, 0.53, 0.15, 0.21),
    @(0.62, 0.62, 0.16, 0.20)
)

$sizes = @(
    @{ n = 'fart1'; w = 46; h = 36 },
    @{ n = 'fart2'; w = 70; h = 54 },
    @{ n = 'fart3'; w = 98; h = 74 }
)
foreach ($f in $sizes) {
    $w = $f.w; $h = $f.h
    $iw = $w - 2 * $PAD; $ih = $h - 2 * $PAD
    # 꼬리: 끝점은 항상 오른쪽 아래에서 (6,6). 구름이 커져도 안 움직입니다.
    # 배열 원소마다 괄호가 필요합니다 - 안 그러면 PowerShell 이 쉼표를 먼저
    # 묶어서 "배열 * 숫자" 로 읽고 op_Multiply 에러를 냅니다.
    $tipx = $w - 6.0; $tipy = $h - 6.0
    $tail = @(
        @(($tipx - $w * 0.22), ($tipy - $h * 0.28), (5.0 + $w * 0.045)),
        @(($tipx - $w * 0.10), ($tipy - $h * 0.13), (3.5 + $w * 0.030)),
        @($tipx, $tipy, (2.0 + $w * 0.020))
    )

    Start-Img $w $h
    foreach ($t in $tail) {
        Oval ($t[0] - $t[2]) ($t[1] - $t[2] * 1.15) ($t[2] * 2) ($t[2] * 2.3) $FART_2
    }
    foreach ($l in $LOBES) {
        Oval ($PAD + $iw * $l[0] - $iw * $l[2]) ($PAD + $ih * $l[1] - $ih * $l[3]) `
            ($iw * $l[2] * 2) ($ih * $l[3] * 2) $FART_2
    }
    # 같은 모양을 조금 작게, 왼쪽 위로 밀어서 밝은 색으로 덮습니다.
    # 남는 오른쪽 아래 테두리가 곧 그늘이 됩니다.
    foreach ($l in $LOBES) {
        $cx = $PAD + $iw * $l[0] - $iw * 0.05; $cy = $PAD + $ih * $l[1] - $ih * 0.08
        $rx = $iw * $l[2] * 0.86; $ry = $ih * $l[3] * 0.86
        Oval ($cx - $rx) ($cy - $ry) ($rx * 2) ($ry * 2) $FART_1
    }
    Edge $FART_O
    Save-Img $StageDir $f.n
}
# ============================================================
#  sparkle.png - 32x32. 빵 터졌을 때 튀는 효과선.
# ============================================================
Start-Img 32 32
foreach ($a in @(0, 45, 90, 135, 180, 225, 270, 315)) {
    $r = [math]::PI * $a / 180.0
    for ($d = 7; $d -le 14; $d++) {
        $x = [int](16 + [math]::Cos($r) * $d)
        $y = [int](16 + [math]::Sin($r) * $d)
        Fill $x $y 2 2 $SPARK
    }
}
Save-Img $StageDir 'sparkle'

# ============================================================
#  리듬 파트용 그림
# ------------------------------------------------------------
#  note_glove.png  28x28  좌/우 노트 (원 · 투)
#  note_face.png   28x28  위 노트 (뿡) - 맹순이의 부끄러운 얼굴
#  ring.png        40x40  판정 링 (좌 · 상 · 우 세 군데에 놓입니다)
#  ring_lit.png    40x40  맞았을 때 잠깐 갈아 끼우는 밝은 링
#
#  노트는 28px 안에서 한눈에 읽혀야 해서 캐릭터 그림을 줄이지 않고
#  아이콘으로 새로 그립니다. 64x64 얼굴을 반으로 줄이면 눈이 뭉개집니다.
# ============================================================
$GL     = 'E05A52'   # 글러브 빨강
$GL_D   = 'B33F3C'
$GL_L   = 'F58C7E'
$GL_O   = '4A1614'
$LACE   = 'F2E6CC'
$LACE_D = 'B79B72'
$FROG   = '5FAE3C'
$FROG_L = '7FCB59'
$FROG_O = '22331C'
$JAW    = 'F6E792'
$FLUSH  = 'FF7A7A'
$FLUSH_D = 'E05555'
$BOW    = 'FFC2D4'
$BOW_D  = 'F09BB5'
$RING   = 'FFF3D2'
$RING_D = '8C7CB0'
$RING_H = 'FFE06B'

# ---------- note_glove.png ----------
Start-Img 28 28
Oval 2 1 24 22 $GL_O                 # 외곽선 (1px 크게 그린 같은 모양)
Oval 3 2 22 20 $GL
Fill 5 4 10 5 $GL_L                  # 왼쪽 위 하이라이트
Oval 3 12 22 10 $GL_D                # 아래쪽 그늘
Oval 3 2 22 16 $GL
Oval 4 13 20 8 $GL_D
Oval 0 8 9 12 $GL_O                  # 엄지
Oval 1 9 7 10 $GL
Box 7 20 14 7 $LACE $GL_O            # 손목 밴드
Fill 9 22 10 1 $LACE_D
Fill 13 20 2 7 $LACE_D               # 끈
Save-Img $StageDir 'note_glove'

# ---------- note_face.png ----------
Start-Img 28 28
Oval 1 4 26 22 $FROG_O
Oval 2 5 24 20 $FROG
Fill 4 6 17 4 $FROG_L
Oval 4 16 20 9 $JAW                  # 크림색 턱
Fill 4 13 5 4 $FLUSH_D               # 달아오른 볼
Fill 19 13 5 4 $FLUSH_D
Fill 9 14 10 2 $FLUSH                # 콧등을 가로지르는 홍조
Fill 5 10 6 2 $FROG_O                # 감은 눈 (얇은 실선 두 줄)
Fill 6 12 4 1 $FROG_O
Fill 17 10 6 2 $FROG_O
Fill 18 12 4 1 $FROG_O
Fill 12 20 4 2 $FROG_O               # 오므린 입
Fill 8 1 12 5 $BOW                   # 머리 리본
Fill 12 2 4 3 $BOW_D
Fill 8 4 12 2 $BOW_D
Save-Img $StageDir 'note_face'
# ---------- ring.png / ring_lit.png ----------
foreach ($v in @(@{ n = 'ring'; c = $RING; d = $RING_D }, @{ n = 'ring_lit'; c = $RING_H; d = $RING })) {
    Start-Img 40 40
    Oval 0 0 40 40 $v.d
    Oval 2 2 36 36 $v.c
    Oval 5 5 30 30 $v.d
    Hole 7 7 26 26
    Save-Img $StageDir $v.n
}
