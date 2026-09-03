# ============================================================
#  디오라마 투영 + 면별 플랫 셰이딩
# ------------------------------------------------------------
#  젤다 「꿈꾸는 섬」과 「알바」가 입체로 보이는 이유는 단 하나입니다.
#  물건마다 [b]윗면이 보이고, 면마다 색이 다르다[/b]는 것.
#
#  지금까지 그리던 정면 실루엣은 아무리 그라디언트를 넣어도 납작합니다.
#  여기서는 바닥 좌표 (x, z) 와 높이 h 를 화면 좌표로 투영해서,
#  상자 하나를 [b]윗면 · 앞면 · 옆면[/b] 세 조각으로 나눠 칠합니다.
#
#      x : 가로 (오른쪽이 +)
#      z : 깊이 (화면 안쪽이 +)
#      h : 높이 (위가 +)
#
#      sx = OX + x + z * SHEAR
#      sy = FRONTY - z * DEPTH - h
#
#  SHEAR 가 0 이면 옆면이 아예 안 보입니다(정면 뷰). 0.18 쯤 주면
#  살짝 비스듬해지면서 옆면이 얇게 드러나 "모형"처럼 보입니다.
#
#  면 색은 알바처럼 [b]면마다 한 톤[/b]입니다. 그라디언트로 뭉개지 않고
#  윗면 밝게 / 앞면 중간 / 옆면 어둡게 딱 나누는 쪽이 훨씬 단단해 보입니다.
# ============================================================

. (Join-Path $PSScriptRoot '_soft.ps1')

$script:FRONTY = 640.0
$script:DEPTH = 0.52
$script:SHEAR = 0.18
$script:OX = 40.0

function Set-Camera([double]$frontY, [double]$depth, [double]$shear, [double]$ox) {
    $script:FRONTY = $frontY; $script:DEPTH = $depth
    $script:SHEAR = $shear; $script:OX = $ox
}

# 바닥 좌표 + 높이 -> 화면 좌표
function P3([double]$x, [double]$z, [double]$h) {
    return (Pt ($script:OX + $x + $z * $script:SHEAR) ($script:FRONTY - $z * $script:DEPTH - $h))
}

# 네 점을 잇는 사각면
function Quad($a, $b, $c, $d) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $p.AddPolygon([System.Drawing.PointF[]]@($a, $b, $c, $d))
    return $p
}

# ---------- 면 세 종류 ----------
# 윗면: 높이 h 에서 바닥 사각형을 그대로 올린 것
function FaceTop([double]$x0, [double]$z0, [double]$x1, [double]$z1, [double]$h) {
    return (Quad (P3 $x0 $z1 $h) (P3 $x1 $z1 $h) (P3 $x1 $z0 $h) (P3 $x0 $z0 $h))
}
# 앞면: 깊이 z 에 서 있는 벽
function FaceFront([double]$x0, [double]$x1, [double]$z, [double]$h0, [double]$h1) {
    return (Quad (P3 $x0 $z $h0) (P3 $x1 $z $h0) (P3 $x1 $z $h1) (P3 $x0 $z $h1))
}
# 옆면: 가로 x 에 서 있는 벽
function FaceSide([double]$x, [double]$z0, [double]$z1, [double]$h0, [double]$h1) {
    return (Quad (P3 $x $z0 $h0) (P3 $x $z1 $h0) (P3 $x $z1 $h1) (P3 $x $z0 $h1))
}

# ---------- 상자 하나 ----------
# 옆면은 오른쪽만 그립니다. SHEAR 가 양수라 왼쪽 옆면은 안 보입니다.
function Box3([double]$x0, [double]$z0, [double]$x1, [double]$z1, [double]$h0, [double]$h1,
    [string]$top, [string]$front, [string]$side) {
    $sf = FaceSide $x1 $z0 $z1 $h0 $h1
    FillPath $sf $side
    $ff = FaceFront $x0 $x1 $z0 $h0 $h1
    FillPath $ff $front
    $tf = FaceTop $x0 $z0 $x1 $z1 $h1
    FillPath $tf $top
    return @($tf, $ff, $sf)
}

# 물건이 바닥에 닿는 자리의 그늘. 이게 없으면 물건이 떠 보입니다.
function Contact([double]$x0, [double]$z0, [double]$x1, [double]$z1, [double]$alpha = 0.30) {
    $c0 = P3 $x0 $z0 0; $c1 = P3 $x1 $z1 0
    $cx = ($c0.X + $c1.X) / 2.0; $cy = ($c0.Y + $c1.Y) / 2.0
    GroundShadow $cx ($cy + 4) (($c1.X - $c0.X) * 0.72) (($x1 - $x0) * 0.16 + 10) '#7A6250' $alpha
}

# 면 위에 얹는 아주 옅은 빛/그늘. 플랫을 유지하면서 단조로움만 덜어 줍니다.
function FaceLight($path, [string]$hex, [double]$alpha) {
    $b = $path.GetBounds()
    PushClip $path
    GroundShadow ($b.X + $b.Width * 0.34) ($b.Y + $b.Height * 0.26) ($b.Width * 0.62) ($b.Height * 0.58) $hex $alpha
    PopClip
}

# ---------- 원기둥 ----------
# 컵 · 화분 · 캐릭터 몸통처럼 상자로 만들면 어색한 것들.
# 바닥의 원은 투영하면 타원이 됩니다 (세로가 DEPTH 만큼 눌림).
function Cyl3([double]$cx, [double]$cz, [double]$r, [double]$h0, [double]$h1,
    [string]$top, [string]$front, [string]$side) {
    $ct = P3 $cx $cz $h1
    $cb = P3 $cx $cz $h0
    $ry = $r * $script:DEPTH
    # 아래 마감 (몸통보다 먼저 = 밑이 둥글어 보임)
    FillPath (EllipsePath $cb.X $cb.Y $r $ry) $front
    # 몸통
    FillPath (Quad (Pt ($cb.X - $r) $cb.Y) (Pt ($cb.X + $r) $cb.Y) `
            (Pt ($ct.X + $r) $ct.Y) (Pt ($ct.X - $r) $ct.Y)) $front
    # 오른쪽으로 갈수록 어두워지는 띠 하나 (원기둥의 핵심)
    FillPath (Quad (Pt ($cb.X + $r * 0.34) $cb.Y) (Pt ($cb.X + $r) $cb.Y) `
            (Pt ($ct.X + $r) $ct.Y) (Pt ($ct.X + $r * 0.34) $ct.Y)) $side
    # 윗면
    FillPath (EllipsePath $ct.X $ct.Y $r $ry) $top
}

# ---------- 드리운 그림자 ----------
# 빛이 창(안쪽 위)에서 오므로 그림자는 앞쪽(화면 아래)으로 깔립니다.
# 접지 그늘(Contact)이 "닿아 있다"를 말한다면, 이건 "빛이 어디서 오는지"를
# 말합니다. 둘 다 있어야 방이 한 덩어리로 보입니다.
function CastShadow([double]$x0, [double]$z0, [double]$x1, [double]$z1,
    [double]$h, [double]$alpha = 0.20) {
    $reach = $h * 0.55
    $q = Quad (P3 ($x0 - 6) ($z0 - $reach) 0) (P3 ($x1 + 6) ($z0 - $reach) 0) `
        (P3 $x1 $z1 0) (P3 $x0 $z1 0)
    $br = New-Object System.Drawing.Drawing2D.PathGradientBrush($q)
    $b = $q.GetBounds()
    $br.CenterPoint = (Pt ($b.X + $b.Width * 0.5) ($b.Y + $b.Height * 0.35))
    $br.CenterColor = (CA '#6E5847' $alpha)
    $br.SurroundColors = @((CA '#6E5847' 0.0))
    $script:SG.FillPath($br, $q)
    $br.Dispose(); $q.Dispose()
}

# 벽과 벽, 벽과 바닥이 만나는 구석의 어둠. 이게 없으면 방이 종이 상자처럼 보입니다.
function CornerDark($path, [string]$hex, [double]$alpha, [double]$fx, [double]$fy, [double]$rx, [double]$ry) {
    PushClip $path
    GroundShadow $fx $fy $rx $ry $hex $alpha
    PopClip
}
