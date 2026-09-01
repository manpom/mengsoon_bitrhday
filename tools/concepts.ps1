param([int]$Concept = 0, [string]$Who = 'mengdol', [string]$Out = '')

# ASCII-only comments on purpose: PS 5.1 reads BOM-less UTF-8 as ANSI and a
# mis-decoded byte can act as a line continuation, swallowing the next line.
#
# Five character concepts that do NOT share a silhouette - each one is drawn
# from scratch with its own proportions, outline treatment and palette.
#
#   1 plush     - head and body are one round blob, stub arms, no jaw line
#   2 storybook - 3-heads-tall, small head, real shoulders / waist / legs
#   3 soft      - pastel, no black outline, soft green rim instead
#   4 retro     - drawn on a 32x32 grid in 2x2 blocks, 8-bit console look
#   5 feral     - an actual frog: eyes on top, cream belly, webbed feet
#
#   powershell -ExecutionPolicy Bypass -File tools\concepts.ps1
#       -> builds all 10 and writes tools/concepts.png
#   powershell -ExecutionPolicy Bypass -File tools\concepts.ps1 -Concept 3 -Who mengsoon -Out x.txt

. (Join-Path $PSScriptRoot '_pixlib.ps1')

# A hair bow, drawn from the middle out: tall at the outer tips, pinched where
# the loops meet the knot. Always give it its OWN canvas - the shading step
# recolours everything to the right of the centre.
function Draw-BowAt($cv, [double]$cx, [double]$cy, [double]$w, [double]$h,
    [char]$base, [char]$shade, [char]$knot) {
    for ($x = [int][math]::Floor($cx - $w); $x -le [int][math]::Ceiling($cx + $w); $x++) {
        $d = [math]::Abs($x - $cx) / $w
        if ($d -gt 1.0) { continue }
        if ($d -le 0.16) { $hh = $h }
        elseif ($d -le 0.38) { $hh = $h * 0.34 }
        elseif ($d -le 0.72) { $hh = $h * 0.92 }
        else { $hh = $h * 0.55 }
        Rect $cv $x ([int][math]::Round($cy - $hh)) $x ([int][math]::Round($cy + $hh)) $base
    }
    Tint $cv ([int][math]::Round($cx + 1)) 0 63 63 $shade
    Rect $cv ([int][math]::Round($cx - $w * 0.16)) ([int][math]::Round($cy - $h * 0.7)) `
        ([int][math]::Round($cx + $w * 0.16)) ([int][math]::Round($cy + $h * 0.7)) $knot
}

# ============================================================
# 1. PLUSH - one continuous blob, the way a keyring doll reads
# ============================================================
function Draw-Plush([bool]$isBoy) {
    if ($isBoy) { $cl = [char]'H'; $cd = [char]'J' } else { $cl = [char]'7'; $cd = [char]'0' }
    $cv = New-Canvas

    # body and head share one silhouette - no neck, no outline between them
    Ell $cv 31.5 47 15 12 $cl          # torso
    Ell $cv 12 48 5.5 4.5 'V'          # stub arms, clear of the torso
    Ell $cv 51 48 5.5 4.5 'V'
    Ell $cv 23 58 6.5 4 $cd            # stub feet
    Ell $cv 40 58 6.5 4 $cd
    Ell $cv 17 10 7.5 6.5 'V'          # head bumps
    Ell $cv 46 10 7.5 6.5 'V'
    Ell $cv 31.5 20 21 16 'V'          # head

    Tint $cv 0 4 63 14 'L'             # light on top of the head
    for ($y = 0; $y -lt 64; $y++) {
        $mn = -1; $mx = -1
        for ($x = 0; $x -lt 64; $x++) { if ($cv[$y][$x] -ne '.') { if ($mn -lt 0) { $mn = $x }; $mx = $x } }
        if ($mn -lt 0) { continue }
        for ($x = $mx - 3; $x -le $mx; $x++) {
            $c = G $cv $x $y
            if ($c -eq 'V' -or $c -eq 'L') { P $cv $x $y 'v' } elseif ($c -eq $cl) { P $cv $x $y $cd }
        }
    }
    Rect $cv 0 35 63 36 '.'            # cut a gap, then refill: collar seam
    Ell $cv 31.5 47 15 12 $cl
    Ell $cv 31.5 20 21 16 'V'
    Tint $cv 17 34 46 36 $cd           # the seam itself

    Ell $cv 21 21 3 3.5 'K'            # tiny dot eyes
    Ell $cv 42 21 3 3.5 'K'
    Rect $cv 20 19 21 20 'W'
    Rect $cv 41 19 42 20 'W'
    EllIn $cv 13 27 4.5 2.5 'S'        # big round blush
    EllIn $cv 50 27 4.5 2.5 'S'
    for ($x = 27; $x -le 36; $x++) {   # small smile
        $t = ($x - 31.5) / 4.5
        P $cv $x ([int][math]::Round(27 + 2 * (1 - $t * $t))) 'E'
    }
    if (-not $isBoy) {
        Rect $cv 29 30 34 34 'E'       # one solid tooth
        Rect $cv 30 31 33 33 'W'
    }
    Outline $cv 'E'
    if (-not $isBoy) {
        $bow = New-Canvas
        Draw-BowAt $bow 31.5 6 12 5 '6' '7' '0'
        Outline $bow 'E'
        Stack $cv $bow
    }
    return , $cv
}

# ============================================================
# 2. STORYBOOK - 3 heads tall, small head, actual limbs
# ============================================================
function Draw-Storybook([bool]$isBoy) {
    $body = New-Canvas
    if ($isBoy) { $cl = [char]'H'; $cd = [char]'J' } else { $cl = [char]'F'; $cd = [char]'i' }

    # the point of this one is the proportion: head 21px, body 37px
    Rect $body 24 26 39 26 $cl         # shoulders
    Rect $body 23 27 40 41 $cl         # torso
    Rect $body 19 29 22 42 $cl         # arms, held away from the body
    Rect $body 41 29 44 42 $cl
    Tint $body 36 26 40 41 $cd         # right-side shade
    Tint $body 41 29 44 42 $cd
    Rect $body 23 40 40 41 $cd         # hem
    Ell $body 20.5 44 3 3 'V'          # hands
    Ell $body 43 44 3 3 'V'

    if ($isBoy) {
        Rect $body 23 41 40 48 'T'     # trousers
        Rect $body 25 48 30 56 'T'
        Rect $body 33 48 38 56 'T'
        Tint $body 36 41 40 56 't'
        Rect $body 31 41 32 47 't'
        Rect $body 22 57 31 62 'F'     # sneakers
        Rect $body 32 57 41 62 'F'
        Tint $body 28 57 31 62 'f'
        Tint $body 38 57 41 62 'f'
        Rect $body 22 62 41 62 'f'
        Rect $body 28 30 28 36 'W'     # drawstrings
        Rect $body 35 30 35 36 'W'
    }
    else {
        Rect $body 22 41 41 44 '7'     # flared skirt
        Rect $body 20 45 43 47 '7'
        Rect $body 19 48 44 50 '7'
        foreach ($px in 24, 29, 34, 39) { Rect $body $px 42 $px 49 '0' }
        Tint $body 37 41 44 50 '0'
        Rect $body 19 50 44 50 '0'
        Rect $body 26 51 30 56 'B'     # socks
        Rect $body 33 51 37 56 'B'
        Rect $body 23 57 31 62 'K'     # shoes
        Rect $body 32 57 40 62 'K'
        Ell $body 27.5 34 3 2.5 'R'    # collar ribbon
        Ell $body 35.5 34 3 2.5 'R'
        Rect $body 30 33 33 35 'R'
        Rect $body 31 34 32 34 '0'
    }
    Outline $body 'E'

    $head = New-Canvas
    Ell $head 24 8 5.5 5 'V'           # eye bumps
    Ell $head 39 8 5.5 5 'V'
    Ell $head 31.5 14 12 10 'V'        # skull, y=4..24
    Tint $head 0 3 63 8 'L'
    for ($y = 0; $y -lt 64; $y++) {
        $mn = -1; $mx = -1
        for ($x = 0; $x -lt 64; $x++) { if ($head[$y][$x] -ne '.') { if ($mn -lt 0) { $mn = $x }; $mx = $x } }
        if ($mn -lt 0) { continue }
        for ($x = $mx - 2; $x -le $mx; $x++) { if ((G $head $x $y) -ne '.') { P $head $x $y 'v' } }
    }
    for ($y = 14; $y -le 26; $y++) {   # small cream muzzle under the smile
        for ($x = 0; $x -lt 64; $x++) {
            if ((G $head $x $y) -eq '.') { continue }
            if ($y -le 16) { continue }
            $dx = ($x - 31.5) / 9.5; $dy = ($y - 21.0) / 4.5
            if ($dx * $dx + $dy * $dy -le 1.0) { P $head $x $y 'C' }
        }
    }
    Tint $head 38 14 63 24 'c'
    Ell $head 24 9 3 3.8 'K'           # eyes
    Ell $head 39 9 3 3.8 'K'
    Rect $head 24 6 25 7 'W'
    Rect $head 39 6 40 7 'W'
    EllIn $head 21 14 3 1.5 'S'        # blush
    EllIn $head 42 14 3 1.5 'S'
    P $head 30 13 'Z'                  # nostrils
    P $head 33 13 'Z'
    for ($x = 25; $x -le 38; $x++) {   # smile
        $t = ($x - 31.5) / 7.0
        $my = [int][math]::Round(15.5 + 1.5 * (1 - $t * $t))
        if ((G $head $x $my) -ne '.') { P $head $x $my 'E' }
    }
    if (-not $isBoy) {
        Rect $head 29 17 34 22 'E'     # front teeth, no divider
        Rect $head 30 18 33 21 'W'
    }
    Outline $head 'E'

    $cv = New-Canvas
    Stack $cv $body
    Stack $cv $head
    if (-not $isBoy) {
        $bow = New-Canvas
        Draw-BowAt $bow 31.5 3 7 3 '6' '7' '0'
        Outline $bow 'E'
        Stack $cv $bow
    }
    return , $cv
}

# ============================================================
# 3. SOFT - pastel, no black anywhere, soft green rim
# ============================================================
function Draw-Soft([bool]$isBoy) {
    if ($isBoy) { $cl = [char]'1'; $cd = [char]'2'; $lo = [char]'U' } else { $cl = [char]'6'; $cd = [char]'7'; $lo = [char]'6' }
    $body = New-Canvas
    Rect $body 21 35 42 36 $cl
    Rect $body 19 37 44 49 $cl
    Rect $body 15 38 19 48 $cd         # sleeves
    Rect $body 44 38 48 48 $cd
    Tint $body 40 35 44 49 $cd
    Ell $body 17 50 3.5 3 'G'          # hands
    Ell $body 46 50 3.5 3 'G'

    if ($isBoy) {
        Rect $body 20 49 43 55 $lo     # shorts
        Tint $body 39 49 43 55 'u'
        Punch $body 30 55 33 55
        Rect $body 23 56 29 58 'G'
        Rect $body 34 56 40 58 'G'
    }
    else {
        Rect $body 19 49 44 50 $lo     # skirt
        Rect $body 18 51 45 53 $lo
        Rect $body 17 54 46 55 $lo
        Tint $body 40 49 46 55 '7'
        Rect $body 23 56 29 58 'B'
        Rect $body 34 56 40 58 'B'
    }
    Rect $body 20 59 30 63 'F'         # soft cream shoes
    Rect $body 33 59 43 63 'F'
    Tint $body 27 60 30 63 'f'
    Tint $body 40 60 43 63 'f'
    Outline $body 'd'

    $head = New-Canvas
    Ell $head 17 13 9.5 11 'G'
    Ell $head 46 13 9.5 11 'G'
    Ell $head 31.5 20 20 15 'G'        # y=5..35
    Tint $head 0 2 63 6 'e'            # airy rim light, top few rows only
    for ($y = 0; $y -lt 64; $y++) {
        $mn = -1; $mx = -1
        for ($x = 0; $x -lt 64; $x++) { if ($head[$y][$x] -ne '.') { if ($mn -lt 0) { $mn = $x }; $mx = $x } }
        if ($mn -lt 0) { continue }
        for ($x = $mx - 3; $x -le $mx; $x++) { if ((G $head $x $y) -ne '.') { P $head $x $y 'g' } }
    }
    Tint $head 0 33 63 35 'g'
    for ($y = 22; $y -le 38; $y++) {   # pale muzzle
        for ($x = 0; $x -lt 64; $x++) {
            if ((G $head $x $y) -eq '.') { continue }
            if ($y -le 26) { continue }
            $dx = ($x - 31.5) / 17.0; $dy = ($y - 32.0) / 8.0
            if ($dx * $dx + $dy * $dy -le 1.0) { P $head $x $y 'B' }
        }
    }
    Ell $head 17 14 5 6.5 'D'          # dark-green eyes, never black
    Ell $head 46 14 5 6.5 'D'
    Rect $head 17 10 20 13 'F'
    Rect $head 46 10 49 13 'F'
    EllIn $head 12 23 4.5 2.5 '6'      # faint blush
    EllIn $head 51 23 4.5 2.5 '6'
    Rect $head 29 21 30 22 'g'
    Rect $head 33 21 34 22 'g'
    for ($x = 18; $x -le 45; $x++) {
        $t = ($x - 31.5) / 14.0
        $my = [int][math]::Round(25 + 2.2 * (1 - $t * $t))
        if ((G $head $x $my) -ne '.') { P $head $x $my 'd' }
    }
    if (-not $isBoy) {
        Rect $head 28 28 35 33 'd'
        Rect $head 29 29 34 32 'F'
    }
    Outline $head 'd'

    $cv = New-Canvas
    Stack $cv $body
    Stack $cv $head
    if (-not $isBoy) {
        $bow = New-Canvas
        Draw-BowAt $bow 31.5 6 12 5 '6' '7' '7'
        Outline $bow 'd'
        Stack $cv $bow
    }
    return , $cv
}

# ============================================================
# 4. RETRO - 32x32 logical grid, every pixel a 2x2 block
# ============================================================
function Draw-Retro([bool]$isBoy) {
    if ($isBoy) { $cl = [char]'N'; $cd = [char]'n' } else { $cl = [char]'P'; $cd = [char]'r' }
    $cv = New-Canvas

    $prof = @{ 1 = 5; 2 = 6; 3 = 10; 4 = 11; 5 = 12; 6 = 12; 7 = 12; 8 = 12; 9 = 12; 10 = 12; 11 = 12; 12 = 11; 13 = 10; 14 = 8 }
    BlkRect $cv 6 0 10 2 'G'           # eye bumps poking up
    BlkRect $cv 21 0 25 2 'G'
    foreach ($k in $prof.Keys) { BlkRow $cv $k $prof[$k] 'G' }
    for ($ly = 0; $ly -le 14; $ly++) { for ($lx = 22; $lx -lt 32; $lx++) { if ((G $cv ($lx * 2) ($ly * 2)) -eq 'G') { Blk $cv $lx $ly 'g' } } }

    BlkRect $cv 7 3 10 7 'K'           # eyes
    BlkRect $cv 21 3 24 7 'K'
    BlkRect $cv 8 4 9 5 'W'
    BlkRect $cv 22 4 23 5 'W'
    BlkRect $cv 4 9 6 10 'S'           # blush
    BlkRect $cv 25 9 27 10 'S'
    BlkRect $cv 14 8 14 8 'D'          # nostrils
    BlkRect $cv 17 8 17 8 'D'
    BlkRect $cv 7 11 24 11 'o'         # mouth
    BlkRect $cv 6 12 25 13 'B'         # cream jaw
    BlkRect $cv 8 14 23 14 'B'
    BlkRect $cv 22 12 25 14 'C'
    if (-not $isBoy) { BlkRect $cv 14 12 17 13 'W' }   # solid teeth

    BlkRect $cv 10 15 21 22 $cl        # torso
    BlkRect $cv 8 16 9 21 $cd          # arms
    BlkRect $cv 22 16 23 21 $cd
    BlkRect $cv 19 15 21 22 $cd
    BlkRect $cv 8 22 9 23 'G'          # hands
    BlkRect $cv 22 22 23 23 'G'
    if ($isBoy) {
        BlkRect $cv 14 16 14 19 'W'    # drawstrings
        BlkRect $cv 17 16 17 19 'W'
        BlkRect $cv 10 23 21 26 'T'    # shorts
        BlkRect $cv 19 23 21 26 't'
        BlkRect $cv 12 27 14 28 'G'    # legs
        BlkRect $cv 17 27 19 28 'G'
        BlkRect $cv 10 29 15 30 'F'    # sneakers
        BlkRect $cv 16 29 21 30 'F'
    }
    else {
        BlkRect $cv 9 23 22 26 'P'     # skirt
        BlkRect $cv 19 23 22 26 'r'
        BlkRect $cv 12 27 14 28 'B'    # socks
        BlkRect $cv 17 27 19 28 'B'
        BlkRect $cv 10 29 15 30 'K'    # shoes
        BlkRect $cv 16 29 21 30 'K'
        BlkRect $cv 11 0 13 2 'P'      # head bow: two loops and a knot
        BlkRect $cv 18 0 20 2 'P'
        BlkRect $cv 14 1 17 1 'P'
        BlkRect $cv 15 0 16 2 'r'
    }
    BlkOutline $cv 'o'
    return , $cv
}

# ============================================================
# 5. FERAL - a frog first, a character second
# ============================================================
function Draw-Feral([bool]$isBoy) {
    $body = New-Canvas
    $prof = @{
        30 = 10; 31 = 11; 32 = 12; 33 = 13; 34 = 14; 35 = 15; 36 = 15; 37 = 16
        38 = 16; 39 = 17; 40 = 17; 41 = 17; 42 = 17; 43 = 17; 44 = 17; 45 = 16
        46 = 16; 47 = 15; 48 = 14; 49 = 12
    }
    foreach ($k in $prof.Keys) { Row $body $k $prof[$k] 'V' }
    Ell $body 14 47 8 7 'V'            # haunches
    Ell $body 49 47 8 7 'V'
    Rect $body 9 54 25 59 'V'          # webbed hind feet
    Rect $body 38 54 54 59 'V'
    foreach ($tx in 12, 17, 22) { Rect $body $tx 59 ($tx + 2) 61 'V' }
    foreach ($tx in 41, 46, 51) { Rect $body $tx 59 ($tx + 2) 61 'V' }
    Rect $body 15 32 19 46 'V'         # front legs
    Rect $body 44 32 48 46 'V'
    foreach ($tx in 13, 16, 19) { Rect $body $tx 46 ($tx + 1) 49 'V' }
    foreach ($tx in 43, 46, 49) { Rect $body $tx 46 ($tx + 1) 49 'V' }

    for ($y = 0; $y -lt 64; $y++) {    # rim shade down the right
        $mn = -1; $mx = -1
        for ($x = 0; $x -lt 64; $x++) { if ($body[$y][$x] -ne '.') { if ($mn -lt 0) { $mn = $x }; $mx = $x } }
        if ($mn -lt 0) { continue }
        for ($x = $mx - 3; $x -le $mx; $x++) { if ((G $body $x $y) -ne '.') { P $body $x $y 'v' } }
        for ($x = $mn; $x -le $mn + 1; $x++) { if ((G $body $x $y) -ne '.') { P $body $x $y 'L' } }
    }
    EllIn $body 31.5 43 11.5 10 'C'    # pale belly
    EllIn $body 34 45 9 8 'c'
    foreach ($p in @(22, 33), @(41, 35), @(26, 50), @(45, 52)) {   # back spots
        if ((G $body $p[0] $p[1]) -eq 'V' -or (G $body $p[0] $p[1]) -eq 'v') {
            Ell $body $p[0] $p[1] 2 1.5 'Z'
        }
    }
    if ($isBoy) {
        Rect $body 18 31 45 35 'H'     # scarf wrapped round the neck
        Tint $body 39 31 45 35 'h'
        Rect $body 38 35 43 46 'H'     # and its hanging tail
        Tint $body 41 35 43 46 'h'
        Rect $body 38 46 43 48 'h'
    }
    else {
        Rect $body 26 34 37 36 'F'     # pinafore
        Rect $body 24 37 39 46 'F'
        Rect $body 25 47 38 48 'F'
        Tint $body 35 34 39 48 'f'
        Rect $body 25 31 27 35 'R'     # straps over the shoulders
        Rect $body 36 31 38 35 'R'
    }
    Outline $body 'E'

    $head = New-Canvas
    Ell $head 18 12 9 9 'V'            # eyes bulging above the skull
    Ell $head 45 12 9 9 'V'
    $hp = @{ 16 = 13; 17 = 15; 18 = 17; 19 = 18; 20 = 19; 21 = 19; 22 = 19; 23 = 19; 24 = 19; 25 = 18; 26 = 18; 27 = 17; 28 = 15; 29 = 12 }
    foreach ($k in $hp.Keys) { Row $head $k $hp[$k] 'V' }
    Tint $head 0 3 63 12 'L'
    for ($y = 0; $y -lt 64; $y++) {
        $mn = -1; $mx = -1
        for ($x = 0; $x -lt 64; $x++) { if ($head[$y][$x] -ne '.') { if ($mn -lt 0) { $mn = $x }; $mx = $x } }
        if ($mn -lt 0) { continue }
        for ($x = $mx - 3; $x -le $mx; $x++) { if ((G $head $x $y) -ne '.') { P $head $x $y 'v' } }
    }
    Ell $head 18 12 5 5.5 'K'
    Ell $head 45 12 5 5.5 'K'
    Rect $head 18 8 21 11 'W'
    Rect $head 45 8 48 11 'W'
    Ell $head 18 15 5.5 1.5 'Z'        # heavy lower lid, very froggy
    Ell $head 45 15 5.5 1.5 'Z'
    EllIn $head 12 23 4 2 'S'
    EllIn $head 51 23 4 2 'S'
    Rect $head 29 20 30 21 'Z'
    Rect $head 33 20 34 21 'Z'
    for ($x = 14; $x -le 49; $x++) {   # mouth stretches almost ear to ear
        $t = ($x - 31.5) / 18.0
        $my = [int][math]::Round(23 + 3.0 * (1 - $t * $t))
        if ((G $head $x $my) -ne '.') { P $head $x $my 'E' }
        if ((G $head $x ($my - 1)) -ne '.') { P $head $x ($my - 1) 'E' }
    }
    for ($y = 20; $y -le 32; $y++) {
        for ($x = 0; $x -lt 64; $x++) {
            if ((G $head $x $y) -eq '.') { continue }
            $t = ($x - 31.5) / 18.0
            $my = [int][math]::Round(23 + 3.0 * (1 - $t * $t))
            if ($y -le $my) { continue }
            $dx = ($x - 31.5) / 16.0; $dy = ($y - 28.0) / 6.0
            if ($dx * $dx + $dy * $dy -le 1.0) { P $head $x $y 'C' }
        }
    }
    if (-not $isBoy) {
        Rect $head 28 25 35 30 'E'
        Rect $head 29 26 34 29 'W'
    }
    Outline $head 'E'

    $cv = New-Canvas
    Stack $cv $body
    Stack $cv $head
    if (-not $isBoy) {
        $bow = New-Canvas
        Draw-BowAt $bow 31.5 4 10 4 '6' '7' '0'
        Outline $bow 'E'
        Stack $cv $bow
    }
    return , $cv
}

# ============================================================
function Build([int]$n, [string]$who) {
    $isBoy = ($who -eq 'mengdol')
    switch ($n) {
        1 { return , (Draw-Plush $isBoy) }
        2 { return , (Draw-Storybook $isBoy) }
        3 { return , (Draw-Soft $isBoy) }
        4 { return , (Draw-Retro $isBoy) }
        5 { return , (Draw-Feral $isBoy) }
    }
    throw "unknown concept $n"
}

if ($Concept -ge 1) {
    $cv = Build $Concept $Who
    if ($Out -eq '') { $Out = Join-Path $PSScriptRoot ('art\' + $Who + '_idle.txt') }
    $bad = Save-Canvas $cv $Out
    Write-Output "$Out  concept=$Concept  badwidth=$bad"
    return
}

# ---------- build all + comparison sheet ----------
Add-Type -AssemblyName System.Drawing
$ArtDir = Join-Path $PSScriptRoot 'art'
$TmpDir = Join-Path $PSScriptRoot 'concepts'
if (-not (Test-Path $TmpDir)) { New-Item -ItemType Directory -Force -Path $TmpDir | Out-Null }

$palette = New-Object System.Collections.Hashtable ([System.StringComparer]::Ordinal)
foreach ($line in Get-Content (Join-Path $ArtDir '_palette.txt')) {
    $t = $line.Trim()
    if ($t -eq '' -or $t.StartsWith('#')) { continue }
    $parts = $t -split '\s+'
    if ($parts[1] -eq 'none') { $palette[$parts[0]] = [System.Drawing.Color]::FromArgb(0, 0, 0, 0) }
    else {
        $palette[$parts[0]] = [System.Drawing.Color]::FromArgb(255,
            [Convert]::ToInt32($parts[1].Substring(0, 2), 16),
            [Convert]::ToInt32($parts[1].Substring(2, 2), 16),
            [Convert]::ToInt32($parts[1].Substring(4, 2), 16))
    }
}
function ConvertTo-Bitmap([string]$path) {
    $rows = @(Get-Content $path | Where-Object { $_ -ne '' })
    $bmp = New-Object System.Drawing.Bitmap(64, 64, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    for ($y = 0; $y -lt 64; $y++) {
        for ($x = 0; $x -lt 64; $x++) {
            $ch = $rows[$y].Substring($x, 1)
            if ($palette.ContainsKey($ch)) { $bmp.SetPixel($x, $y, $palette[$ch]) }
            else { $bmp.SetPixel($x, $y, [System.Drawing.Color]::Magenta) }
        }
    }
    return $bmp
}

$whos = @('mengdol', 'mengsoon')
foreach ($w in $whos) {
    foreach ($n in 1..5) {
        $cv = Build $n $w
        [void](Save-Canvas $cv (Join-Path $TmpDir "${w}_c$n.txt"))
    }
}

$s = 6; $cellW = 64 * $s + 24; $cellH = 64 * $s + 40
$sheet = New-Object System.Drawing.Bitmap(($cellW * 5 + 24), ($cellH * 2 + 24))
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::FromArgb(255, 60, 66, 86))
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$font = New-Object System.Drawing.Font('Malgun Gothic', 15, [System.Drawing.FontStyle]::Bold)
$white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$names = @{ mengdol = '맹돌이'; mengsoon = '맹순이' }
$desc = @{ 1 = 'A 인형'; 2 = 'B 3등신'; 3 = 'C 파스텔'; 4 = 'D 8비트'; 5 = 'E 개구리' }

for ($r = 0; $r -lt 2; $r++) {
    foreach ($n in 1..5) {
        $b = ConvertTo-Bitmap (Join-Path $TmpDir ("{0}_c{1}.txt" -f $whos[$r], $n))
        $x = 12 + ($n - 1) * $cellW
        $y = 12 + $r * $cellH
        $g.DrawString(("{0} · {1}" -f $names[$whos[$r]], $desc[$n]), $font, $white, ($x + 6), ($y + 2))
        $g.DrawImage($b, ($x + 12), ($y + 34), (64 * $s), (64 * $s))
        $b.Dispose()
    }
}
$g.Dispose()
$sheet.Save((Join-Path $PSScriptRoot 'concepts.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$sheet.Dispose()
Write-Output "tools/concepts.png"

