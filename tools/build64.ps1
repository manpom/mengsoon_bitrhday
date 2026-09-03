param(
    [string]$Who = 'mengdol',
    [int]$Variant = 1,
    [string]$Out = '',
    # which way the character is facing
    [ValidateSet('down', 'up')][string]$Dir = 'down',
    # walk cycle: 0 = standing, 1 = left foot up, -1 = right foot up
    [int]$Step = 0,
    # face expression (the back of the head has no face at all)
    [ValidateSet('normal', 'happy', 'surprise', 'sad', 'angry', 'sleepy', 'shy', 'laugh')][string]$Face = 'normal',
    # no clothes - the bare frog body (memory 1 is set in a bathroom)
    [switch]$Nude,
    # what the body is doing. 'lie' ignores Dir/Step and draws the head
    # resting on a pillow with a shoulder stub, for the bed.
    [ValidateSet('stand', 'guard', 'punch1', 'punch2', 'laugh', 'fart', 'lie')][string]$Pose = 'stand'
)

# ASCII-only comments on purpose: PS 5.1 reads BOM-less UTF-8 as ANSI and a
# mis-decoded byte can act as a line continuation, swallowing the next line.
#
# Redrawn from the meng.png reference sheet:
#   - round frog head, two shallow eye bumps on top, cream jaw under the smile
#   - mengdol : navy hoodie + khaki shorts + cream sneakers
#   - mengsoon: cream hoodie + coral ribbon + pink skirt + black shoes
#               + pink bow on the head + two big front teeth
#
# -Variant picks a design option (same meaning for both characters):
#   1  base          - two front teeth with a divider down the middle
#   2  solid teeth   - one wide tooth, NO divider line
#   3  no teeth      - smile only
#   4  round eyes    - bigger rounder eyes + extra sparkle, solid teeth
#   5  small head    - head scaled to 85%, longer body, solid teeth
#
# Every part is drawn on its own canvas and gets its OWN 1px outline, then the
# canvases are stacked. That is what gives the head a clean edge over the body.

$SZ = 64

function New-Canvas {
    $c = @()
    for ($y = 0; $y -lt $SZ; $y++) {
        $r = New-Object char[] $SZ
        for ($x = 0; $x -lt $SZ; $x++) { $r[$x] = '.' }
        $c += , $r
    }
    return , $c
}

function P($cv, $x, $y, [char]$ch) {
    $ix = [int]$x; $iy = [int]$y
    if ($ix -ge 0 -and $ix -lt 64 -and $iy -ge 0 -and $iy -lt 64) { $cv[$iy][$ix] = $ch }
}
function G($cv, $x, $y) {
    $ix = [int]$x; $iy = [int]$y
    if ($ix -ge 0 -and $ix -lt 64 -and $iy -ge 0 -and $iy -lt 64) { return $cv[$iy][$ix] }
    return [char]'.'
}
function Rect($cv, [int]$x0, [int]$y0, [int]$x1, [int]$y1, [char]$ch) {
    for ($y = $y0; $y -le $y1; $y++) { for ($x = $x0; $x -le $x1; $x++) { P $cv $x $y $ch } }
}
# NOTE: do not name this Erase / Clear - PowerShell resolves aliases before
# functions, so those names would call Remove-Item / Clear-Host instead.
function Punch($cv, [int]$x0, [int]$y0, [int]$x1, [int]$y1) { Rect $cv $x0 $y0 $x1 $y1 '.' }
# mirror the right edge off the left one - [math]::Round is banker's rounding,
# so rounding both ends independently would shift the row off centre by 1px
function Row($cv, [int]$y, [double]$hw, [char]$ch, [double]$dx = 0.0) {
    $x0 = [int][math]::Floor(31.5 + $dx - $hw + 0.5)
    # mirror the right edge off the left one so the row stays exactly centred
    $x1 = [int][math]::Round(63 + 2 * $dx) - $x0
    Rect $cv $x0 $y $x1 $y $ch
}
function Ell($cv, [double]$cx, [double]$cy, [double]$rx, [double]$ry, [char]$ch) {
    for ($y = [math]::Floor($cy - $ry); $y -le [math]::Ceiling($cy + $ry); $y++) {
        for ($x = [math]::Floor($cx - $rx); $x -le [math]::Ceiling($cx + $rx); $x++) {
            $dx = ($x - $cx) / $rx; $dy = ($y - $cy) / $ry
            if ($dx * $dx + $dy * $dy -le 1.0) { P $cv $x $y $ch }
        }
    }
}
# ellipse clipped to whatever is already painted (blush must stay on the head)
function EllIn($cv, [double]$cx, [double]$cy, [double]$rx, [double]$ry, [char]$ch) {
    for ($y = [math]::Floor($cy - $ry); $y -le [math]::Ceiling($cy + $ry); $y++) {
        for ($x = [math]::Floor($cx - $rx); $x -le [math]::Ceiling($cx + $rx); $x++) {
            $dx = ($x - $cx) / $rx; $dy = ($y - $cy) / $ry
            if ($dx * $dx + $dy * $dy -le 1.0 -and (G $cv $x $y) -ne '.') { P $cv $x $y $ch }
        }
    }
}
# recolour inside a box without ever growing the silhouette
function Tint($cv, [int]$x0, [int]$y0, [int]$x1, [int]$y1, [char]$ch) {
    for ($y = $y0; $y -le $y1; $y++) {
        for ($x = $x0; $x -le $x1; $x++) { if ((G $cv $x $y) -ne '.') { P $cv $x $y $ch } }
    }
}
function Outline($cv, [char]$ch) {
    $snap = @()
    for ($y = 0; $y -lt 64; $y++) { $snap += , ($cv[$y].Clone()) }
    $dirs = @(@(0, -1), @(0, 1), @(-1, 0), @(1, 0))
    for ($y = 0; $y -lt 64; $y++) {
        for ($x = 0; $x -lt 64; $x++) {
            if ($snap[$y][$x] -ne '.') { continue }
            foreach ($d in $dirs) {
                $nx = $x + $d[0]; $ny = $y + $d[1]
                if ($nx -ge 0 -and $nx -lt 64 -and $ny -ge 0 -and $ny -lt 64 -and $snap[$ny][$nx] -ne '.') {
                    $cv[$y][$x] = $ch; break
                }
            }
        }
    }
}
function Stack($dst, $src) {
    for ($y = 0; $y -lt 64; $y++) {
        for ($x = 0; $x -lt 64; $x++) { if ($src[$y][$x] -ne '.') { $dst[$y][$x] = $src[$y][$x] } }
    }
}
# 캔버스를 반시계로 90도 돌립니다.
# 침대에 누운 그림에 씁니다: 앞얼굴을 그대로 돌리면 정수리가 왼쪽(머리맡),
# 턱이 오른쪽(발치)을 향하고, 얼굴은 화면 위 = 천장을 봅니다.
#   (x, y)  ->  (y, 63 - x)
function Rotate-CCW($src) {
    $dst = New-Canvas
    for ($y = 0; $y -lt 64; $y++) {
        for ($x = 0; $x -lt 64; $x++) {
            if ($src[$y][$x] -ne '.') { P $dst $y (63 - $x) $src[$y][$x] }
        }
    }
    return , $dst
}

# move a whole canvas. Used by the 'lie' pose to slide the head onto a pillow.
function Shift-Canvas($src, [int]$dx, [int]$dy) {
    $dst = New-Canvas
    for ($y = 0; $y -lt 64; $y++) {
        for ($x = 0; $x -lt 64; $x++) {
            if ($src[$y][$x] -ne '.') { P $dst ($x + $dx) ($y + $dy) $src[$y][$x] }
        }
    }
    return , $dst
}
# A solid closed-eye stroke. $slope > 0 curves up in the middle (^ ^),
# $slope < 0 curves down (~ ~).
#
# Two things keep it a LINE instead of a row of dots:
#   1. we walk over integer X, not over an offset. Eye centres land on .5
#      (they sit on the eye bumps), and [math]::Round is banker's rounding, so
#      stepping the offset makes Round() land on the same column twice and skip
#      the next one entirely - that is exactly what made the old arc dotted.
#   2. each column is bridged to the previous one, because Round() still moves
#      a whole pixel at a time in Y and a 3px mark cannot reach across that.
function EyeArc($cv, [double]$ex, [double]$ey, [double]$rx, [double]$slope, [int]$thick, [char]$ch) {
    $prev = -999
    $x0 = [int][math]::Floor($ex - $rx)
    $x1 = [int][math]::Ceiling($ex + $rx)
    for ($x = $x0; $x -le $x1; $x++) {
        $y = [int][math]::Floor($ey + [math]::Abs($x - $ex) * $slope + 0.5)
        $lo = $y; $hi = $y + $thick - 1
        if ($prev -ne -999) {
            if ($prev -lt $lo) { $lo = $prev }
            if (($prev + $thick - 1) -gt $hi) { $hi = $prev + $thick - 1 }
        }
        for ($k = $lo; $k -le $hi; $k++) { if ((G $cv $x $k) -ne '.') { P $cv $x $k $ch } }
        $prev = $y
    }
}

# a thick rounded line - arms and legs are just this
function Limb($cv, [double]$x0, [double]$y0, [double]$x1, [double]$y1, [double]$r, [char]$ch) {
    for ($i = 0; $i -le 18; $i++) {
        $t = $i / 18.0
        Ell $cv ($x0 + ($x1 - $x0) * $t) ($y0 + ($y1 - $y0) * $t) $r $r $ch
    }
}

# ===================== HEAD SHAPE CONFIG =====================
# One place for every head number, so a variant can scale the whole head by
# rewriting this table instead of touching the drawing code.
function New-HeadConfig {
    return @{
        bumpDx = 14.0; bumpCy = 13.0; bumpRx = 10.0; bumpRy = 11.5
        prof   = @{
            3 = 4; 4 = 8; 5 = 11; 6 = 15; 7 = 18; 8 = 20; 9 = 21; 10 = 22; 11 = 22
            12 = 23; 13 = 23; 14 = 23; 15 = 23; 16 = 23; 17 = 23; 18 = 23; 19 = 23
            20 = 23; 21 = 23; 22 = 23; 23 = 23; 24 = 23; 25 = 22; 26 = 22; 27 = 22
            28 = 21; 29 = 21; 30 = 20; 31 = 18; 32 = 15; 33 = 10
        }
        eyeCy    = 13.5; eyeRx = 5.5; eyeRy = 7.0
        glintDx  = 0.5; glintDy = -4.5; glintW = 4.0; glintH = 4.0
        sparkle  = $false
        blushDx  = 17.0; blushCy = 22.5; blushRx = 4.5; blushRy = 2.0
        nostrilY = 20.0
        mouthMid = 24.8; mouthAmp = 2.4; mouthHW = 14.5; mouthX0 = 17.0; mouthX1 = 46.0
        jawCy    = 32.0; jawRx = 19.0; jawRy = 9.0
        headBot  = 33
        litTop   = 8
    }
}

# scale the whole head about the point (31.5, 1) - the top of the skull
function Scale-HeadConfig($c, [double]$s) {
    $n = @{}
    foreach ($k in $c.Keys) { $n[$k] = $c[$k] }
    foreach ($k in 'bumpDx', 'bumpRx', 'bumpRy', 'eyeRx', 'eyeRy', 'glintDx', 'glintDy',
        'glintW', 'glintH', 'blushDx', 'blushRx', 'blushRy', 'jawRx', 'jawRy',
        'mouthAmp', 'mouthHW') { $n[$k] = $c[$k] * $s }
    foreach ($k in 'bumpCy', 'eyeCy', 'blushCy', 'nostrilY', 'mouthMid', 'jawCy') {
        $n[$k] = 1 + ($c[$k] - 1) * $s
    }
    foreach ($k in 'mouthX0', 'mouthX1') { $n[$k] = 31.5 + ($c[$k] - 31.5) * $s }
    $n['headBot'] = [int][math]::Round(1 + ($c['headBot'] - 1) * $s)
    $n['litTop'] = [int][math]::Round(1 + ($c['litTop'] - 1) * $s)
    $p = @{}
    foreach ($y in $c['prof'].Keys) {
        $ny = [int][math]::Round(1 + ($y - 1) * $s)
        $nhw = $c['prof'][$y] * $s
        if (-not $p.ContainsKey($ny) -or $p[$ny] -lt $nhw) { $p[$ny] = $nhw }
    }
    $n['prof'] = $p
    return $n
}

function Get-HeadConfig([int]$v) {
    $c = New-HeadConfig
    if ($v -eq 0) {
        # the very first published version: no teeth, and the larger blush that
        # reaches out to the edge of the cheek
        $c['blushDx'] = 19.0; $c['blushCy'] = 23.0; $c['blushRx'] = 5.0; $c['blushRy'] = 3.5
    }
    if ($v -eq 4) {
        $c['bumpRx'] = 10.5; $c['bumpRy'] = 12.0
        $c['eyeCy'] = 14.0; $c['eyeRx'] = 6.8; $c['eyeRy'] = 7.6
        $c['glintDx'] = 0.5; $c['glintDy'] = -4.5; $c['glintW'] = 5.0; $c['glintH'] = 5.0
        $c['sparkle'] = $true
    }
    if ($v -eq 5) { $c = Scale-HeadConfig $c 0.85 }
    return $c
}

# teeth: 1 = split (divider down the middle), 2/4/5 = solid (no divider), 3 = none
function Get-TeethMode([int]$v) {
    if ($v -eq 1) { return 'split' }
    if ($v -eq 0 -or $v -eq 3) { return 'none' }
    return 'solid'
}

# ===================== HEAD =====================
# $dir  : down = face us, up = back of the head, side = face turned right
# $face : expression. Only 'down' and 'side' have a face at all.
function Draw-Head($cv, $c, [string]$teeth, [bool]$isBoy, [string]$dir = 'down', [string]$face = 'normal') {
    # Every facial feature is placed relative to this offset, so turning the
    # head sideways is just "slide the whole face 6px toward the ear".
    # NOTE: the face is NOT rotated for the side view.
    #
    # We tried it (slide the face over, shrink the far eye, lean the skull) and
    # it looked wrong every time. The reason is the design itself: this head is
    # two huge eye bumps and almost nothing else, so the moment the eyes stop
    # being symmetric the whole face reads as broken - there is no nose, no ear,
    # no hairline left to tell you "this is a head in profile".
    #
    # So the side view keeps the front face and only the BODY turns
    # (see Draw-Body: $sdx shifts the limbs, and the far arm goes dark).
    # Plenty of chibi games do exactly this - the face is the character, and
    # you do not throw it away just because they are walking left.
    $fdx = 0.0
    # a frown is the same parabola with the sign flipped
    $mouthSign = 1.0
    $mouthScale = 1.0
    if ($face -eq 'happy') { $mouthScale = 1.7 }
    if ($face -eq 'sad' -or $face -eq 'angry') { $mouthSign = -1.0 }
    if ($face -eq 'sleepy') { $mouthScale = 0.4 }
    # 부끄러움: 입은 작게 오므리고, 볼 대신 얼굴 전체가 달아오릅니다 (아래 blush 참고)
    if ($face -eq 'shy') { $mouthScale = 0.3 }
    $mouthAt = {
        param([int]$x)
        $xc = $x
        if ($xc -lt ($c.mouthX0 + $fdx)) { $xc = $c.mouthX0 + $fdx }
        if ($xc -gt ($c.mouthX1 + $fdx)) { $xc = $c.mouthX1 + $fdx }
        $t = ($xc - 31.5 - $fdx) / $c.mouthHW
        return [int][math]::Round($c.mouthMid + $mouthSign * $mouthScale * $c.mouthAmp * (1 - $t * $t))
    }

    # -- silhouette: two shallow eye bumps riding on a rounded jaw block
    #
    # Turning the head is NOT "slide the eyes sideways" - if the eyes move but
    # the bumps stay put, the eyeballs end up hanging off the skull and the
    # face looks wrong. So the bumps move first and the eyes are then placed
    # ON their own bump. The far bump also shrinks, the way a real head
    # foreshortens when it turns away from you.
    $farX = 31.5 - $c.bumpDx
    $nearX = 31.5 + $c.bumpDx
    $farRx = $c.bumpRx
    $profDx = 0.0
    Ell $cv $farX $c.bumpCy $farRx $c.bumpRy 'V'
    Ell $cv $nearX $c.bumpCy $c.bumpRx $c.bumpRy 'V'
    foreach ($k in $c.prof.Keys) { Row $cv $k $c.prof[$k] 'V' $profDx }

    # -- shading: bright on top, darker down the right side and under the chin
    Tint $cv 0 0 63 $c.litTop 'L'
    for ($y = 0; $y -lt 64; $y++) {
        $mn = -1; $mx = -1
        for ($x = 0; $x -lt 64; $x++) { if ($cv[$y][$x] -ne '.') { if ($mn -lt 0) { $mn = $x }; $mx = $x } }
        if ($mn -lt 0) { continue }
        for ($x = $mx - 3; $x -le $mx; $x++) { if ((G $cv $x $y) -ne '.') { P $cv $x $y 'v' } }
        for ($x = $mn; $x -le $mn + 1; $x++) { if ((G $cv $x $y) -ne '.') { P $cv $x $y 'L' } }
    }
    Tint $cv 0 ($c.headBot - 1) 63 $c.headBot 'v'

    # -- back of the head: no face at all. Just a soft crease between the two
    #    eye bumps and a little extra shade where the neck meets the hood.
    if ($dir -eq 'up') {
        for ($y = 3; $y -le 17; $y++) {
            for ($x = 30; $x -le 33; $x++) { if ((G $cv $x $y) -ne '.') { P $cv $x $y 'v' } }
        }
        Tint $cv 0 ($c.headBot - 3) 63 $c.headBot 'v'
        return
    }

    # -- cream jaw: inside the head, below the smile, inside a wide ellipse
    for ($y = 15; $y -le 45; $y++) {
        for ($x = 0; $x -lt 64; $x++) {
            if ((G $cv $x $y) -eq '.') { continue }
            if ($y -le (& $mouthAt $x)) { continue }
            $dx = ($x - 31.5 - $fdx) / $c.jawRx; $dy = ($y - $c.jawCy) / $c.jawRy
            if ($dx * $dx + $dy * $dy -le 1.0) { P $cv $x $y 'C' }
        }
    }
    Tint $cv 45 15 63 $c.headBot 'c'                        # jaw shade on the right
    Tint $cv 0 $c.headBot 63 $c.headBot 'c'                 # and along the very bottom

    # -- eyes ------------------------------------------------------------
    # each eye sits in the middle of its own bump (see the silhouette above)
    $elx = $farX                        # far eye when the head is turned
    $erx = $nearX                       # near eye
    $lrx = $c.eyeRx
    # (side view keeps the front face - see the note at the top of this function)

    # snapshot before the eyes go on, so an eyelid can put the skin back
    $preEye = @()
    for ($y = 0; $y -lt 64; $y++) { $preEye += , ($cv[$y].Clone()) }

    if ($face -eq 'happy' -or $face -eq 'shy' -or $face -eq 'laugh') {
        # A closed eye is one SOLID stroke, never a row of dots.
        #   happy / laugh : ^ ^   arc pulled up in the middle
        #   shy           : ~ ~   arc pushed down, "can't look at you"
        # EyeArc bridges the gap between neighbouring columns, which is the
        # whole trick - Round() jumps a full pixel at a time and a 2px mark
        # cannot reach across that on its own, so it comes out dotted.
        $slope = 0.6; $thick = 2
        if ($face -eq 'laugh') { $slope = 0.85; $thick = 3 }
        if ($face -eq 'shy') { $slope = -0.45; $thick = 3 }
        foreach ($e in @(@($elx, $lrx), @($erx, $c.eyeRx))) {
            $ex = $e[0]; $rx = $e[1]
            $base = $c.eyeCy + 2.0
            if ($face -eq 'shy') { $base = $c.eyeCy + 4.0 }
            EyeArc $cv $ex $base ($rx + 0.5) $slope $thick 'K'
        }
        # 눈물이 핑 - 웃겨 죽겠을 때 눈꼬리에서 튀어나오는 눈물
        if ($face -eq 'laugh') {
            foreach ($e in @(@($elx, -1.0), @($erx, 1.0))) {
                $ex = [int][math]::Round($e[0] + $e[1] * ($c.eyeRx + 2.5))
                $ey = [int][math]::Round($c.eyeCy + 3.0)
                for ($k = 0; $k -lt 5; $k++) {
                    $tx = $ex + [int]($e[1] * ($k * 0.5))
                    Rect $cv $tx ($ey + $k) ($tx + 1) ($ey + $k) '1'
                }
                Rect $cv $ex $ey ($ex + 1) ($ey + 1) 'W'
                Ell $cv ($ex + $e[1] * 2.5) ($ey + 6.0) 2.2 2.6 '1'
                P $cv ([int]($ex + $e[1] * 2.5)) ($ey + 5) 'W'
            }
        }
    }
    else {
        $ery = $c.eyeRy
        $ecy = $c.eyeCy
        $erxN = $c.eyeRx
        if ($face -eq 'surprise') { $ery = $c.eyeRy * 1.15; $erxN = $c.eyeRx * 1.35; $lrx = $lrx * 1.35 }
        if ($face -eq 'sad') { $ecy = $c.eyeCy + 1.0 }

        Ell $cv $elx $ecy $lrx $ery 'K'
        Ell $cv $erx $ecy $erxN $ery 'K'
        foreach ($e in @(@($elx, $lrx), @($erx, $erxN))) {
            $ex = $e[0]; $rx = $e[1]
            $gw = [int]$c.glintW
            if ($rx -lt $c.eyeRx) { $gw = [math]::Max(2, $gw - 2) }
            $gx = [int][math]::Round($ex + $c.glintDx); $gy = [int][math]::Round($ecy + $c.glintDy)
            Rect $cv $gx $gy ($gx + $gw - 1) ($gy + [int]$c.glintH - 1) 'W'
            if ($c.sparkle -or $face -eq 'surprise') {
                $sx = [int][math]::Round($ex - $rx * 0.5)
                $sy = [int][math]::Round($ecy + $ery * 0.4)
                Rect $cv $sx $sy ($sx + 1) ($sy + 1) 'W'
            }
        }

        # eyelids = paint the skin back over the top of the eye, then a dark rim
        $lidCut = -1
        if ($face -eq 'sleepy') { $lidCut = [int][math]::Round($ecy + $ery * 0.15) }
        if ($face -eq 'sad') { $lidCut = [int][math]::Round($ecy - $ery * 0.40) }
        if ($lidCut -ge 0) {
            for ($y = 0; $y -le $lidCut; $y++) {
                for ($x = 0; $x -lt 64; $x++) {
                    if ($cv[$y][$x] -eq 'K' -or $cv[$y][$x] -eq 'W') { P $cv $x $y $preEye[$y][$x] }
                }
            }
            for ($x = 0; $x -lt 64; $x++) {
                $below = G $cv $x ($lidCut + 1)
                if ($below -eq 'K' -or $below -eq 'W') { P $cv $x $lidCut 'E' }
            }
        }
    }

    # -- angry eyebrows: slanted down toward the middle of the face
    if ($face -eq 'angry') {
        foreach ($e in @(@($elx, 1.0), @($erx, -1.0))) {
            $ex = $e[0]; $slope = $e[1]
            for ($k = 0; $k -le 8; $k++) {
                $bx = [int][math]::Round($ex - 4 + $k)
                $by = [int][math]::Round($c.eyeCy - $c.eyeRy - 1 + ($k - 4) * 0.55 * $slope)
                for ($t = 0; $t -lt 2; $t++) {
                    if ((G $cv $bx ($by + $t)) -ne '.') { P $cv $bx ($by + $t) 'E' }
                }
            }
        }
    }

    # -- a tear on the near cheek
    if ($face -eq 'sad') {
        $tx = [int][math]::Round($erx + $c.eyeRx * 0.55)
        $ty = [int][math]::Round($c.eyeCy + $c.eyeRy + 1)
        for ($k = 0; $k -lt 4; $k++) {
            if ((G $cv $tx ($ty + $k)) -ne '.') { P $cv $tx ($ty + $k) '1' }
            if ((G $cv ($tx + 1) ($ty + $k)) -ne '.') { P $cv ($tx + 1) ($ty + $k) '1' }
        }
        if ((G $cv $tx $ty) -ne '.') { P $cv $tx $ty 'W' }
    }

    # -- nostrils
    $ny = [int][math]::Round($c.nostrilY)
    Rect $cv ([int](29 + $fdx)) $ny ([int](30 + $fdx)) ($ny + 1) 'Z'
    Rect $cv ([int](33 + $fdx)) $ny ([int](34 + $fdx)) ($ny + 1) 'Z'

    # -- blush
    if ($face -eq 'shy') {
        # 얼굴이 벌겋게 달아오릅니다. 반드시 좌우 대칭이어야 합니다.
        #
        # ★ 함정: 머리의 밑칠은 좌우 대칭이 아닙니다. Draw-Head 는 오른쪽
        #   1/4 을 크림색(`c`)으로 덮어서 턱 그늘을 만듭니다. 그래서 "지금
        #   무슨 색인지 보고 칠할 색을 고르면" 왼쪽은 빨강, 오른쪽은 주황이
        #   되어 버립니다 - 오른쪽만 옅어 보이던 이유가 이것이었습니다.
        #
        #   그래서 칠할 색은 [b]밑칠이 아니라 좌표[/b]로 정합니다. 입선 아래이고
        #   턱 타원 안이면 턱, 아니면 얼굴. 좌표는 좌우가 완전히 같으므로
        #   왼쪽 절반만 계산해서 x 를 뒤집어 그대로 복사하면 됩니다.
        $cxf = 31.5 + $fdx
        $paint = {
            param([int]$x, [int]$y, [char]$ch)
            $mx = [int][math]::Round(2.0 * $cxf) - $x
            foreach ($px in @($x, $mx)) {
                $g = G $cv $px $y
                # 눈 · 콧구멍 · 외곽선 · 빈칸은 건드리지 않습니다
                if ($g -eq '.' -or $g -eq 'K' -or $g -eq 'W' -or $g -eq 'E' -or $g -eq 'Z') { continue }
                P $cv $px $y $ch
            }
        }
        for ($y = [int]($c.blushCy - 14); $y -le [int]($c.blushCy + 12); $y++) {
            for ($x = [int]($cxf - 24); $x -le [int][math]::Floor($cxf); $x++) {
                $dxw = ($x - $cxf) / 23.0
                $dyw = ($y - ($c.blushCy - 3.5)) / 12.0
                if ($dxw * $dxw + $dyw * $dyw -gt 1.0) { continue }
                # 턱인가? (입선 아래 + 턱 타원 안) - 밑칠이 아니라 좌표로 판단
                $jx = ($x - $cxf) / $c.jawRx
                $jy = ($y - $c.jawCy) / $c.jawRy
                if ($y -gt (& $mouthAt $x) -and ($jx * $jx + $jy * $jy) -le 1.0) {
                    & $paint $x $y 'S'
                    continue
                }
                $dxc = ($x - ($cxf - $c.blushDx)) / 8.0
                $dyc = ($y - $c.blushCy) / 5.0
                if ($dxc * $dxc + $dyc * $dyc -le 1.0) { & $paint $x $y 'k' }
                else { & $paint $x $y 'j' }
            }
        }
        # 볼마다 만화식 빗금 두 줄. 이것도 좌우가 거울처럼 뒤집힙니다.
        foreach ($s in @(-3.0, 0.0)) {
            for ($t = 0; $t -lt 6; $t++) {
                $px = [int][math]::Floor($cxf - $c.blushDx + $s - $t * 0.45 + 0.5)
                $py = [int][math]::Floor($c.blushCy - 2.5 + $t + 0.5)
                if ((G $cv $px $py) -eq 'k') { & $paint $px $py 'W' }
            }
        }
    }
    else {
        EllIn $cv (31.5 - $c.blushDx + $fdx) $c.blushCy $c.blushRx $c.blushRy 'S'
        EllIn $cv (31.5 + $c.blushDx + $fdx) $c.blushCy $c.blushRx $c.blushRy 'S'
    }
    # -- mouth
    if ($face -eq 'surprise') {
        # a small round "오!" instead of a smile
        EllIn $cv (31.5 + $fdx) ($c.mouthMid + 2.5) 4.0 4.5 'E'
        EllIn $cv (31.5 + $fdx) ($c.mouthMid + 2.5) 2.5 3.0 'z'
    }
    elseif ($face -eq 'laugh') {
        # 푸하하 - 입을 크게 벌리고 웃는 입. 개구리라 넓지만, 턱 전체를
        # 잡아먹으면 립스틱처럼 보여서 세로는 얕게 둡니다.
        $mcy = $c.mouthMid + 2.6
        EllIn $cv (31.5 + $fdx) $mcy 9.5 4.6 'E'
        EllIn $cv (31.5 + $fdx) ($mcy + 0.3) 7.8 3.4 'q'
        EllIn $cv (31.5 + $fdx) ($mcy + 2.4) 4.2 1.8 'r'      # 혀
        for ($x = [int](22 + $fdx); $x -le [int](41 + $fdx); $x++) {   # 윗니
            $ty = [int][math]::Floor($mcy - 2.4 + 0.5)
            for ($k = 0; $k -lt 2; $k++) {
                if ((G $cv $x ($ty + $k)) -eq 'q') { P $cv $x ($ty + $k) 'W' }
            }
        }
    }
    else {
        # 2px thick so it still reads at 1x
        for ($x = [int]($c.mouthX0 + $fdx); $x -le [int]($c.mouthX1 + $fdx); $x++) {
            $my = & $mouthAt $x
            if ((G $cv $x $my) -ne '.') { P $cv $x $my 'E' }
            if ((G $cv $x ($my - 1)) -ne '.') { P $cv $x ($my - 1) 'E' }
        }
    }
    # -- front teeth hanging off the smile into the jaw.
    #    mengsoon's are the big ones; mengdol gets a narrower pair.
    #    Only makes sense on a smiling face.
    if ($teeth -ne 'none' -and ($face -eq 'normal' -or $face -eq 'happy')) {
        # hang off the smile, but stop short of the chin so they float in the jaw
        $tTop = (& $mouthAt ([int](31 + $fdx))) - 1
        if ($isBoy) { $bx0 = 28; $bx1 = 35; $ix0 = 29; $ix1 = 34; $th = 3 }
        else { $bx0 = 27; $bx1 = 36; $ix0 = 28; $ix1 = 35; $th = 4 }
        $bx0 += [int]$fdx; $bx1 += [int]$fdx; $ix0 += [int]$fdx; $ix1 += [int]$fdx
        $th = [math]::Min($th, $c.headBot - $tTop - 2)
        if ($th -ge 2) {
            Rect $cv $bx0 $tTop $bx1 ($tTop + $th + 1) 'E'
            Rect $cv $ix0 ($tTop + 1) $ix1 ($tTop + $th) 'W'
            if ($teeth -eq 'split') { Rect $cv ([int](31 + $fdx)) ($tTop + 1) ([int](32 + $fdx)) ($tTop + $th) 'E' }
        }
    }
}

# ===================== BODY =====================
# $t0 is the first body row (just under the head), so a smaller head simply
# means a longer hoodie - everything from the hem down stays put.
function Draw-Body($cv, [string]$who, [int]$t0, [string]$dir = 'down', [int]$step = 0) {
    $isBoy = ($who -eq 'mengdol')
    $isUp = ($dir -eq 'up')
    $isSide = ($dir -eq 'side')
    # turning sideways slides the limbs a few px toward the camera-near side
    $sdx = 0
    if ($isSide) { $sdx = 3 }
    if ($isBoy) { $top = [char]'H'; $topS = [char]'h'; $topD = [char]'J' }
    else { $top = [char]'F'; $topS = [char]'f'; $topD = [char]'i' }

    # -- walk cycle. The lifted foot gets a shorter leg (bent knee) and the
    #    shoe rides up with it; the arms swing the opposite way.
    $dyL = 0; $dyR = 0; $handL = 0; $handR = 0
    if ($step -eq 1) { $dyL = -2; $handL = 1; $handR = -1 }
    if ($step -eq -1) { $dyR = -2; $handL = -1; $handR = 1 }

    # -- hood bunched at the neck, then the torso and sleeves over it
    Rect $cv 22 $t0 41 $t0 $topD
    Rect $cv 20 ($t0 + 1) 43 ($t0 + 1) $topD
    Rect $cv 19 ($t0 + 2) 44 49 $top
    Rect $cv 16 ($t0 + 2) 19 ($t0 + 2) $topS
    Rect $cv 44 ($t0 + 2) 47 ($t0 + 2) $topS
    Rect $cv 15 ($t0 + 3) 19 47 $topS
    Rect $cv 44 ($t0 + 3) 48 47 $topS

    if ($isUp) {
        # from behind you see the hood itself, draped over the shoulders
        Rect $cv 22 ($t0 + 1) 41 ($t0 + 8) $topS
        Rect $cv 20 ($t0 + 3) 43 ($t0 + 8) $topS
        Ell $cv 31.5 ($t0 + 7) 11.5 6.0 $topS
        Ell $cv 31.5 ($t0 + 6) 9.0 4.5 $topD
        Rect $cv 24 ($t0 + 1) 39 ($t0 + 2) $topD       # the opening rim
        Rect $cv 31 ($t0 + 3) 32 ($t0 + 10) $topD      # spine seam
    }
    else {
        # -- green throat showing in the hood opening
        Rect $cv (28 + $sdx) $t0 (35 + $sdx) $t0 'V'
        Rect $cv (30 + $sdx) ($t0 + 1) (33 + $sdx) ($t0 + 1) 'V'
    }

    Rect $cv 19 ($t0 + 3) 19 45 $topD    # armhole seams, so the arms read as arms
    Rect $cv 44 ($t0 + 3) 44 45 $topD
    Tint $cv 40 ($t0 + 2) 44 49 $topS    # right-side shade
    Tint $cv 15 46 19 47 $topD           # cuffs
    Tint $cv 44 46 48 47 $topD
    Rect $cv 19 48 44 49 $topD           # hem rib
    # turned sideways: the far arm falls behind the body, so it goes dark
    if ($isSide) { Tint $cv 15 ($t0 + 2) 19 47 $topD }

    if ($isBoy) {
        if (-not $isUp) {
            Rect $cv (24 + $sdx) 43 (39 + $sdx) 43 'J'    # kangaroo pocket, as an outline
            Rect $cv (24 + $sdx) 47 (39 + $sdx) 47 'J'
            Rect $cv (24 + $sdx) 43 (24 + $sdx) 47 'J'
            Rect $cv (39 + $sdx) 43 (39 + $sdx) 47 'J'
            Tint $cv (25 + $sdx) 44 (38 + $sdx) 46 'h'
            Rect $cv (29 + $sdx) ($t0 + 2) (29 + $sdx) ($t0 + 6) 'W'      # drawstrings
            Rect $cv (34 + $sdx) ($t0 + 2) (34 + $sdx) ($t0 + 6) 'W'
            Rect $cv (28 + $sdx) ($t0 + 6) (29 + $sdx) ($t0 + 8) 'W'      # aglets
            Rect $cv (34 + $sdx) ($t0 + 6) (35 + $sdx) ($t0 + 8) 'W'
        }

        Rect $cv 20 50 43 55 'T'          # shorts
        Tint $cv 39 50 43 55 't'
        Rect $cv 31 50 32 54 't'          # centre seam
        Rect $cv 20 55 43 55 't'          # hem
        Punch $cv 30 55 33 55             # split between the legs

        Rect $cv (23 + $sdx) 56 (29 + $sdx) (58 + $dyL) 'V'          # legs
        Rect $cv (34 + $sdx) 56 (40 + $sdx) (58 + $dyR) 'V'
        Tint $cv (27 + $sdx) 56 (29 + $sdx) (58 + $dyL) 'v'
        Tint $cv (38 + $sdx) 56 (40 + $sdx) (58 + $dyR) 'v'

        Rect $cv (21 + $sdx) (59 + $dyL) (29 + $sdx) (59 + $dyL) 'F'   # sneakers
        Rect $cv (20 + $sdx) (60 + $dyL) (30 + $sdx) (60 + $dyL) 'F'
        Rect $cv (19 + $sdx) (61 + $dyL) (30 + $sdx) (63 + $dyL) 'F'
        Rect $cv (34 + $sdx) (59 + $dyR) (42 + $sdx) (59 + $dyR) 'F'
        Rect $cv (33 + $sdx) (60 + $dyR) (43 + $sdx) (60 + $dyR) 'F'
        Rect $cv (33 + $sdx) (61 + $dyR) (44 + $sdx) (63 + $dyR) 'F'
        Tint $cv (27 + $sdx) (60 + $dyL) (30 + $sdx) (63 + $dyL) 'f'   # outer-side shade
        Tint $cv (41 + $sdx) (60 + $dyR) (44 + $sdx) (63 + $dyR) 'f'
        Rect $cv (19 + $sdx) (63 + $dyL) (30 + $sdx) (63 + $dyL) 'f'   # sole
        Rect $cv (33 + $sdx) (63 + $dyR) (44 + $sdx) (63 + $dyR) 'f'
    }
    else {
        # coral ribbon: hollow loops (the hoodie shows through) + two tails,
        # the same way the reference draws it. It is worn at the front, so the
        # back view does not have one.
        if (-not $isUp) {
            Ell $cv (27.5 + $sdx) 38.5 3.5 3 'R'       # loops
            Ell $cv (35.5 + $sdx) 38.5 3.5 3 'R'
            Ell $cv (27.5 + $sdx) 38.5 1.5 1.5 $top
            Ell $cv (35.5 + $sdx) 38.5 1.5 1.5 $top
            Rect $cv (30 + $sdx) 37 (33 + $sdx) 40 'R' # knot
            Rect $cv (31 + $sdx) 38 (32 + $sdx) 39 '0'
            Rect $cv (29 + $sdx) 41 (30 + $sdx) 42 'R' # tails
            Rect $cv (28 + $sdx) 43 (29 + $sdx) 45 'R'
            Rect $cv (33 + $sdx) 41 (34 + $sdx) 42 'R'
            Rect $cv (34 + $sdx) 43 (35 + $sdx) 45 'R'
        }

        Rect $cv 19 49 44 50 '7'          # skirt
        Rect $cv 18 51 45 52 '7'
        Rect $cv 17 53 46 55 '7'
        foreach ($px in 23, 29, 34, 40) { Rect $cv $px 50 $px 54 '0' }
        Tint $cv 41 49 46 55 '0'          # right-side shade
        Rect $cv 17 55 46 55 '0'          # hem trim

        Rect $cv (23 + $sdx) 56 (29 + $sdx) (58 + $dyL) 'B'   # socks
        Rect $cv (34 + $sdx) 56 (40 + $sdx) (58 + $dyR) 'B'

        Rect $cv (21 + $sdx) (59 + $dyL) (29 + $sdx) (59 + $dyL) 'K'   # black shoes
        Rect $cv (20 + $sdx) (60 + $dyL) (30 + $sdx) (60 + $dyL) 'K'
        Rect $cv (19 + $sdx) (61 + $dyL) (30 + $sdx) (63 + $dyL) 'K'
        Rect $cv (34 + $sdx) (59 + $dyR) (42 + $sdx) (59 + $dyR) 'K'
        Rect $cv (33 + $sdx) (60 + $dyR) (43 + $sdx) (60 + $dyR) 'K'
        Rect $cv (33 + $sdx) (61 + $dyR) (44 + $sdx) (63 + $dyR) 'K'
        Rect $cv (21 + $sdx) (61 + $dyL) (26 + $sdx) (61 + $dyL) 'J'   # shine
        Rect $cv (35 + $sdx) (61 + $dyR) (40 + $sdx) (61 + $dyR) 'J'
    }

    # -- hands last so they sit over the skirt / shorts
    $farHand = 'V'
    if ($isSide) { $farHand = 'v' }       # the far hand is in the body's shadow
    Ell $cv (17 + $sdx) (50 + $handL) 3.5 3 $farHand
    Ell $cv (46 + $sdx) (50 + $handR) 3.5 3 'V'
    Ell $cv (47.5 + $sdx) (50 + $handR) 2 2.5 'v'
}

# ===================== BARE BODY =====================
# Memory 1 happens in a bathroom, so the two of them have no clothes on.
# It is drawn as a plain frog: green all over with a cream belly, webbed feet,
# and no shoes. The head bow stays on mengsoon - without clothes it is the only
# thing left that tells the two of them apart at a glance.
#
# $pose moves only the arms:
#   stand  - hanging at the sides
#   guard  - both fists up in front of the chest (boxing stance)
#   punch1 - LEFT fist thrown out ("one")
#   punch2 - RIGHT fist thrown out ("two")
#   laugh  - both hands clutching the belly
function Draw-BodyNude($cv, [string]$who, [int]$t0, [string]$pose, [int]$step) {
    # -- torso. Width is matched to the clothed body (x 15..48) on purpose:
    #    a narrower one makes the already-huge head look like it is going to
    #    snap the neck.
    Rect $cv 26 $t0 37 ($t0 + 3) 'V'                  # neck
    Ell $cv 31.5 ($t0 + 8) 13.5 8.5 'V'               # chest
    Rect $cv 19 ($t0 + 6) 44 ($t0 + 13) 'V'
    # 골반. 예전에는 이게 y58 까지 내려와서 다리 사이를 메워 버렸고,
    # 그래서 하반신이 통짜 덩어리로 보였습니다. 이제 y51 에서 끝나고,
    # 다리는 그 아래에서 확실하게 둘로 갈라집니다.
    Ell $cv 31.5 ($t0 + 12) 12.0 5.5 'V'

    # -- 다리. 허벅지는 굵고 종아리로 갈수록 가늘어집니다.
    $dyL = 0; $dyR = 0
    if ($step -eq 1) { $dyL = -2 }
    if ($step -eq -1) { $dyR = -2 }
    foreach ($lg in @(@(26.5, $dyL, -1), @(36.5, $dyR, 1))) {
        $lx = [double]$lg[0]; $dy = [int]$lg[1]; $sd = [int]$lg[2]
        Ell $cv $lx ($t0 + 14.0) 4.5 4.5 'V'                       # 허벅지 위쪽
        Rect $cv ([int]($lx - 4)) ($t0 + 14) ([int]($lx + 4)) (53 + $dy) 'V'
        Rect $cv ([int]($lx - 3)) (53 + $dy) ([int]($lx + 3)) (58 + $dy) 'V'   # 종아리
    }
    # 다리 안쪽(그늘)과 바깥쪽(빛)
    Tint $cv 29 ($t0 + 14) 31 58 'v'
    Tint $cv 38 ($t0 + 14) 41 58 'v'

    # -- cream belly (몸 밖으로 새지 않도록 EllIn 으로 자릅니다)
    EllIn $cv 31.0 ($t0 + 11) 9.5 7.0 'C'
    EllIn $cv 34.5 ($t0 + 12) 6.5 5.0 'c'             # its shaded side

    # -- light on top, shade down the right (same as the head)
    Tint $cv 0 $t0 63 ($t0 + 3) 'L'
    Tint $cv 42 $t0 63 ($t0 + 18) 'v'

    # -- webbed feet, splayed outward
    Ell $cv 25.0 (60 + $dyL) 7.5 3.5 'V'
    Ell $cv 38.0 (60 + $dyR) 7.5 3.5 'V'
    Tint $cv 41 (57 + $dyR) 47 63 'v'
    Tint $cv 31 57 32 63 'Z'                          # 두 발 사이 경계
    foreach ($f in @(@(25, $dyL), @(38, $dyR))) {
        $fx = [int]$f[0]; $fd = [int]$f[1]
        Rect $cv ($fx - 3) (59 + $fd) ($fx - 3) (62 + $fd) 'Z'    # toe seams
        Rect $cv ($fx + 3) (59 + $fd) ($fx + 3) (62 + $fd) 'Z'
    }

    # -- arms. Shoulders are fixed; only the hand target moves.
    $shLx = 21.0; $shRx = 42.0; $shY = $t0 + 7.0
    $fistR = 4.5
    switch ($pose) {
        'guard' { $hL = @(25.0, 40.0); $hR = @(38.0, 40.0) }
        'punch1' { $hL = @(6.0, 44.0); $hR = @(38.0, 40.0); $fistR = 5.5 }
        'punch2' { $hL = @(25.0, 40.0); $hR = @(57.0, 44.0); $fistR = 5.5 }
        'laugh' { $hL = @(24.0, 50.0); $hR = @(39.0, 50.0) }
        # 뿡! 두 팔을 옆으로 활짝 (미니게임에서 몸을 살짝 굽히는 건 코드가 합니다)
        'fart' { $hL = @(11.0, 41.0); $hR = @(52.0, 41.0) }
        default { $hL = @(14.0, 52.0); $hR = @(49.0, 52.0) }
    }
    Limb $cv $shLx $shY $hL[0] $hL[1] 3.2 'V'
    Limb $cv $shRx $shY $hR[0] $hR[1] 3.2 'V'
    Ell $cv $hL[0] $hL[1] $fistR ($fistR - 0.5) 'V'
    Ell $cv $hR[0] $hR[1] $fistR ($fistR - 0.5) 'V'
    Ell $cv ($hL[0] - 1) ($hL[1] - 1) ($fistR - 2.0) ($fistR - 2.2) 'L'   # knuckle light
    Ell $cv ($hR[0] + 1) ($hR[1] + 1) ($fistR - 2.0) ($fistR - 2.2) 'v'   # ...and shade
}

# ===================== BOW (mengsoon only) =====================
# Tall at the outer tips, pinched at the knot -> reads as a bow, not a capsule.
function Draw-Bow($cv) {
    for ($x = 20; $x -le 43; $x++) {
        $d = [math]::Abs($x - 31.5)
        if ($d -le 2.0) { Rect $cv $x 1 $x 6 '6' }
        elseif ($d -le 4.5) { Rect $cv $x 3 $x 5 '6' }
        elseif ($d -le 8.0) { Rect $cv $x 1 $x 6 '6' }
        elseif ($d -le 10.5) { Rect $cv $x 0 $x 7 '6' }
        else { Rect $cv $x 2 $x 5 '6' }
    }
    Tint $cv 32 0 63 7 '7'         # right loop sits in shade
    Tint $cv 0 6 63 7 '7'          # underside
    Rect $cv 29 1 34 6 '7'         # knot
    Rect $cv 30 2 33 5 '0'
    Rect $cv 23 1 25 2 'W'         # highlight on the left loop
}

# ===================== ASSEMBLE =====================
$cfg = Get-HeadConfig $Variant
$teethMode = Get-TeethMode $Variant
$isBoy = ($Who -eq 'mengdol')

$canvas = New-Canvas
$headDx = 0; $headDy = 0
$lieRotate = $false

if ($Pose -eq 'lie') {
    # 침대에 누운 그림.
    #
    # ★ 얼굴이 [b]천장[/b]을 봅니다.
    #   침대는 옆에서 본 모습이라 머리맡이 왼쪽, 발치가 오른쪽입니다.
    #   등을 대고 누우면 정수리가 왼쪽, 턱이 오른쪽을 향하고 얼굴은 위를
    #   봅니다. 그래서 앞얼굴을 그린 뒤 [b]반시계로 90도 돌립니다[/b]
    #   (Rotate-CCW). 눈 두 개가 위아래로 나란히 놓이는 게 정상입니다.
    #
    #   돌리지 않고 앞얼굴 그대로 두면 "누운 게 아니라 서 있는 얼굴을
    #   침대에 얹어 놓은" 그림이 됩니다.
    if ($isBoy) { $lTop = [char]'H'; $lTopS = [char]'h'; $lTopD = [char]'J' }
    else { $lTop = [char]'F'; $lTopS = [char]'f'; $lTopD = [char]'i' }
    $lieRotate = $true
    $headDx = 2; $headDy = 4
    $torso = New-Canvas
    Rect $torso 30 22 63 42 $lTop            # 몸통 (발치 쪽으로 이어짐)
    Ell $torso 41.0 32.0 12.0 10.5 $lTop     # 어깨
    Tint $torso 0 34 63 63 $lTopS            # 아래쪽은 그늘
    Ell $torso 34.0 32.0 8.5 10.0 $lTopD     # 목 뒤에 뭉친 후드
    Ell $torso 58.0 44.0 4.5 4.0 'V'         # 이불 밖으로 나온 손
    Outline $torso 'E'
    Stack $canvas $torso
}
else {
    $body = New-Canvas
    if ($Nude) { Draw-BodyNude $body $Who ($cfg.headBot + 1) $Pose $Step }
    else { Draw-Body $body $Who ($cfg.headBot + 1) $Dir $Step }
    Outline $body 'E'
    Stack $canvas $body
    # doubled over laughing: the head drops and tips forward
    if ($Pose -eq 'laugh') { $headDx = 2; $headDy = 3 }
}

$head = New-Canvas
Draw-Head $head $cfg $teethMode $isBoy $Dir $Face
Outline $head 'E'
if ($lieRotate) { $head = Rotate-CCW $head }
if ($headDx -ne 0 -or $headDy -ne 0) { $head = Shift-Canvas $head $headDx $headDy }
Stack $canvas $head

if (-not $isBoy) {
    $bow = New-Canvas
    Draw-Bow $bow
    Outline $bow 'E'
    if ($lieRotate) { $bow = Rotate-CCW $bow }
    if ($headDx -ne 0 -or $headDy -ne 0) { $bow = Shift-Canvas $bow $headDx $headDy }
    Stack $canvas $bow
}

# ===================== SAVE =====================
$lines = @()
for ($y = 0; $y -lt 64; $y++) { $lines += (-join $canvas[$y]) }
if ($Out -eq '') { $Out = Join-Path $PSScriptRoot ('art\' + $Who + '_idle.txt') }
Set-Content -Path $Out -Value $lines -Encoding ASCII
$bad = 0
foreach ($l in $lines) { if ($l.Length -ne 64) { $bad++ } }
Write-Output "$Out  variant=$Variant dir=$Dir step=$Step face=$Face  rows=$($lines.Count)  badwidth=$bad"
