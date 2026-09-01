param(
    [string]$Who = 'mengdol',
    [int]$Variant = 1,
    [string]$Out = '',
    # which way the character is facing
    [ValidateSet('down', 'up', 'side')][string]$Dir = 'down',
    # walk cycle: 0 = standing, 1 = left foot up, -1 = right foot up
    [int]$Step = 0,
    # face expression (only drawn when Dir is down or side)
    [ValidateSet('normal', 'happy', 'surprise', 'sad', 'angry', 'sleepy', 'shy')][string]$Face = 'normal',
    # no clothes - the bare frog body (memory 1 is set in a bathroom)
    [switch]$Nude,
    # what the body is doing. 'lie' ignores Dir/Step and draws the head
    # resting on a pillow with a shoulder stub, for the bed.
    [ValidateSet('stand', 'guard', 'punch1', 'punch2', 'laugh', 'lie')][string]$Pose = 'stand'
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
    # blushing / embarrassed: squeezed-shut eyes and a huge blush
    if ($face -eq 'shy') {
        $mouthScale = 0.3
        $c = $c.Clone()
        $c['blushDx'] = $c['blushDx'] * 0.92
        $c['blushRx'] = $c['blushRx'] * 1.9
        $c['blushRy'] = $c['blushRy'] * 2.2
    }

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

    if ($face -eq 'happy' -or $face -eq 'shy') {
        # ^ ^  : eyes squeezed shut. No eyeball, just two arcs.
        # 'shy' uses a flatter arc so it reads as "looking away", not "laughing".
        $slope = 0.6
        if ($face -eq 'shy') { $slope = 0.25 }
        foreach ($e in @(@($elx, $lrx), @($erx, $c.eyeRx))) {
            $ex = $e[0]; $rx = $e[1]
            for ($dx = - [int]$rx; $dx -le [int]$rx; $dx++) {
                $by = [int][math]::Round($c.eyeCy + 2.0 + [math]::Abs($dx) * $slope)
                for ($k = 0; $k -lt 2; $k++) {
                    if ((G $cv ([int]($ex + $dx)) ($by + $k)) -ne '.') { P $cv ([int]($ex + $dx)) ($by + $k) 'K' }
                }
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
    EllIn $cv (31.5 - $c.blushDx + $fdx) $c.blushCy $c.blushRx $c.blushRy 'S'
    EllIn $cv (31.5 + $c.blushDx + $fdx) $c.blushCy $c.blushRx $c.blushRy 'S'

    # -- mouth
    if ($face -eq 'surprise') {
        # a small round "오!" instead of a smile
        EllIn $cv (31.5 + $fdx) ($c.mouthMid + 2.5) 4.0 4.5 'E'
        EllIn $cv (31.5 + $fdx) ($c.mouthMid + 2.5) 2.5 3.0 'z'
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
    Ell $cv 31.5 ($t0 + 16) 12.5 8.0 'V'              # hips
    Rect $cv 19 ($t0 + 6) 44 ($t0 + 18) 'V'

    # -- cream belly
    Ell $cv 31.0 ($t0 + 12) 9.5 7.5 'C'
    Ell $cv 34.5 ($t0 + 13) 6.5 5.5 'c'               # its shaded side

    # -- light on top, shade down the right (same as the head)
    Tint $cv 0 $t0 63 ($t0 + 3) 'L'
    Tint $cv 42 $t0 63 ($t0 + 22) 'v'

    # -- legs
    $dyL = 0; $dyR = 0
    if ($step -eq 1) { $dyL = -2 }
    if ($step -eq -1) { $dyR = -2 }
    Rect $cv 22 ($t0 + 16) 30 (57 + $dyL) 'V'
    Rect $cv 33 ($t0 + 16) 41 (57 + $dyR) 'V'
    Tint $cv 27 ($t0 + 18) 30 (57 + $dyL) 'v'
    Tint $cv 38 ($t0 + 18) 41 (57 + $dyR) 'v'

    # -- webbed feet, splayed outward
    Ell $cv 24.0 (60 + $dyL) 9.0 3.5 'V'
    Ell $cv 39.0 (60 + $dyR) 9.0 3.5 'V'
    Tint $cv 42 (57 + $dyR) 49 63 'v'
    foreach ($f in @(@(24, $dyL), @(39, $dyR))) {
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

if ($Pose -eq 'lie') {
    # Lying in bed, seen from the side: the head rests on the pillow at the
    # left and only a shoulder shows to the right. Everything below the
    # shoulder is under the quilt, so we simply do not draw it.
    $headDx = -9; $headDy = 8
    $torso = New-Canvas
    Ell $torso 46 33 12.0 9.5 'H'       # shoulder
    Rect $torso 36 25 62 42 'H'
    Ell $torso 60 33 9.0 8.5 'H'        # upper arm rolled forward
    Tint $torso 0 35 63 63 'h'          # underside in shadow
    Rect $torso 34 24 48 31 'J'         # hood bunched behind the neck
    Ell $torso 42 30 8.0 6.5 'J'
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
if ($headDx -ne 0 -or $headDy -ne 0) { $head = Shift-Canvas $head $headDx $headDy }
Stack $canvas $head

if (-not $isBoy) {
    $bow = New-Canvas
    Draw-Bow $bow
    Outline $bow 'E'
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
