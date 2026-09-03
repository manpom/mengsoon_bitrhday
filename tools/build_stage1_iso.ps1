# ============================================================
#  미니게임 1 「원 투 뿡!」 무대 — 디오라마 버전
# ------------------------------------------------------------
#     powershell -ExecutionPolicy Bypass -File tools\build_stage1_iso.ps1
#
#  결과 -> assets/sprites/stages/
#     bath_bg.png      1280x660  욕실 (방과 [b]똑같은 카메라[/b]로 그립니다)
#     fart1~3.png                방귀 구름 3단계
#     sparkle.png                빵 터짐 효과
#     note_glove / note_face     리듬 파트 노트
#     ring / ring_lit            리듬 파트 판정 링
#  미리보기 -> tools/bath_iso_preview.png
#
#  ★ 예전 도트판(build_stage1.ps1)을 대체합니다. 그쪽은 480x270 기준입니다.
#
#  ★ 카메라를 방과 똑같이 둡니다. 컷신은 방에서 곧바로 이어지는데
#    시점이 달라지면 다른 세계로 순간이동한 것처럼 보입니다.
#
#  ★ 화면 배치: 씬에서 배경을 (-40, -100) 에 놓습니다. 그러면 기준 화면
#    960x540 에 그림의 x 40~1000, y 100~640 이 보입니다. 캔버스를 1280 으로
#    넉넉히 잡은 것은 아이폰(19.5:9)처럼 화면이 더 넓을 때 좌우로 욕실이
#    계속 이어져 보이게 하기 위해서입니다.
# ============================================================

. (Join-Path $PSScriptRoot '_iso.ps1')

$Root = Split-Path -Parent $PSScriptRoot
$StageDir = Join-Path $Root 'assets\sprites\stages'
if (-not (Test-Path $StageDir)) { New-Item -ItemType Directory -Force -Path $StageDir | Out-Null }

Set-Camera 648.0 0.54 0.18 30.0

Write-Output 'assets/sprites/stages/'

# ---------- 팔레트 ----------
# 방은 따뜻한 크림색, 욕실은 [b]차가운 민트-회청색[/b]입니다.
# 같은 파스텔 톤·같은 채도라 두 화면이 한 세계로 묶이면서도,
# 장소가 바뀐 것은 색온도만으로 바로 읽힙니다.
$B3 = @{
    floorT    = '#D8E5E3'; floorSeam = '#B2C8C6'
    wallBack  = '#E2EDEB'; wallLeft = '#D2E1E0'; wallTop = '#F4FAF9'
    tileF     = '#C0D7D6'; tileS = '#ABC6C7'
    skirtF    = '#D3E1E0'; skirtS = '#BCCECE'

    porcT     = '#FBFDFD'; porcF = '#E9F1F2'; porcS = '#CFDDDF'
    tubIn     = '#CBE1E8'; tubInS = '#AFCAD4'

    chromeT   = '#EAF0F3'; chromeF = '#C0CBD2'; chromeS = '#A2AFB7'
    mirrorT   = '#C9E0EA'; mirrorL = '#E8F5F9'

    woodT     = '#DCBB93'; woodF = '#C39B72'; woodS = '#AA855F'

    towelAT   = '#F6C2C8'; towelAF = '#E2A3AC'; towelAS = '#CC8E98'
    towelBT   = '#BFDDD3'; towelBF = '#A2C2B8'; towelBS = '#8DAEA5'

    matT      = '#EBD1D6'; matIn = '#D5B4BC'

    leafT     = '#A6CB9F'; leafF = '#86AF85'
    potT      = '#DFAC92'; potF = '#C39079'; potS = '#AB7D69'

    duckT     = '#FFDD86'
    botAT     = '#BCCFE3'; botAF = '#9FB5CE'
    botBT     = '#EDBEC5'; botBF = '#D4A3AC'

    skyTop    = '#D6E7F2'; skyLow = '#F3E4CC'
}

$W = 1280; $H = 660
New-Soft $W $H

# 바깥 여백 (방과 같은 처리 — 모형을 책상에 올려놓고 내려다보는 느낌)
FillPath (RoundRectPath 0 0 $W $H 0) '#E4EDEB'
GroundShadow ($W / 2.0) ($H * 0.46) ($W * 0.60) ($H * 0.62) '#F6FBFA' 0.95

# ============================================================
#  욕실 껍데기: 왼쪽 벽 · 뒷벽 · 바닥
# ============================================================
$RX0 = 0.0; $RX1 = 1180.0; $RZ0 = -40.0; $RZ1 = 300.0
$WALLH = 430.0
$TILEH = 180.0          # 허리 높이 타일. 위쪽은 그냥 칠한 벽입니다

# ---------- 바닥 ----------
$floor = FaceTop $RX0 $RZ0 $RX1 $RZ1 0
FillPath $floor $B3.floorT
# 욕실 바닥은 널판이 아니라 [b]정사각 타일[/b]입니다.
# 깊이 줄과 가로 줄을 같은 간격으로 그으면 바로 욕실로 읽힙니다.
for ($z = $RZ0; $z -le $RZ1; $z += 68) {
    $a = P3 $RX0 $z 0; $b = P3 $RX1 $z 0
    $pen = New-Object System.Drawing.Pen((CA $B3.floorSeam 0.75), 2.5)
    $script:SG.DrawLine($pen, $a, $b); $pen.Dispose()
}
for ($x = $RX0; $x -le $RX1; $x += 68) {
    $a = P3 $x $RZ0 0; $b = P3 $x $RZ1 0
    $pen = New-Object System.Drawing.Pen((CA $B3.floorSeam 0.55), 2.5)
    $script:SG.DrawLine($pen, $a, $b); $pen.Dispose()
}
PushClip $floor
GroundShadow (P3 560 $RZ1 0).X (P3 560 $RZ1 0).Y 900 130 '#5E7377' 0.20
PopClip

# ---------- 뒷벽 / 왼쪽 벽 ----------
$back = FaceFront $RX0 $RX1 $RZ1 0 $WALLH
FillPath $back $B3.wallBack
FaceLight $back $B3.wallTop 0.32
$left = FaceSide $RX0 $RZ0 $RZ1 0 $WALLH
FillPath $left $B3.wallLeft
FaceLight $left '#F1F8F7' 0.4

# ---------- 허리 타일 ----------
# 벽 전체를 타일로 채우면 줄눈이 너무 많아 화면이 시끄러워집니다.
# 아래쪽만 타일, 위쪽은 무지 — 실제 욕실도 대개 이렇게 생겼습니다.
FillPath (FaceFront $RX0 $RX1 $RZ1 0 $TILEH) $B3.tileF
FillPath (FaceSide $RX0 $RZ0 $RZ1 0 $TILEH) $B3.tileS
for ($x = $RX0; $x -le $RX1; $x += 76) {
    $a = P3 $x $RZ1 0; $b = P3 $x $RZ1 $TILEH
    $pen = New-Object System.Drawing.Pen((CA '#A9C4C5' 0.55), 2.5)
    $script:SG.DrawLine($pen, $a, $b); $pen.Dispose()
}
foreach ($hh in @(60.0, 120.0)) {
    $a = P3 $RX0 $RZ1 $hh; $b = P3 $RX1 $RZ1 $hh
    $pen = New-Object System.Drawing.Pen((CA '#A9C4C5' 0.55), 2.5)
    $script:SG.DrawLine($pen, $a, $b); $pen.Dispose()
    $c = P3 $RX0 $RZ0 $hh; $d = P3 $RX0 $RZ1 $hh
    $pen2 = New-Object System.Drawing.Pen((CA '#98B6B8' 0.5), 2.5)
    $script:SG.DrawLine($pen2, $c, $d); $pen2.Dispose()
}
# 타일 맨 윗줄 마감 — 걸레받이를 거꾸로 올린 것이 곧 타일 끝선입니다
FillPath (FaceFront $RX0 $RX1 $RZ1 $TILEH ($TILEH + 12)) $B3.skirtF
FillPath (FaceSide $RX0 $RZ0 $RZ1 $TILEH ($TILEH + 12)) $B3.skirtS

# ---------- 구석 어둠 ----------
CornerDark $back '#4E6B70' 0.28 (P3 0 $RZ1 0).X (P3 0 $RZ1 0).Y 300 460
CornerDark $left '#4E6B70' 0.24 (P3 $RX0 $RZ1 0).X (P3 $RX0 $RZ1 0).Y 200 420
PushClip $floor
GroundShadow (P3 $RX0 100 0).X (P3 $RX0 100 0).Y 220 380 '#4E6B70' 0.18
PopClip

# ============================================================
#  창문 (뒷벽 · 불투명 유리)
# ------------------------------------------------------------
#  방의 창과 같은 역할입니다. [b]빛이 어디서 오는지[/b]를 정해 주면
#  그림자를 전부 앞쪽으로 깔 명분이 생깁니다.
#  불투명 유리로 처리하면 바깥 풍경을 안 그려도 되어 화면이 조용해집니다.
# ============================================================
$winL = 340.0; $winR = 500.0; $winB = 240.0; $winT = 380.0
FillPath (FaceFront ($winL - 12) ($winR + 12) $RZ1 ($winB - 12) ($winT + 12)) $B3.porcT
$glass = FaceFront $winL $winR $RZ1 $winB $winT
FillPath $glass $B3.skyTop
$gc = P3 (($winL + $winR) / 2) $RZ1 $winB
PushClip $glass
GroundShadow $gc.X $gc.Y 130 90 $B3.skyLow 0.9
PopClip
for ($hh = $winB + 14; $hh -lt $winT; $hh += 22) {
    $a = P3 $winL $RZ1 $hh; $b = P3 $winR $RZ1 $hh
    $pen = New-Object System.Drawing.Pen((CA '#FFFFFF' 0.45), 6)
    $script:SG.DrawLine($pen, $a, $b); $pen.Dispose()
}
$wmid = ($winL + $winR) / 2
FillPath (FaceFront ($wmid - 4) ($wmid + 4) $RZ1 $winB $winT) $B3.porcT

# ============================================================
#  욕조 (왼쪽)
# ============================================================
# ★ 욕조가 [b]상자[/b]로 보이지 않게 하는 것이 전부입니다. 필요한 건 셋입니다.
#   1. 낮고 깊게 (높이 150, 앞으로 길게) — 높으면 조리대처럼 보입니다
#   2. 턱 안쪽 네 면 전부에 그늘 — 한쪽만 넣으면 그냥 얼룩으로 보입니다
#   3. 물이 고이는 바닥은 턱보다 확실히 어두운 색
$tX0 = 20.0; $tX1 = 300.0; $tZ0 = 118.0; $tZ1 = 300.0; $tH = 150.0
CastShadow $tX0 $tZ0 $tX1 $tZ1 $tH 0.16
Contact $tX0 $tZ0 $tX1 $tZ1 0.32
Box3 $tX0 $tZ0 $tX1 $tZ1 0 $tH $B3.porcT $B3.porcF $B3.porcS | Out-Null
# 안쪽으로 파인 물통. 윗면 위에 한 겹 더 얹어서 "파였다"를 만듭니다.
$bX0 = $tX0 + 24; $bX1 = $tX1 - 24; $bZ0 = $tZ0 + 20; $bZ1 = $tZ1 - 20
$basin = FaceTop $bX0 $bZ0 $bX1 $bZ1 $tH
FillPath $basin $B3.tubIn
foreach ($cn in @(@($bX1, $bZ1, 170.0, 70.0, 0.55), @($bX0, $bZ1, 90.0, 70.0, 0.40),
        @($bX1, $bZ0, 120.0, 50.0, 0.30), @($bX0, $bZ0, 80.0, 45.0, 0.22))) {
    $cp = P3 $cn[0] $cn[1] $tH
    CornerDark $basin '#6E96A2' $cn[4] $cp.X $cp.Y $cn[2] $cn[3]
}
# 앞쪽 턱의 두께 — 이 한 줄이 "안이 비어 있다"를 말해 줍니다
FillPath (FaceFront $bX0 $bX1 $bZ0 ($tH - 22) $tH) $B3.tubInS
$drain = P3 (($bX0 + $bX1) / 2) (($bZ0 + $bZ1) / 2 + 14) $tH
FillPath (EllipsePath $drain.X $drain.Y 13 7) $B3.chromeF

# 수도꼭지 + 샤워기 (뒷벽)
$fx = 130.0
FillPath (FaceFront ($fx - 9) ($fx + 9) $RZ1 $tH ($tH + 46)) $B3.chromeF
FillPath (FaceFront ($fx - 22) ($fx + 4) $RZ1 ($tH + 30) ($tH + 42)) $B3.chromeT
FillPath (FaceFront ($fx - 5) ($fx + 5) $RZ1 330 372) $B3.chromeS
$sh = P3 $fx $RZ1 330
FillPath (EllipsePath $sh.X $sh.Y 30 16) $B3.chromeF
FillPath (EllipsePath $sh.X ($sh.Y - 5) 26 12) $B3.chromeT

# 욕조 턱 위의 소품 — 오리 한 마리와 통 두 개면 충분합니다
$dk = P3 250 ($tZ0 + 11) $tH
FillPath (EllipsePath $dk.X ($dk.Y - 16) 24 18) $B3.duckT
FillPath (EllipsePath ($dk.X - 14) ($dk.Y - 34) 14 13) $B3.duckT
ShadeTopOnly (EllipsePath $dk.X ($dk.Y - 16) 24 18) '#FFF0BE' ($dk.X - 8) ($dk.Y - 26)
FillPath (EllipsePath ($dk.X - 26) ($dk.Y - 36) 7 5) '#F09A55'
FillPath (EllipsePath ($dk.X - 17) ($dk.Y - 38) 2.6 2.6) '#4A3A2A'
Cyl3 60 ($tZ0 + 12) 20 $tH ($tH + 62) $B3.botAT $B3.botAT $B3.botAF
Cyl3 105 ($tZ0 + 12) 17 $tH ($tH + 48) $B3.botBT $B3.botBT $B3.botBF

# ============================================================
#  수건걸이 (뒷벽 가운데)
#  ★ 높이 200 아래로는 내려오지 않습니다. 두 사람 머리 꼭대기가
#    화면 y=364 근처인데, 수건이 거기까지 내려오면 얼굴에 겹칩니다.
# ============================================================
FillPath (FaceFront 540 680 $RZ1 352 360) $B3.chromeF
foreach ($tw in @(@(560.0, 604.0, $B3.towelAT, $B3.towelAF, $B3.towelAS, 208.0),
        @(618.0, 664.0, $B3.towelBT, $B3.towelBF, $B3.towelBS, 232.0))) {
    FillPath (FaceFront $tw[0] $tw[1] $RZ1 $tw[5] 358) $tw[3]
    FillPath (FaceFront $tw[0] ($tw[0] + 11) $RZ1 $tw[5] 358) $tw[4]
    FillPath (FaceFront $tw[0] $tw[1] $RZ1 340 358) $tw[2]
    FillPath (FaceFront $tw[0] $tw[1] $RZ1 ($tw[5] + 26) ($tw[5] + 34)) $tw[4]
}

# ============================================================
#  세면대 + 거울 (오른쪽)
# ============================================================
$sX0 = 660.0; $sX1 = 900.0; $sZ0 = 232.0; $sZ1 = 300.0; $sH = 170.0
CastShadow $sX0 $sZ0 $sX1 $sZ1 $sH 0.16
Contact $sX0 $sZ0 $sX1 $sZ1 0.30
Box3 $sX0 $sZ0 $sX1 $sZ1 0 ($sH - 22) $B3.woodT $B3.woodF $B3.woodS | Out-Null
Box3 ($sX0 - 10) ($sZ0 - 8) ($sX1 + 10) $sZ1 ($sH - 22) $sH $B3.porcT $B3.porcF $B3.porcS | Out-Null
# 세면 볼
$bw = P3 (($sX0 + $sX1) / 2) ((($sZ0 + $sZ1) / 2) - 4) $sH
FillPath (EllipsePath $bw.X $bw.Y 78 42) $B3.porcS
FillPath (EllipsePath $bw.X ($bw.Y - 3) 70 36) $B3.tubIn
FillPath (EllipsePath $bw.X ($bw.Y + 6) 12 7) $B3.chromeF
# 서랍 손잡이 두 개 (앞면이 허전하지 않게)
foreach ($hx in @(722.0, 838.0)) {
    $hp = P3 $hx $sZ0 100
    FillPath (RoundRectPath ($hp.X - 26) ($hp.Y - 5) 52 10 5) $B3.chromeF
}
# 수전
$scx = ($sX0 + $sX1) / 2
FillPath (FaceFront ($scx - 8) ($scx + 8) $RZ1 $sH ($sH + 52)) $B3.chromeF
FillPath (FaceFront ($scx - 8) ($scx + 26) $RZ1 ($sH + 40) ($sH + 52)) $B3.chromeT
# 칫솔 컵
Cyl3 690 ($sZ0 + 24) 22 $sH ($sH + 46) $B3.towelBT $B3.towelBT $B3.towelBF
foreach ($br in @(@(-8.0, $B3.towelAT), @(7.0, $B3.botAT))) {
    $bp = P3 (690 + $br[0]) ($sZ0 + 24) ($sH + 46)
    FillPath (RoundRectPath ($bp.X - 4) ($bp.Y - 30) 8 34 4) $br[1]
}
# 거울
$mL = 690.0; $mR = 870.0; $mB = 210.0; $mT = 350.0
FillPath (FaceFront ($mL - 10) ($mR + 10) $RZ1 ($mB - 10) ($mT + 10)) $B3.porcT
$mir = FaceFront $mL $mR $RZ1 $mB $mT
FillPath $mir $B3.mirrorT
$ml2 = P3 ($mL + 40) $RZ1 ($mT - 30)
PushClip $mir
GroundShadow $ml2.X $ml2.Y 110 80 $B3.mirrorL 0.95
PopClip
FillPath (FaceFront ($mL + 18) ($mL + 40) $RZ1 ($mB + 22) ($mT - 18)) $B3.mirrorL

# ============================================================
#  바닥 소품
# ============================================================
# 발매트 — 두 사람이 이 위에 섭니다
$mx0 = 300.0; $mx1 = 620.0; $mz0 = 120.0; $mz1 = 250.0
Contact $mx0 $mz0 $mx1 $mz1 0.16
FillPath (FaceTop $mx0 $mz0 $mx1 $mz1 3) $B3.matT
FillPath (FaceTop ($mx0 + 22) ($mz0 + 16) ($mx1 - 22) ($mz1 - 16) 3.5) $B3.matIn
FillPath (FaceTop ($mx0 + 38) ($mz0 + 28) ($mx1 - 38) ($mz1 - 28) 4) $B3.matT

# 나무 스툴 + 개어 놓은 수건 (왼쪽 앞)
$stX0 = 120.0; $stX1 = 268.0; $stZ0 = 20.0; $stZ1 = 118.0; $stH = 118.0
CastShadow $stX0 $stZ0 $stX1 $stZ1 $stH 0.18
Contact $stX0 $stZ0 $stX1 $stZ1 0.32
foreach ($lg in @(@(($stX0 + 14), ($stZ0 + 14)), @(($stX1 - 14), ($stZ0 + 14)), @(($stX1 - 14), ($stZ1 - 14)))) {
    Cyl3 $lg[0] $lg[1] 9 0 ($stH - 16) $B3.woodT $B3.woodF $B3.woodS
}
Box3 $stX0 $stZ0 $stX1 $stZ1 ($stH - 16) $stH $B3.woodT $B3.woodF $B3.woodS | Out-Null
Box3 ($stX0 + 22) ($stZ0 + 20) ($stX1 - 22) ($stZ1 - 20) $stH ($stH + 30) $B3.towelBT $B3.towelBF $B3.towelBS | Out-Null
Box3 ($stX0 + 28) ($stZ0 + 26) ($stX1 - 28) ($stZ1 - 26) ($stH + 30) ($stH + 56) $B3.towelAT $B3.towelAF $B3.towelAS | Out-Null

# 화분 (오른쪽 앞 구석)
# ★ 작게. 크게 놓으면 세면대 앞을 가로막는 덤불이 되어 버립니다.
#   앞쪽 구석의 소품은 "여백을 채우는 것"이지 주인공이 아닙니다.
$pcx = 900.0; $pcz = 100.0
CastShadow ($pcx - 26) ($pcz - 20) ($pcx + 26) ($pcz + 20) 90 0.16
Contact ($pcx - 26) ($pcz - 20) ($pcx + 26) ($pcz + 20) 0.30
Cyl3 $pcx $pcz 26 0 54 $B3.potT $B3.potF $B3.potS
Cyl3 $pcx $pcz 29 54 68 $B3.potT $B3.potF $B3.potS
$lb = P3 $pcx $pcz 68
foreach ($lf in @(@(-27.0, -24.0, 17.0, 23.0), @(3.0, -44.0, 15.0, 26.0),
        @(27.0, -22.0, 16.0, 22.0), @(-8.0, -14.0, 19.0, 17.0))) {
    FillPath (EllipsePath ($lb.X + $lf[0]) ($lb.Y + $lf[1]) $lf[2] $lf[3]) $B3.leafF
    FillPath (EllipsePath ($lb.X + $lf[0] - 3) ($lb.Y + $lf[1] - 4) ($lf[2] * 0.78) ($lf[3] * 0.78)) $B3.leafT
}

$bathOnly = Take-Soft
$bathOnly.Save((Join-Path $StageDir 'bath_bg.png'), [System.Drawing.Imaging.ImageFormat]::Png)
Write-Output ("  bath_bg.png                  {0}x{1}" -f $bathOnly.Width, $bathOnly.Height)

# ============================================================
#  fart1~3.png — 만화식 방귀 구름 (세 장을 이어 보여주면 퍼집니다)
# ------------------------------------------------------------
#  ★ 꼬리 끝은 세 장 모두 [b]오른쪽 아래에서 (6, 6)[/b] 입니다.
#    씬에서 offset 을 (6 - w/2, 6 - h/2) 로 잡으면 노드 위치가 곧 꼬리 끝이
#    되어, 구름이 부풀어도 똥꼬에서 안 떨어집니다. 크기가 2배로 커져도
#    이 규칙은 그대로라서 컷신 스크립트는 고칠 필요가 없습니다.
#
#  ★ 새 스타일에는 외곽선이 없습니다. 대신 [b]짙은 덩어리 위에 밝은 덩어리를
#    왼쪽 위로 밀어서[/b] 겹칩니다. 남는 오른쪽 아래 테두리가 곧 그늘입니다.
# ============================================================
$FART_L = '#D8BCF0'
$FART_M = '#B392DA'
$PAD = 6

$LOBES = @(
    @(0.28, 0.34, 0.26, 0.31),
    @(0.51, 0.24, 0.24, 0.26),
    @(0.71, 0.40, 0.23, 0.27),
    @(0.43, 0.56, 0.26, 0.30),
    @(0.15, 0.53, 0.17, 0.23),
    @(0.63, 0.63, 0.18, 0.22)
)

foreach ($f in @(@{ n = 'fart1'; w = 92; h = 72 },
        @{ n = 'fart2'; w = 140; h = 108 },
        @{ n = 'fart3'; w = 196; h = 148 })) {
    $fw = [double]$f.w; $fh = [double]$f.h
    $iw = $fw - 2 * $PAD; $ih = $fh - 2 * $PAD
    New-Soft ([int]$f.w) ([int]$f.h)

    # 꼬리 — 말풍선 꼬리처럼 끝으로 갈수록 가늘어집니다
    $tipx = $fw - 6.0; $tipy = $fh - 6.0
    foreach ($t in @(
            @(($tipx - $fw * 0.22), ($tipy - $fh * 0.28), (10.0 + $fw * 0.045)),
            @(($tipx - $fw * 0.10), ($tipy - $fh * 0.13), (7.0 + $fw * 0.030)),
            @($tipx, $tipy, (4.0 + $fw * 0.020)))) {
        FillPath (EllipsePath $t[0] $t[1] $t[2] ($t[2] * 1.15)) $FART_M
    }
    foreach ($l in $LOBES) {
        FillPath (EllipsePath ($PAD + $iw * $l[0]) ($PAD + $ih * $l[1]) ($iw * $l[2]) ($ih * $l[3])) $FART_M
    }
    foreach ($l in $LOBES) {
        FillPath (EllipsePath ($PAD + $iw * $l[0] - $iw * 0.045) ($PAD + $ih * $l[1] - $ih * 0.075) `
            ($iw * $l[2] * 0.86) ($ih * $l[3] * 0.86)) $FART_L
    }
    Save-Soft (Join-Path $StageDir ($f.n + '.png'))
}

# ============================================================
#  sparkle.png — 64x64. 빵 터졌을 때 튀는 효과선
# ============================================================
New-Soft 64 64
foreach ($a in @(0, 45, 90, 135, 180, 225, 270, 315)) {
    $r = [math]::PI * $a / 180.0
    $x0 = 32 + [math]::Cos($r) * 17; $y0 = 32 + [math]::Sin($r) * 17
    $x1 = 32 + [math]::Cos($r) * 29; $y1 = 32 + [math]::Sin($r) * 29
    CurveStroke @((Pt $x0 $y0), (Pt $x1 $y1)) '#FFEBB8' 4.5 0.0
}
FillPath (EllipsePath 32 32 7 7) '#FFF6DC'
Save-Soft (Join-Path $StageDir 'sparkle.png')

# ============================================================
#  리듬 파트 노트 · 판정 링
# ------------------------------------------------------------
#  note_glove.png  56x56  좌/우 노트 (원 · 투)
#  note_face.png   56x56  위 노트 (뿡) — 맹순이의 부끄러운 얼굴
#  ring.png        80x80  판정 링 (좌 · 상 · 우 세 군데)
#  ring_lit.png    80x80  맞았을 때 잠깐 갈아 끼우는 밝은 링
#
#  ★ 노트는 캐릭터 그림을 줄여 쓰지 않고 아이콘으로 새로 그립니다.
#    192px 얼굴을 56 으로 줄이면 눈이 뭉개져서 뭔지 알아볼 수 없습니다.
#
#  ★ 글러브는 [b]손목까지 전부 빨강[/b]입니다. 이음선·바느질선 같은
#    잔선은 넣지 않습니다 (이 크기에서는 때가 낀 것처럼 보입니다).
# ============================================================
New-Soft 56 56
FillPath (EllipsePath 28 24 24 21) '#C97D77'
FillPath (EllipsePath 27 22 22 19) '#E29A92'
ShadeTopOnly (EllipsePath 27 22 22 19) '#F2B6AE' 20 15
FillPath (EllipsePath 7 27 9 11) '#C97D77'
FillPath (EllipsePath 7 26 8 10) '#E29A92'
FillPath (RoundRectPath 13 40 30 15 7) '#C97D77'
FillPath (RoundRectPath 13 39 30 14 7) '#E29A92'
Save-Soft (Join-Path $StageDir 'note_glove.png')

New-Soft 56 56
FillPath (EllipsePath 28 30 25 22) '#84AC83'
FillPath (EllipsePath 28 28 24 21) '#A6CB9F'
ShadeTopOnly (EllipsePath 28 28 24 21) '#C2DEB8' 21 20
FillPath (EllipsePath 28 39 19 11) '#F7EBC4'          # 크림색 턱
FillPath (EllipsePath 12 32 7 5) '#F08A8A'            # 달아오른 볼
FillPath (EllipsePath 44 32 7 5) '#F08A8A'
CurveStroke @((Pt 12 25), (Pt 17 22), (Pt 22 25)) '#4A5F44' 3.4 0.5   # 감은 눈
CurveStroke @((Pt 34 25), (Pt 39 22), (Pt 44 25)) '#4A5F44' 3.4 0.5
FillPath (EllipsePath 28 42 4 3) '#4A5F44'            # 오므린 입
FillPath (EllipsePath 28 8 12 7) '#F0A7C0'            # 머리 리본
FillPath (EllipsePath 28 8 5 5) '#DE8CAA'
Save-Soft (Join-Path $StageDir 'note_face.png')

foreach ($v in @(@{ n = 'ring'; c = '#FFF3D2'; d = '#B7A7CE'; w = 8.0 },
        @{ n = 'ring_lit'; c = '#FFE06B'; d = '#FFF6D8'; w = 11.0 })) {
    New-Soft 80 80
    # ★ 링은 어떤 배경 위에도 [b]타겟[/b]으로 보여야 합니다. 파스텔 배경에
    #   파스텔 링을 올리면 그냥 무늬가 되어 버리므로 짙은 테를 한 겹 깝니다.
    StrokePath (EllipsePath 40 40 33 33) '#443B5C' ($v.w + 10)
    StrokePath (EllipsePath 40 40 33 33) $v.d ($v.w + 5)
    StrokePath (EllipsePath 40 40 33 33) $v.c $v.w
    Save-Soft (Join-Path $StageDir ($v.n + '.png'))
}

# ============================================================
#  미리보기 — 두 사람을 씬과 같은 자리에 세워 봅니다
# ============================================================
$script:SImg = $bathOnly
$script:SG = [System.Drawing.Graphics]::FromImage($bathOnly)
$script:SG.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$script:SG.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$script:SG.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
foreach ($c in @(@('mengsoon', 430.0), @('mengdol', 620.0))) {
    $footX = [double]$c[1]; $footY = 540.0
    $x3 = $footX - 66.0
    CastShadow ($x3 - 30) 188 ($x3 + 30) 212 110 0.20
    Contact ($x3 - 30) 188 ($x3 + 30) 212 0.34
    $p = Join-Path $Root ("assets/sprites/characters/$($c[0])/$($c[0])_nude_stand.png")
    if (Test-Path $p) {
        $b = [System.Drawing.Bitmap]::FromFile($p)
        $script:SG.DrawImage($b, [single]($footX - 96), [single]($footY - 190), 192, 192)
        $b.Dispose()
    }
}
$canvas = Take-Soft
$final = TiltShift $canvas 0.30 0.90 6.0
$canvas.Dispose()
$final.Save((Join-Path $PSScriptRoot 'bath_iso_preview.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$final.Dispose()
Write-Output 'tools/bath_iso_preview.png'
