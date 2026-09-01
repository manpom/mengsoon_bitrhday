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
$WOOD   = '9C7550'
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

# --- 나무 발매트 (가운데 아래, 두 사람이 설 자리 표시)
Box (168 + $OX) 214 148 20 $WOOD "6B4A31"
for ($x = 174 + $OX; $x -lt 312 + $OX; $x += 12) { Fill $x 218 6 12 "85603F" }

Save-Img $StageDir 'bath_bg'

# ============================================================
#  fart1~3.png - 보라색 방귀 구름. 세 장을 순서대로 보여주면
#  퍼지는 것처럼 보입니다.
# ============================================================
$sizes = @(
    @{ n = 'fart1'; w = 26; h = 20; s = 0.55 },
    @{ n = 'fart2'; w = 40; h = 30; s = 0.80 },
    @{ n = 'fart3'; w = 56; h = 42; s = 1.00 }
)
foreach ($f in $sizes) {
    Start-Img $f.w $f.h
    $cx = $f.w / 2.0; $cy = $f.h / 2.0; $k = $f.s
    # 겹친 동그라미 세 겹으로 뭉게구름
    Oval ($cx - 13 * $k) ($cy - 8 * $k) (26 * $k) (17 * $k) $FART_3
    Oval ($cx - 2 * $k) ($cy - 13 * $k) (22 * $k) (18 * $k) $FART_3
    Oval ($cx - 20 * $k) ($cy - 1 * $k) (20 * $k) (15 * $k) $FART_3
    Oval ($cx - 11 * $k) ($cy - 6 * $k) (22 * $k) (14 * $k) $FART_2
    Oval ($cx - 1 * $k) ($cy - 10 * $k) (18 * $k) (14 * $k) $FART_2
    Oval ($cx - 17 * $k) ($cy + 1 * $k) (16 * $k) (11 * $k) $FART_2
    Oval ($cx - 8 * $k) ($cy - 4 * $k) (14 * $k) (9 * $k) $FART_1
    Oval ($cx + 1 * $k) ($cy - 7 * $k) (10 * $k) (8 * $k) $FART_1
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
