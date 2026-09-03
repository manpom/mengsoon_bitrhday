# ============================================================
#  맹돌이의 방 — 디오라마 버전 (젤다 꿈꾸는 섬 / 알바 참고)
# ------------------------------------------------------------
#     powershell -ExecutionPolicy Bypass -File tools\build_room_iso.ps1
#  결과 -> tools/room_iso_preview.png
#
#  ★ 정면 뷰를 완전히 버렸습니다.
#    바닥이 안쪽으로 물러나고, 가구마다 윗면이 보이고, 면마다 색이 다릅니다.
#    마지막에 틸트시프트를 걸어 "작은 모형" 신호를 줍니다.
#
#  좌표는 (x 가로, z 깊이, h 높이). 방은 x 0~1180, z 0~300.
# ============================================================

. (Join-Path $PSScriptRoot '_iso.ps1')

$MengLibOnly = $true
. (Join-Path $PSScriptRoot 'concepts_soft.ps1')
$STYLE_A = $STYLES | Where-Object { $_.key -eq 'A' }

$Root = Split-Path -Parent $PSScriptRoot
$PropDir = Join-Path $Root 'assets/sprites/props'

Set-Camera 648.0 0.54 0.18 30.0

# 미리보기에 캐릭터를 얹습니다.
# ★ 다시 그리지 않고 [b]구워 놓은 프레임[/b]을 불러옵니다. 그래야 미리보기와
#   실제 게임 화면이 어긋나지 않습니다. (192x192, 발이 y=190)
function PutMeng3([string]$who, [double]$x, [double]$z, [double]$unused = 0) {
    $foot = P3 $x $z 0
    CastShadow ($x - 30) ($z - 12) ($x + 30) ($z + 12) 110 0.22
    Contact ($x - 30) ($z - 12) ($x + 30) ($z + 12) 0.36
    $p = Join-Path $Root ("assets/sprites/characters/$who/${who}_down_idle.png")
    if (-not (Test-Path $p)) { return }
    $b = [System.Drawing.Bitmap]::FromFile($p)
    $script:SG.DrawImage($b, [single]($foot.X - 96), [single]($foot.Y - 190), 192, 192)
    $b.Dispose()
}

# ---------- 팔레트 ----------
# 알바처럼 면마다 한 톤. 윗면 밝게 / 앞면 중간 / 옆면 어둡게.
$C3 = @{
    floorTop  = '#E8D0AC'; floorSeam = '#D6B78F'
    wallBack  = '#F4E7D3'; wallLeft = '#E6D5BC'; wallTop = '#FBF2E4'
    skirtT    = '#EFE1C8'; skirtF = '#DCC9AA'; skirtS = '#C9B492'

    woodT     = '#DCBB93'; woodF = '#C39B72'; woodS = '#AA855F'
    woodDkT   = '#C0996F'; woodDkF = '#A87E58'; woodDkS = '#8E6A49'

    sheetT    = '#FFFCF4'; sheetF = '#F1E7D6'; sheetS = '#DFD3BE'
    quiltT    = '#BDD6AC'; quiltF = '#A2BE93'; quiltS = '#8CA880'
    pillowT   = '#FFFFFF'; pillowF = '#F0E9DA'

    rugT      = '#D9C5CB'; rugIn = '#BFA6B0'   # 맹돌이 후드가 연하늘이라 러그는 다른 계열로
    clothT    = '#B7CBE0'; clothF = '#9BB2CB'; clothS = '#8699B0'
    roseT     = '#E9BAC1'; roseF = '#D2A0A9'
    mintT     = '#B4D6CB'; mintF = '#98BCB2'
    creamT    = '#FFF3E2'; creamF = '#EBDCC4'

    leafT     = '#A2C79B'; leafF = '#84AC83'
    potT      = '#DCA98F'; potF = '#C08D76'; potS = '#A87A66'

    skyTop    = '#CBDDEE'; skyLow = '#F7DCC0'
    glove     = '#E29A92'; gloveF = '#C97D77'; gloveS = '#B06B67'
    ink       = '#6B5344'
}

$W = 1280; $H = 660
New-Soft $W $H

# 방 바깥은 흰 여백이 아니라 부드러운 배경입니다. 모형을 책상 위에
# 올려놓고 내려다보는 느낌이 되도록 가장자리를 살짝 어둡게 깝니다.
FillPath (RoundRectPath 0 0 $W $H 0) '#EFE2CE'
GroundShadow ($W / 2.0) ($H * 0.46) ($W * 0.60) ($H * 0.62) '#FBF2E2' 0.95

# ============================================================
#  방 껍데기: 왼쪽 벽 · 뒷벽 · 바닥
# ============================================================
$RX0 = 0.0; $RX1 = 1180.0; $RZ0 = -40.0; $RZ1 = 300.0; $WALLH = 430.0

# 바닥
$floor = FaceTop $RX0 $RZ0 $RX1 $RZ1 0
FillPath $floor $C3.floorTop
# 널판: 깊이 방향으로 줄이 물러납니다
for ($z = $RZ0; $z -le $RZ1; $z += 34) {
    $a = P3 $RX0 $z 0; $b = P3 $RX1 $z 0
    $pen = New-Object System.Drawing.Pen((CA $C3.floorSeam 0.55), 2.5)
    $script:SG.DrawLine($pen, $a, $b); $pen.Dispose()
}
for ($x = $RX0; $x -le $RX1; $x += 260) {
    $a = P3 $x $RZ0 0; $b = P3 $x $RZ1 0
    $pen = New-Object System.Drawing.Pen((CA $C3.floorSeam 0.35), 2.5)
    $script:SG.DrawLine($pen, $a, $b); $pen.Dispose()
}
# 안쪽으로 갈수록 살짝 어둡게 (공간감)
PushClip $floor
GroundShadow (P3 590 $RZ1 0).X (P3 590 $RZ1 0).Y 900 130 '#7A6250' 0.22
PopClip

# 뒷벽
$back = FaceFront $RX0 $RX1 $RZ1 0 $WALLH
FillPath $back $C3.wallBack
FaceLight $back $C3.wallTop 0.55
# 왼쪽 벽
$left = FaceSide $RX0 $RZ0 $RZ1 0 $WALLH
FillPath $left $C3.wallLeft
FaceLight $left '#F2E4CE' 0.4

# 구석의 어둠. 이게 없으면 방이 종이 상자처럼 보입니다.
CornerDark $back '#8A6E55' 0.30 (P3 0 $RZ1 0).X (P3 0 $RZ1 0).Y 300 460
CornerDark $left '#8A6E55' 0.26 (P3 $RX0 $RZ1 0).X (P3 $RX0 $RZ1 0).Y 200 420
CornerDark $floor '#8A6E55' 0.22 (P3 0 $RZ1 0).X (P3 0 $RZ1 0).Y 340 150

# 벽 허리선 (몰딩) - 벽이 통짜 면으로 보이지 않게
Box3 $RX0 ($RZ1 - 6) $RX1 $RZ1 150 162 $C3.skirtT $C3.skirtF $C3.skirtS | Out-Null
FillPath (FaceFront $RX0 $RX1 ($RZ1 - 7) 0 150) '#EEDFC6'

# 걸레받이
Box3 $RX0 ($RZ1 - 8) $RX1 $RZ1 0 26 $C3.skirtT $C3.skirtF $C3.skirtS | Out-Null
Box3 $RX0 $RZ0 ($RX0 + 8) $RZ1 0 26 $C3.skirtT $C3.skirtS $C3.skirtF | Out-Null
# 벽이 바닥에 드리우는 그늘
Contact $RX0 ($RZ1 - 30) $RX1 $RZ1 0.26

# --- 러그 (바닥 바로 위. 다른 가구는 전부 이 위에 얹힙니다)
$rug = Quad (P3 400 34 0) (P3 800 34 0) (P3 828 186 0) (P3 372 186 0)
FillPath $rug $C3.rugT
CornerDark $rug '#6E5847' 0.16 (P3 600 186 0).X (P3 600 186 0).Y 300 40
$rug2 = Quad (P3 442 56 0) (P3 758 56 0) (P3 780 164 0) (P3 420 164 0)
StrokePath $rug2 $C3.rugIn 7
$rug3 = Quad (P3 478 76 0) (P3 722 76 0) (P3 740 144 0) (P3 460 144 0)
StrokePath $rug3 $C3.rugIn 4

# ============================================================
#  뒷벽에 붙은 것들
# ------------------------------------------------------------
#  벽 위 물건은 서로 [b]붙지 않게[/b] 간격을 둡니다.
#  창(470~720) · 선반(780~960) · 문(1000~1170) 순서로 떨어져 있습니다.
#  액자는 뺐습니다.
# ============================================================

# --- 창문 (아침 빛)
$wx0 = 470.0; $wx1 = 720.0
Box3 ($wx0 - 18) ($RZ1 - 10) ($wx1 + 18) ($RZ1 - 2) 184 386 $C3.woodT $C3.woodF $C3.woodS | Out-Null
$gl = FaceFront $wx0 $wx1 ($RZ1 - 3) 200 370
FillPath $gl $C3.skyTop
GradIn $gl $C3.skyTop $C3.skyLow (P3 0 $RZ1 370).Y (P3 0 $RZ1 200).Y
# 유리에 비친 구름 두 덩이
CornerDark $gl '#FFFFFF' 0.5 (P3 540 $RZ1 320).X (P3 540 $RZ1 320).Y 60 22
CornerDark $gl '#FFFFFF' 0.4 (P3 650 $RZ1 280).X (P3 650 $RZ1 280).Y 48 18
# 창살
FillPath (FaceFront (($wx0 + $wx1) / 2 - 5) (($wx0 + $wx1) / 2 + 5) ($RZ1 - 4) 200 370) $C3.woodF
FillPath (FaceFront $wx0 $wx1 ($RZ1 - 4) 282 292) $C3.woodF
# 창턱 + 작은 화분
Box3 ($wx0 - 26) ($RZ1 - 22) ($wx1 + 26) ($RZ1 - 2) 184 196 $C3.woodT $C3.woodF $C3.woodS | Out-Null
Cyl3 ($wx0 + 60) ($RZ1 - 12) 16 196 226 $C3.potT $C3.potF $C3.potS
foreach ($sl in @(@(-14, 40), @(2, 52), @(16, 38))) {
    $lp5 = BlobPath @(
        (P3 ($wx0 + 60) ($RZ1 - 12) 226),
        (P3 ($wx0 + 60 + $sl[0] - 8) ($RZ1 - 12) (226 + $sl[1] * 0.6)),
        (P3 ($wx0 + 60 + $sl[0]) ($RZ1 - 12) (226 + $sl[1])),
        (P3 ($wx0 + 60 + $sl[0] + 7) ($RZ1 - 12) (226 + $sl[1] * 0.7))
    ) 0.6
    FillPath $lp5 $C3.leafT
}
# 커튼
foreach ($cu in @(@(($wx0 - 34), ($wx0 + 40)), @(($wx1 - 40), ($wx1 + 34)))) {
    $c = FaceFront $cu[0] $cu[1] ($RZ1 - 6) 186 400
    FillPath $c $C3.roseT
    FaceLight $c '#F5CFD5' 0.5
    CornerDark $c '#C9959E' 0.35 (P3 (($cu[0] + $cu[1]) / 2) $RZ1 200).X (P3 (($cu[0] + $cu[1]) / 2) $RZ1 200).Y 40 60
}
# 커튼 봉 - 가로로 누운 막대라 Cyl3(세로 원기둥)를 쓰면 안 됩니다
Box3 ($wx0 - 44) ($RZ1 - 10) ($wx1 + 44) ($RZ1 - 4) 396 406 $C3.woodT $C3.woodS $C3.woodS | Out-Null

# 창에서 바닥으로 떨어지는 빛
$lp = Quad (P3 ($wx0 - 10) $RZ1 0) (P3 ($wx1 + 10) $RZ1 0) (P3 ($wx1 + 96) 20 0) (P3 ($wx0 - 96) 20 0)
$br = New-Object System.Drawing.Drawing2D.PathGradientBrush($lp)
$br.CenterPoint = (P3 (($wx0 + $wx1) / 2) 170 0)
$br.CenterColor = (CA '#FFF0D2' 0.44)
$br.SurroundColors = @((CA '#FFF0D2' 0.0))
$script:SG.FillPath($br, $lp); $br.Dispose()

# --- 벽 선반 (책상 바로 위. 문과 확실히 떨어뜨립니다)
Box3 780 ($RZ1 - 46) 960 ($RZ1 - 4) 208 222 $C3.woodT $C3.woodF $C3.woodS | Out-Null
$bx = 798.0
foreach ($bc in @(@($C3.clothT, $C3.clothF, 52), @($C3.roseT, $C3.roseF, 62),
        @($C3.mintT, $C3.mintF, 46), @($C3.creamT, $C3.creamF, 58),
        @($C3.clothT, $C3.clothF, 50))) {
    Box3 $bx ($RZ1 - 38) ($bx + 17) ($RZ1 - 14) 222 (222 + $bc[2]) $bc[0] $bc[1] $bc[1] | Out-Null
    $bx += 21
}
Cyl3 930 ($RZ1 - 26) 18 222 246 $C3.mintT $C3.mintF $C3.mintF

# --- 문 (맨 오른쪽)
#  ★ 문은 벽에 [b]박혀[/b] 있어야 합니다. Box3 로 그리면 윗면과 옆면이
#    드러나서 벽 앞에 세워 둔 옷장처럼 튀어나와 보입니다.
#    벽과 같은 면(FaceFront)으로만 그립니다.
FillPath (FaceFront 996 1174 ($RZ1 - 1) 0 406) $C3.woodDkF          # 문틀
FillPath (FaceFront 1008 1162 ($RZ1 - 2) 0 396) $C3.woodT           # 문짝
FillPath (FaceFront 1022 1148 ($RZ1 - 3) 212 372) $C3.woodDkF       # 위 패널
FillPath (FaceFront 1026 1144 ($RZ1 - 4) 216 368) $C3.woodT
FillPath (FaceFront 1022 1148 ($RZ1 - 3) 28 190) $C3.woodDkF        # 아래 패널
FillPath (FaceFront 1026 1144 ($RZ1 - 4) 32 186) $C3.woodT
FillPath (EllipsePath (P3 1032 ($RZ1 - 5) 198).X (P3 1032 ($RZ1 - 5) 198).Y 9 9) '#C9C2B4'
# 문이 벽에서 살짝 안으로 들어가 있다는 신호 - 위와 왼쪽에 얇은 그늘
CornerDark (FaceFront 1008 1162 ($RZ1 - 2) 0 396) '#7A6250' 0.30 `
    (P3 1010 $RZ1 396).X (P3 1010 $RZ1 396).Y 60 130
# 문 앞 매트
$mat = Quad (P3 1022 286 0) (P3 1148 286 0) (P3 1154 246 0) (P3 1016 246 0)
FillPath $mat '#C9B79E'
# ============================================================
#  바닥에 놓인 가구  (뒤에 있는 것부터 그립니다)
# ============================================================

# --- 옷장
CastShadow 330 236 470 290 300 0.24
Contact 330 236 470 290 0.30
Box3 330 236 470 290 0 300 $C3.woodT $C3.woodF $C3.woodS | Out-Null
FillPath (FaceFront 340 396 235 16 288) $C3.woodDkF
FillPath (FaceFront 404 460 235 16 288) $C3.woodDkF
FillPath (EllipsePath (P3 397 234 152).X (P3 397 234 152).Y 5 13) '#C9C2B4'
FillPath (EllipsePath (P3 405 234 152).X (P3 405 234 152).Y 5 13) '#C9C2B4'
$wt = FaceTop 330 236 470 290 300
CornerDark $wt '#8A6E55' 0.28 (P3 400 250 300).X (P3 400 250 300).Y 90 18

# --- 책상 (다리 두 짝 + 상판 + 오른쪽 서랍장)
CastShadow 760 220 980 292 120 0.20
Contact 760 220 980 292 0.30
Box3 766 226 796 288 0 104 $C3.woodDkT $C3.woodDkF $C3.woodDkS | Out-Null   # 왼쪽 다리판
Box3 890 226 974 288 0 104 $C3.woodDkT $C3.woodDkF $C3.woodDkS | Out-Null   # 오른쪽 서랍장
FillPath (FaceFront 900 964 225 62 96) $C3.woodT                             # 서랍 두 칸
FillPath (FaceFront 900 964 225 16 52) $C3.woodT
FillPath (RoundRectPath ((P3 920 225 76).X) ((P3 920 225 76).Y) 24 7 3) '#C9C2B4'
FillPath (RoundRectPath ((P3 920 225 32).X) ((P3 920 225 32).Y) 24 7 3) '#C9C2B4'
Box3 760 220 980 292 104 120 $C3.woodT $C3.woodF $C3.woodS | Out-Null        # 상판
$dt = FaceTop 760 220 980 292 120
CornerDark $dt '#F2DABA' 0.45 (P3 820 276 120).X (P3 820 276 120).Y 100 22

# 책상 위: 책 두 권 · 머그컵 · 연필꽂이 · 스탠드
Box3 782 236 848 274 120 142 $C3.clothT $C3.clothF $C3.clothS | Out-Null
Box3 788 240 842 270 142 160 $C3.roseT $C3.roseF $C3.roseF | Out-Null
Cyl3 872 250 20 120 168 $C3.creamT $C3.creamF $C3.creamF
FillPath (EllipsePath (P3 872 250 168).X (P3 872 250 168).Y 14 8) $C3.mintT
$hd = EllipsePath ((P3 872 250 144).X + 25) ((P3 872 250 144).Y) 14 13
StrokePath $hd $C3.creamF 8
Cyl3 916 262 16 120 158 $C3.mintT $C3.mintF $C3.mintF                        # 연필꽂이
foreach ($pc in @(@(-6, 34, $C3.roseF), @(2, 42, $C3.woodS), @(9, 30, $C3.clothF))) {
    Cyl3 (916 + $pc[0]) 262 3 150 (158 + $pc[1]) $pc[2] $pc[2] $pc[2]
}
Cyl3 950 268 14 120 128 $C3.mintT $C3.mintF $C3.mintF                        # 스탠드
FillPath (FaceFront 944 956 268 128 206) $C3.mintF
$sh2 = BlobPath @(
    (P3 926 268 206), (P3 976 268 206), (P3 968 268 246), (P3 934 268 246)
) 0.2
FillPath $sh2 $C3.mintT
FaceLight $sh2 '#D3EAE2' 0.55

# --- 의자 (책상을 향해 정면으로. 등받이가 우리 쪽 = 앞쪽입니다)
CastShadow 806 126 906 208 200 0.18
Contact 806 126 906 208 0.28
foreach ($lg in @(@(812, 132), @(884, 132), @(812, 186), @(884, 186))) {
    Box3 $lg[0] $lg[1] ($lg[0] + 16) ($lg[1] + 14) 0 88 $C3.woodDkT $C3.woodDkF $C3.woodDkS | Out-Null
}
Box3 806 126 906 208 88 102 $C3.woodT $C3.woodF $C3.woodS | Out-Null          # 앉는 판
Box3 810 126 902 138 102 196 $C3.woodT $C3.woodF $C3.woodS | Out-Null         # 등받이
FillPath (FaceFront 822 890 125 120 184) $C3.woodDkF

# --- 침대 (왼쪽 벽에 붙여서)
CastShadow 60 60 300 250 150 0.22
Contact 60 60 300 250 0.34
Box3 60 60 300 250 0 54 $C3.woodDkT $C3.woodDkF $C3.woodDkS | Out-Null       # 침대 틀
Box3 60 232 300 250 0 150 $C3.woodT $C3.woodF $C3.woodS | Out-Null           # 머리판
foreach ($sl2 in 92, 140, 188, 236) {
    FillPath (FaceFront ($sl2 - 7) ($sl2 + 7) 231 44 140) $C3.woodDkF
}
Box3 66 66 294 244 54 96 $C3.sheetT $C3.sheetF $C3.sheetS | Out-Null         # 매트리스
Box3 74 176 286 236 96 126 $C3.pillowT $C3.pillowF $C3.pillowF | Out-Null    # 베개
$pt2 = FaceTop 74 176 286 236 126
CornerDark $pt2 '#E4D9C6' 0.5 (P3 180 190 126).X (P3 180 190 126).Y 90 24
Box3 66 66 294 130 96 118 $C3.quiltT $C3.quiltF $C3.quiltS | Out-Null        # 이불
$qt = FaceTop 66 66 294 130 118
CornerDark $qt '#93AF88' 0.35 (P3 250 96 118).X (P3 250 96 118).Y 90 30
FillPath (FaceFront 66 294 66 108 118) $C3.sheetT                             # 접힌 시트 끝

# --- 화분 (앞쪽 오른쪽 구석)
CastShadow 1080 30 1170 110 108 0.20
Contact 1080 30 1170 110 0.30
Cyl3 1125 70 44 0 88 $C3.potT $C3.potF $C3.potS
Cyl3 1125 70 50 88 106 $C3.potT $C3.potF $C3.potS
FillPath (EllipsePath (P3 1125 70 106).X (P3 1125 70 106).Y 42 22) '#8E6A55'
foreach ($lf in @(@(-40, 146, 26), @(-14, 188, 20), @(18, 172, 24), @(42, 134, 22))) {
    $lx = 1125 + $lf[0]
    $leaf = BlobPath @(
        (P3 1125 70 108),
        (P3 ($lx - $lf[2]) 70 ($lf[1] * 0.62)),
        (P3 $lx 70 $lf[1]),
        (P3 ($lx + $lf[2] * 0.7) 70 ($lf[1] * 0.72))
    ) 0.62
    FillPath $leaf $C3.leafT
    FaceLight $leaf '#BEDCB6' 0.5
}

# --- 복싱 글러브 (★ 미니게임 1) — 침대 위 벽에 끈으로 걸어 둡니다
#
#  ★ 바닥에 눕혀 놓는 건 다섯 번 고쳐도 분홍 덩어리로만 보였습니다.
#    [b]끈에 매달린 두 짝[/b]은 실루엣만으로 글러브 말고 다른 게 될 수 없습니다.
#
#  ★ 선은 하나도 긋지 않습니다. 이 크기에서 잔선은 형태를 살리기는커녕
#    지저분해 보이기만 합니다. 손목 밴드도 크림색으로 나누지 않고
#    [b]전부 빨갛게[/b] 두고, 명암 차이만으로 구분합니다.
$hookP = P3 206 ($RZ1 - 2) 330
FillPath (RoundRectPath ($hookP.X - 5) ($hookP.Y - 4) 10 14 4) $C3.woodS
FillPath (EllipsePath $hookP.X ($hookP.Y + 12) 7 6) '#C9C2B4'

foreach ($gv in @(@(-40, 0, -1), @(36, 16, 1))) {
    $dx2 = [double]$gv[0]; $dy2 = [double]$gv[1]; $gd = [double]$gv[2]
    $tx = $hookP.X + $dx2
    $ty = $hookP.Y + 50 + $dy2

    # 끈 - 고리에서 글러브까지. 이게 "매달려 있다"는 유일한 신호입니다.
    CurveStroke @(
        (Pt $hookP.X ($hookP.Y + 12)),
        (Pt ($hookP.X + $dx2 * 0.55) ($hookP.Y + 30 + $dy2 * 0.4)),
        (Pt $tx ($ty + 2))
    ) '#CDB794' 4 0.5

    # 엄지 - 바깥쪽으로 (주먹보다 먼저 = 뒤에 깔림)
    FillPath (EllipsePath ($tx + $gd * 27) ($ty + 64) 15 19) $C3.gloveF

    # 손목 밴드 - 주먹과 같은 빨강, 한 톤만 어둡게
    $cuff = RoundRectPath ($tx - 20) $ty 40 36 12
    FillPath $cuff $C3.gloveF
    ShadeTopOnly $cuff $C3.glove ($tx - 8) ($ty + 8)

    # 주먹
    $fist = BlobPath @(
        (Pt ($tx - 21) ($ty + 26)),
        (Pt ($tx - 35) ($ty + 52)),
        (Pt ($tx - 32) ($ty + 86)),
        (Pt ($tx - 8) ($ty + 99)),
        (Pt ($tx + 20) ($ty + 92)),
        (Pt ($tx + 32) ($ty + 62)),
        (Pt ($tx + 21) ($ty + 26))
    ) 0.5
    FillPath $fist $C3.glove
    ShadeTopOnly $fist '#F8CCC4' ($tx - 10) ($ty + 44)
    PushClip $fist
    GroundShadow ($tx + 12) ($ty + 106) 34 24 $C3.gloveS 0.55
    PopClip
}
# --- 슬리퍼 두 짝
foreach ($sp in @(@(902, 34), @(956, 24))) {
    Contact ($sp[0] - 22) ($sp[1] - 14) ($sp[0] + 22) ($sp[1] + 14) 0.22
    Box3 ($sp[0] - 22) ($sp[1] - 12) ($sp[0] + 22) ($sp[1] + 12) 0 12 $C3.roseT $C3.roseF $C3.roseF | Out-Null
    FillPath (EllipsePath (P3 $sp[0] ($sp[1] + 4) 14).X (P3 $sp[0] ($sp[1] + 4) 14).Y 20 11) $C3.creamT
}

# ============================================================
#  내보내기
# ------------------------------------------------------------
#  ★ 게임에는 [b]방 한 장[/b]이 들어갑니다. 예전처럼 가구를 낱장 스프라이트로
#    쪼개지 않습니다. 디오라마는 가구끼리 그림자와 가림이 얽혀 있어서
#    낱장으로 쪼개면 그 관계가 전부 깨집니다.
#    상호작용은 그림 위에 [b]안 보이는 Prop[/b]을 얹어서 처리합니다.
#
#  ★ 틸트시프트는 [b]미리보기에만[/b] 겁니다. 카메라가 따라 움직이는데
#    배경에 구워 버리면 흐린 띠가 방과 같이 움직여서 어색해집니다.
#    나중에 화면 셰이더로 넣는 게 맞습니다.
#
#  이불만 따로 한 장 더 뽑습니다. 오프닝에서 누운 맹돌이를 [b]덮어야[/b] 하므로
#  플레이어보다 앞에 그려질 스프라이트가 하나 필요합니다.
# ============================================================
$roomOnly = Take-Soft
$roomOnly.Save((Join-Path $PropDir 'room_iso.png'), [System.Drawing.Imaging.ImageFormat]::Png)
Write-Output ("  room_iso.png                 {0}x{1}" -f $roomOnly.Width, $roomOnly.Height)

# --- 이불만 (플레이어 위에 덮일 오버레이)
New-Soft $W $H
Box3 66 66 294 130 96 118 $C3.quiltT $C3.quiltF $C3.quiltS | Out-Null
$qt2 = FaceTop 66 66 294 130 118
CornerDark $qt2 '#93AF88' 0.35 (P3 250 96 118).X (P3 250 96 118).Y 90 30
FillPath (FaceFront 66 294 66 108 118) $C3.sheetT
$quilt = Take-Soft
$quilt.Save((Join-Path $PropDir 'quilt_overlay.png'), [System.Drawing.Imaging.ImageFormat]::Png)
Write-Output ("  quilt_overlay.png            {0}x{1}" -f $quilt.Width, $quilt.Height)
$quilt.Dispose()

# --- 미리보기 (캐릭터 + 틸트시프트)
$script:SImg = $roomOnly
$script:SG = [System.Drawing.Graphics]::FromImage($roomOnly)
$script:SG.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$script:SG.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$script:SG.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
PutMeng3 'mengdol' 560 24
PutMeng3 'mengsoon' 700 44
$canvas = Take-Soft
$final = TiltShift $canvas 0.30 0.90 6.0
$canvas.Dispose()
$final.Save((Join-Path $PSScriptRoot 'room_iso_preview.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$final.Dispose()
Write-Output 'tools/room_iso_preview.png'
