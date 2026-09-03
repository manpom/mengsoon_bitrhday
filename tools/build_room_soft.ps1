# ============================================================
#  맹돌이의 방 — A안(몽글 젤리) 아트로 다시 그리기
# ------------------------------------------------------------
#  실행:
#     powershell -ExecutionPolicy Bypass -File tools\build_room_soft.ps1
#  결과 -> assets/sprites/props/  (전부 덮어씁니다)
#
#  ★ 해상도가 2배입니다. 방이 1280x660 (예전 640x330).
#    부드러운 그림은 도트와 달리 확대하면 뭉개지므로, 기준 해상도를
#    960x540 으로 올리고 그림도 전부 2배로 그립니다.
#
#  ★ 소품은 "많이"가 아니라 "살아 있게" 놓습니다.
#    시선이 캐릭터와 노란 느낌표(글러브)로 자연스럽게 가야 하므로,
#    벽 위쪽과 방 가장자리에만 잔 소품을 두고 가운데 바닥은 비워 둡니다.
# ============================================================

. (Join-Path $PSScriptRoot '_soft.ps1')

$Root = Split-Path -Parent $PSScriptRoot
$PropDir = Join-Path $Root 'assets\sprites\props'
if (-not (Test-Path $PropDir)) { New-Item -ItemType Directory -Force -Path $PropDir | Out-Null }

# ---------- 팔레트 (A안과 같은 계열) ----------
# ★ 이름이 한 글자면 안 됩니다. PowerShell 변수는 대소문자를 구분하지 않아서
#   foreach ($k in ...) 한 줄이 팔레트 $K 를 통째로 덮어써 버립니다.
#   (실제로 그 버그로 글러브부터 전부 깨졌습니다)
$PAL = @{
    line     = '#6B5344'
    lineSoft = '#8A6E59'

    wall     = '#F7EAD8'
    wallLit  = '#FDF5E8'
    wallShd  = '#EBD9BF'
    panel    = '#EADAC3'
    base     = '#EFE0C8'

    floor    = '#E0CBAF'
    floor2   = '#D8C3A6'
    seam     = '#C4AA8B'
    floorShd = '#C2A585'

    wood     = '#C7A483'
    woodLit  = '#D8B998'
    woodShd  = '#A98B6D'
    woodDark = '#8F7457'

    sheet    = '#FFFBF2'
    sheetShd = '#EFE3CE'
    quilt    = '#BFD3B3'
    quiltLit = '#D2E0C8'
    quiltShd = '#A3BE9A'

    cloth    = '#AFC4DC'
    clothShd = '#95AAC6'
    rose     = '#E5B3BA'
    roseShd  = '#C795A0'
    mint     = '#B0D3C9'
    mintShd  = '#94BAB0'
    cream    = '#FFF4E6'
    creamShd = '#EBDCC2'

    leaf     = '#98BE94'
    leafLit  = '#AED2A9'
    leafShd  = '#7E9C81'
    pot      = '#D2A28B'
    potShd   = '#B58974'

    glass    = '#CFE3EE'
    sky      = '#CFE0EF'
    skyWarm  = '#F6D9BC'
    metal    = '#C9C2B4'
}

# 물건 하나를 그릴 캔버스. 아래에 그림자용 여백을 두고 부드러운 접지 그림자를
# 미리 깔아 둡니다. prop.gd 의 sprite_bottom_pad 와 같은 값이어야 합니다.
$PAD = 12
function Start-SoftProp([int]$w, [int]$h, [double]$shadowW = 1.0) {
    New-Soft ($w + 24) ($h + $PAD)
    GroundShadow (($w + 24) / 2.0) ($h + 2) ($w * 0.52 * $shadowW) 13 '#8A6E59' 0.26
    return 12.0   # 그림을 그릴 x 원점
}
function SaveProp([string]$name) { Save-Soft (Join-Path $PropDir ($name + '.png')) }

Write-Output 'assets/sprites/props/  (A안 · 2배 해상도)'

# ============================================================
#  room_bg.png - 1280x660.  벽 + 바닥 + 걸레받이 + 창에서 드는 빛
# ============================================================
$W = 1280; $H = 660; $FLOOR = 316
New-Soft $W $H

# 벽: 위가 밝고 아래로 갈수록 살짝 어두워집니다 (천장에서 빛이 옵니다)
$wallRect = RoundRectPath 0 0 $W $FLOOR 0
GradIn $wallRect $PAL.wallLit $PAL.wallShd 0 $FLOOR
# 아주 얕은 세로 판넬. 벽이 통짜 색이면 프로토타입처럼 보입니다.
for ($x = 0; $x -le $W; $x += 96) {
    $pen = New-Object System.Drawing.Pen((CA $PAL.panel 0.55), 3)
    $script:SG.DrawLine($pen, [single]$x, 0, [single]$x, [single]$FLOOR)
    $pen.Dispose()
}

# 바닥: 원근 없이 가로 널판. 위쪽이 조금 어둡고 앞으로 올수록 밝아집니다.
$floorRect = RoundRectPath 0 $FLOOR $W ($H - $FLOOR) 0
GradIn $floorRect $PAL.floorShd $PAL.floor2 $FLOOR $H
$row = 0
for ($y = $FLOOR + 34; $y -lt $H; $y += 46) {
    $pen = New-Object System.Drawing.Pen((CA $PAL.seam 0.5), 3)
    $script:SG.DrawLine($pen, 0, [single]$y, [single]$W, [single]$y)
    $pen.Dispose()
    # 널판 이음매를 한 줄 걸러 어긋나게
    $off = @(0, 210)[$row % 2]
    for ($x = $off; $x -lt $W; $x += 420) {
        $pen2 = New-Object System.Drawing.Pen((CA $PAL.seam 0.38), 3)
        $script:SG.DrawLine($pen2, [single]$x, [single]$y, [single]$x, [single]($y - 46))
        $pen2.Dispose()
    }
    $row++
}

# 걸레받이
FillPath (RoundRectPath 0 ($FLOOR - 22) $W 26 6) $PAL.base
FillPath (RoundRectPath 0 ($FLOOR - 4) $W 8 0) $PAL.creamShd
# 벽이 바닥에 드리우는 그늘
GroundShadow ($W / 2.0) ($FLOOR + 14) ($W * 0.62) 34 '#8A6E59' 0.20

# 창에서 바닥으로 떨어지는 빛 웅덩이 — 화면 전체를 하나의 그림으로 묶어 줍니다
$light = BlobPath @(
    (Pt 470 ($FLOOR + 8)), (Pt 760 ($FLOOR + 8)),
    (Pt 880 ($H - 40)), (Pt 360 ($H - 40))
) 0.3
$br = New-Object System.Drawing.Drawing2D.PathGradientBrush($light)
$br.CenterPoint = (Pt 615 ($FLOOR + 90))
$br.CenterColor = (CA '#FFF3D8' 0.42)
$br.SurroundColors = @((CA '#FFF3D8' 0.0))
$script:SG.FillPath($br, $light)
$br.Dispose()

Save-Soft (Join-Path $PropDir 'room_bg.png')

# ============================================================
#  bed_base.png - 옆에서 본 침대.  머리맡 왼쪽, 발치 오른쪽.
# ============================================================
$ox = Start-SoftProp 340 230
# 머리판
$hb = RoundRectPath ($ox + 0) 0 46 230 16
FillPath $hb $PAL.wood
ShadeIn $hb $PAL.woodLit $PAL.woodShd ($ox + 14) 40
StrokePath $hb $PAL.line 4
for ($y = 28; $y -lt 150; $y += 34) {
    FillPath (RoundRectPath ($ox + 12) $y 22 18 8) $PAL.woodShd
}
# 발판
$fb = RoundRectPath ($ox + 296) 66 44 164 16
FillPath $fb $PAL.wood
ShadeIn $fb $PAL.woodLit $PAL.woodShd ($ox + 306) 96
StrokePath $fb $PAL.line 4
# 매트리스
$mt = RoundRectPath ($ox + 30) 62 282 122 26
FillPath $mt $PAL.sheet
ShadeIn $mt '#FFFFFF' $PAL.sheetShd ($ox + 110) 92
StrokePath $mt $PAL.line 4
# 침대 틀
$fr = RoundRectPath ($ox + 30) 176 282 34 12
FillPath $fr $PAL.woodShd
StrokePath $fr $PAL.line 4
# 다리
foreach ($lx in 44, 274) {
    $lg = RoundRectPath ($ox + $lx) 204 24 26 8
    FillPath $lg $PAL.woodDark
    StrokePath $lg $PAL.line 3
}
# 베개
$pl = BlobPath @(
    (Pt ($ox + 52) 74), (Pt ($ox + 148) 68),
    (Pt ($ox + 156) 158), (Pt ($ox + 58) 164)
) 0.45
FillPath $pl '#FFFFFF'
ShadeIn $pl '#FFFFFF' $PAL.sheetShd ($ox + 80) 92
StrokePath $pl $PAL.line 4
CurveStroke @( (Pt ($ox + 70) 120), (Pt ($ox + 104) 128), (Pt ($ox + 140) 118) ) $PAL.creamShd 4 0.5
SaveProp 'bed_base'

# ============================================================
#  bed_quilt.png - 이불.  접힌 시트는 베개 쪽(왼쪽)에.
# ============================================================
New-Soft 212 128
$q = BlobPath @(
    (Pt 4 12), (Pt 208 4), (Pt 208 112), (Pt 4 118)
) 0.35
FillPath $q $PAL.quilt
ShadeIn $q $PAL.quiltLit $PAL.quiltShd 70 34
StrokePath $q $PAL.line 4
for ($x = 52; $x -lt 200; $x += 40) {
    CurveStroke @( (Pt $x 14), (Pt ($x + 3) 62), (Pt $x 110) ) $PAL.quiltShd 3 0.5
}
$fold = BlobPath @( (Pt 4 12), (Pt 44 8), (Pt 46 116), (Pt 4 118) ) 0.35
FillPath $fold $PAL.sheet
ShadeIn $fold '#FFFFFF' $PAL.sheetShd 16 34
StrokePath $fold $PAL.line 4
Save-Soft (Join-Path $PropDir 'bed_quilt.png')

# ============================================================
#  desk.png - 책상 + 서랍
# ============================================================
$ox = Start-SoftProp 260 168
$tp = RoundRectPath ($ox + 0) 26 260 26 10
FillPath $tp $PAL.woodLit
ShadeIn $tp '#E8C79C' $PAL.wood ($ox + 60) 32
StrokePath $tp $PAL.line 4
$dw = RoundRectPath ($ox + 22) 50 216 74 12
FillPath $dw $PAL.wood
ShadeIn $dw $PAL.woodLit $PAL.woodShd ($ox + 60) 62
StrokePath $dw $PAL.line 4
foreach ($dx in 34, 130) {
    $d = RoundRectPath ($ox + $dx) 62 96 50 10
    FillPath $d $PAL.woodLit
    StrokePath $d $PAL.woodShd 3
    FillPath (RoundRectPath ($ox + $dx + 34) 82 28 10 5) $PAL.metal
}
foreach ($lx in 16, 216) {
    $lg = RoundRectPath ($ox + $lx) 118 28 50 8
    FillPath $lg $PAL.woodShd
    StrokePath $lg $PAL.line 3
}
# 책상 위 소품: 스탠드 조명
$lamp = BlobPath @( (Pt ($ox + 30) 0), (Pt ($ox + 74) 0), (Pt ($ox + 64) 26), (Pt ($ox + 40) 26) ) 0.3
FillPath $lamp $PAL.mint
ShadeIn $lamp '#C7E8DE' $PAL.mintShd ($ox + 44) 6
StrokePath $lamp $PAL.line 4
SaveProp 'desk'

# ============================================================
#  chair.png
# ============================================================
$ox = Start-SoftProp 92 130
$bk = RoundRectPath ($ox + 8) 0 76 62 16
FillPath $bk $PAL.wood
ShadeIn $bk $PAL.woodLit $PAL.woodShd ($ox + 24) 12
StrokePath $bk $PAL.line 4
FillPath (RoundRectPath ($ox + 24) 14 44 34 10) $PAL.woodShd
$st = RoundRectPath ($ox + 0) 58 92 22 9
FillPath $st $PAL.woodLit
StrokePath $st $PAL.line 4
foreach ($lx in 8, 66) {
    $lg = RoundRectPath ($ox + $lx) 76 18 54 7
    FillPath $lg $PAL.woodShd
    StrokePath $lg $PAL.line 3
}
SaveProp 'chair'

# ============================================================
#  wardrobe.png
# ============================================================
$ox = Start-SoftProp 180 250
$wd = RoundRectPath ($ox + 0) 0 180 250 18
FillPath $wd $PAL.wood
ShadeIn $wd $PAL.woodLit $PAL.woodShd ($ox + 40) 40
StrokePath $wd $PAL.line 4
foreach ($dx in 12, 94) {
    $d = RoundRectPath ($ox + $dx) 14 74 214 12
    FillPath $d $PAL.woodLit
    StrokePath $d $PAL.woodShd 3
}
foreach ($hx in 78, 100) {
    FillPath (RoundRectPath ($ox + $hx) 112 8 30 4) $PAL.metal
}
SaveProp 'wardrobe'

# ============================================================
#  window.png - 새벽 하늘이 보이는 창 + 커튼
# ============================================================
New-Soft 268 200
$fr2 = RoundRectPath 6 6 256 168 14
FillPath $fr2 $PAL.wood
StrokePath $fr2 $PAL.line 4
$gl = RoundRectPath 20 20 228 140 8
FillPath $gl $PAL.sky
GradIn $gl $PAL.sky $PAL.skyWarm 20 160
# 해 뜨기 직전의 구름 두 덩이
GroundShadow 90 76 54 22 '#FFFFFF' 0.55
GroundShadow 168 104 44 18 '#FFFFFF' 0.45
StrokePath $gl $PAL.line 4
FillPath (RoundRectPath 130 20 8 140 3) $PAL.wood
FillPath (RoundRectPath 20 86 228 8 3) $PAL.wood
# 커튼
foreach ($sd in @(0, 1)) {
    $x0 = @(6, 196)[$sd]
    $cu = BlobPath @(
        (Pt $x0 0), (Pt ($x0 + 66) 4),
        (Pt ($x0 + 58) 150), (Pt ($x0 + 8) 158)
    ) 0.4
    FillPath $cu $PAL.rose
    ShadeIn $cu '#F6C6CE' $PAL.roseShd ($x0 + 16) 24
    StrokePath $cu $PAL.line 4
}
FillPath (RoundRectPath 0 0 268 14 6) $PAL.woodDark
Save-Soft (Join-Path $PropDir 'window.png')

# ============================================================
#  door.png
# ============================================================
New-Soft 200 320
$dr = RoundRectPath 6 6 188 314 12
FillPath $dr $PAL.wood
ShadeIn $dr $PAL.woodLit $PAL.woodShd 44 60
StrokePath $dr $PAL.line 4
FillPath (RoundRectPath 26 26 148 128 10) $PAL.woodShd
FillPath (RoundRectPath 26 174 148 122 10) $PAL.woodShd
FillPath (EllipsePath 160 172 11 11) $PAL.metal
StrokePath (EllipsePath 160 172 11 11) $PAL.line 3
Save-Soft (Join-Path $PropDir 'door.png')

# ============================================================
#  rug.png - 몽글한 타원 러그
# ============================================================
New-Soft 460 220
$rg = BlobPath @(
    (Pt 20 112), (Pt 130 16), (Pt 330 12), (Pt 442 108),
    (Pt 330 206), (Pt 130 208)
) 0.55
FillPath $rg '#C9D8E6'
ShadeIn $rg '#DCE8F1' '#B0C4D8' 150 60
StrokePath $rg $PAL.line 4
$rg2 = BlobPath @(
    (Pt 66 112), (Pt 152 44), (Pt 314 42), (Pt 396 108),
    (Pt 312 176), (Pt 152 178)
) 0.55
StrokePath $rg2 '#B0C4D8' 6
Save-Soft (Join-Path $PropDir 'rug.png')

# ============================================================
#  frame_empty.png - 빈 액자 (미니게임 하나 = 액자 하나)
# ============================================================
New-Soft 108 92
$f = RoundRectPath 4 4 100 84 10
FillPath $f $PAL.wood
ShadeIn $f $PAL.woodLit $PAL.woodShd 24 16
StrokePath $f $PAL.line 4
$inner = RoundRectPath 16 16 76 60 6
FillPath $inner '#EFE3D0'
StrokePath $inner $PAL.woodShd 3
# 아직 안 걸린 사진 자리에 옅은 물음표 대신 은은한 빛만
GroundShadow 54 46 30 22 '#FFFFFF' 0.5
Save-Soft (Join-Path $PropDir 'frame_empty.png')

# ============================================================
#  생활감 소품들
# ============================================================

# --- plant.png  화분
$ox = Start-SoftProp 116 150 0.8
$pt2 = BlobPath @(
    (Pt ($ox + 22) 74), (Pt ($ox + 94) 74),
    (Pt ($ox + 84) 148), (Pt ($ox + 32) 148)
) 0.3
FillPath $pt2 $PAL.pot
ShadeIn $pt2 '#E8B396' $PAL.potShd ($ox + 40) 88
StrokePath $pt2 $PAL.line 4
FillPath (RoundRectPath ($ox + 16) 64 84 22 9) '#E8B396'
StrokePath (RoundRectPath ($ox + 16) 64 84 22 9) $PAL.line 4
foreach ($lf in @(@(-34, 18, -26), @(0, 0, 0), @(34, 20, 26))) {
    $lx = $ox + 58 + $lf[0]; $ly = 8 + $lf[1]
    $leaf = BlobPath @(
        (Pt ($ox + 58) 70), (Pt ($lx - 16 + $lf[2] * 0.2) ($ly + 22)),
        (Pt $lx $ly), (Pt ($lx + 16 + $lf[2] * 0.2) ($ly + 26))
    ) 0.6
    FillPath $leaf $PAL.leaf
    ShadeIn $leaf $PAL.leafLit $PAL.leafShd $lx ($ly + 10)
    StrokePath $leaf $PAL.line 4
}
SaveProp 'plant'

# --- books.png  쌓아 둔 책 세 권
$ox = Start-SoftProp 120 80 0.9
$cols = @($PAL.cloth, $PAL.rose, $PAL.mint)
$y = 80
for ($i = 0; $i -lt 3; $i++) {
    $h2 = 22 - $i * 2
    $y -= $h2
    $bk2 = RoundRectPath ($ox + 4 + $i * 5) $y (112 - $i * 10) $h2 6
    FillPath $bk2 $cols[$i]
    StrokePath $bk2 $PAL.line 4
    FillPath (RoundRectPath ($ox + 10 + $i * 5) ($y + 4) 8 ($h2 - 8) 3) '#FFFFFFAA'
}
SaveProp 'books'

# --- cup.png  머그컵
$ox = Start-SoftProp 76 76 0.8
$cp = BlobPath @(
    (Pt ($ox + 10) 14), (Pt ($ox + 62) 14),
    (Pt ($ox + 56) 74), (Pt ($ox + 16) 74)
) 0.3
FillPath $cp $PAL.cream
ShadeIn $cp '#FFFFFF' $PAL.creamShd ($ox + 22) 26
StrokePath $cp $PAL.line 4
FillPath (RoundRectPath ($ox + 12) 32 48 12 5) $PAL.mint
$hd = EllipsePath ($ox + 66) 40 15 15
StrokePath $hd $PAL.line 9
StrokePath $hd $PAL.cream 5
SaveProp 'cup'

# --- toy.png  작은 개구리 인형 (둘의 미니어처)
$ox = Start-SoftProp 92 92 0.85
$tb = BlobPath @(
    (Pt ($ox + 18) 56), (Pt ($ox + 74) 56),
    (Pt ($ox + 68) 90), (Pt ($ox + 24) 90)
) 0.4
FillPath $tb '#A6D79C'
StrokePath $tb $PAL.line 4
$th = BlobPath @(
    (Pt ($ox + 20) 20), (Pt ($ox + 34) 2), (Pt ($ox + 58) 2),
    (Pt ($ox + 72) 20), (Pt ($ox + 66) 58), (Pt ($ox + 26) 58)
) 0.5
FillPath $th '#A6D79C'
ShadeIn $th '#C9E9BC' '#7FBA84' ($ox + 32) 16
StrokePath $th $PAL.line 4
FillPath (EllipsePath ($ox + 34) 22 7 8) '#4A3A46'
FillPath (EllipsePath ($ox + 58) 22 7 8) '#4A3A46'
CurveStroke @( (Pt ($ox + 30) 38), (Pt ($ox + 46) 46), (Pt ($ox + 62) 38) ) $PAL.line 4 0.5
SaveProp 'toy'

# --- shelf.png  벽 선반 (책 + 컵이 올라간)
New-Soft 260 96
$sh = RoundRectPath 8 60 244 20 8
FillPath $sh $PAL.wood
ShadeIn $sh $PAL.woodLit $PAL.woodShd 40 64
StrokePath $sh $PAL.line 4
$y2 = 60
foreach ($b in @(@(30, 44, $PAL.cloth), @(48, 52, $PAL.rose), @(64, 40, $PAL.mint), @(80, 48, $PAL.cream))) {
    $bk3 = RoundRectPath $b[0] ($y2 - $b[1]) 16 $b[1] 4
    FillPath $bk3 $b[2]
    StrokePath $bk3 $PAL.line 3
}
$vase = BlobPath @( (Pt 180 22), (Pt 206 22), (Pt 202 60), (Pt 184 60) ) 0.3
FillPath $vase $PAL.mint
StrokePath $vase $PAL.line 4
foreach ($lf in @(-14, 0, 14)) {
    $lp4 = BlobPath @( (Pt 193 24), (Pt (193 + $lf - 4) 8), (Pt (193 + $lf) 0), (Pt (193 + $lf + 6) 12) ) 0.6
    FillPath $lp4 $PAL.leaf
    StrokePath $lp4 $PAL.line 3
}
Save-Soft (Join-Path $PropDir 'shelf.png')

# --- clock.png  벽시계
New-Soft 88 88
$cl = EllipsePath 44 44 40 40
FillPath $cl $PAL.cream
ShadeIn $cl '#FFFFFF' $PAL.creamShd 30 30
StrokePath $cl $PAL.line 5
CurveStroke @( (Pt 44 44), (Pt 44 22) ) $PAL.line 5 0.5
CurveStroke @( (Pt 44 44), (Pt 60 50) ) $PAL.line 4 0.5
FillPath (EllipsePath 44 44 5 5) $PAL.line
Save-Soft (Join-Path $PropDir 'clock.png')

# --- glove.png  복싱 글러브 한 쌍 (★ 노란 느낌표 = 미니게임 1)
#     두 짝 사이를 확실히 벌리고 각자 손목 밴드를 줍니다.
#     붙여 놓으면 그냥 빨간 덩어리 하나로 보입니다.
$ox = Start-SoftProp 236 150
foreach ($mit in @(@(58, -1, 10), @(178, 1, 0))) {
    $gx = $ox + $mit[0]; $dir = $mit[1]; $gy = $mit[2]
    # 엄지 (주먹보다 먼저 = 뒤에 깔림)
    $th2 = BlobPath @(
        (Pt ($gx + $dir * 34) ($gy + 40)), (Pt ($gx + $dir * 62) ($gy + 52)),
        (Pt ($gx + $dir * 56) ($gy + 84)), (Pt ($gx + $dir * 32) ($gy + 78))
    ) 0.55
    FillPath $th2 '#DE8880'
    StrokePath $th2 $PAL.line 4
    # 주먹
    $mt2 = BlobPath @(
        (Pt ($gx - 44) ($gy + 46)), (Pt ($gx - 34) ($gy + 10)),
        (Pt ($gx + 2) ($gy + 0)), (Pt ($gx + 40) ($gy + 16)),
        (Pt ($gx + 44) ($gy + 62)), (Pt ($gx + 36) ($gy + 94)),
        (Pt ($gx - 36) ($gy + 96))
    ) 0.5
    FillPath $mt2 '#E9948C'
    ShadeIn $mt2 '#F7BAB2' '#C6706B' ($gx - 16) ($gy + 22)
    StrokePath $mt2 $PAL.line 4
    # 손가락 마디 골 - 이 한 줄이 있어야 "쥔 주먹"으로 보입니다
    CurveStroke @(
        (Pt ($gx - 34) ($gy + 56)), (Pt $gx ($gy + 64)), (Pt ($gx + 34) ($gy + 54))
    ) '#C6706B' 6 0.5
    # 손목 밴드 + X 자 끈
    $bd = RoundRectPath ($gx - 30) ($gy + 90) 60 44 12
    FillPath $bd $PAL.cream
    ShadeIn $bd '#FFFFFF' $PAL.creamShd ($gx - 12) ($gy + 98)
    StrokePath $bd $PAL.line 4
    foreach ($li in 0, 1) {
        CurveStroke @( (Pt ($gx - 16 + $li * 14) ($gy + 98)), (Pt ($gx + 2 + $li * 14) ($gy + 124)) ) $PAL.creamShd 4 0.5
        CurveStroke @( (Pt ($gx + 2 + $li * 14) ($gy + 98)), (Pt ($gx - 16 + $li * 14) ($gy + 124)) ) $PAL.creamShd 4 0.5
    }
}
SaveProp 'glove'

# --- shadow.png  캐릭터 발밑 그림자
New-Soft 96 40
GroundShadow 48 20 46 18 '#8A6E59' 0.34
Save-Soft (Join-Path $PropDir 'shadow.png')

Write-Output '완료'
