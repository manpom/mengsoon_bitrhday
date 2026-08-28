param([string]$Who = 'mengdol', [string]$Out = '')

# ASCII-only comments on purpose: PS 5.1 reads BOM-less UTF-8 as ANSI and a
# mis-decoded byte can act as a line continuation, swallowing the next line.

$W = 64; $H = 64
$script:rows = @()
for ($y = 0; $y -lt $H; $y++) { $script:rows += , (New-Object char[] $W) }
for ($y = 0; $y -lt $H; $y++) { for ($x = 0; $x -lt $W; $x++) { $script:rows[$y][$x] = '.' } }

function P([double]$x, [double]$y, [char]$ch) {
    $ix = [int]$x; $iy = [int]$y
    if ($ix -ge 0 -and $ix -lt 64 -and $iy -ge 0 -and $iy -lt 64) { $script:rows[$iy][$ix] = $ch }
}
function Get([int]$x, [int]$y) {
    if ($x -ge 0 -and $x -lt 64 -and $y -ge 0 -and $y -lt 64) { return $script:rows[$y][$x] }
    return [char]'.'
}
function Ell([double]$cx, [double]$cy, [double]$rx, [double]$ry, [char]$ch) {
    for ($y = [math]::Floor($cy - $ry); $y -le [math]::Ceiling($cy + $ry); $y++) {
        for ($x = [math]::Floor($cx - $rx); $x -le [math]::Ceiling($cx + $rx); $x++) {
            $dx = ($x - $cx) / $rx; $dy = ($y - $cy) / $ry
            if ($dx * $dx + $dy * $dy -le 1.0) { P $x $y $ch }
        }
    }
}
function Rect([int]$x0, [int]$y0, [int]$x1, [int]$y1, [char]$ch) {
    for ($y = $y0; $y -le $y1; $y++) { for ($x = $x0; $x -le $x1; $x++) { P $x $y $ch } }
}
function Row([int]$y, [int]$hw, [char]$ch) { Rect (32 - $hw) $y (31 + $hw) $y $ch }
# paint only inside the silhouette: never grow it, and never eat the outline
function Shade([int]$x0, [int]$y0, [int]$x1, [int]$y1, [char]$ch) {
    for ($y = $y0; $y -le $y1; $y++) {
        for ($x = $x0; $x -le $x1; $x++) {
            $c = Get $x $y
            if ($c -ne '.' -and $c -ne 'A') { P $x $y $ch }
        }
    }
}
function Outline() {
    $snap = @()
    for ($y = 0; $y -lt 64; $y++) { $snap += , ($script:rows[$y].Clone()) }
    $dirs = @(@(0, -1), @(0, 1), @(-1, 0), @(1, 0))
    for ($y = 0; $y -lt 64; $y++) {
        for ($x = 0; $x -lt 64; $x++) {
            if ($snap[$y][$x] -ne '.') { continue }
            foreach ($d in $dirs) {
                $nx = $x + $d[0]; $ny = $y + $d[1]
                if ($nx -ge 0 -and $nx -lt 64 -and $ny -ge 0 -and $ny -lt 64 -and $snap[$ny][$nx] -ne '.') {
                    $script:rows[$y][$x] = [char]'A'; break
                }
            }
        }
    }
}

# ribbon: tall at the outer tips, pinched at the knot -> reads as a bow, not a bone
$bow = @{
    23 = @(2, 7); 24 = @(1, 8); 25 = @(1, 8); 26 = @(2, 7); 27 = @(2, 7)
    28 = @(3, 6); 29 = @(3, 6); 30 = @(3, 6); 31 = @(3, 6); 32 = @(3, 6); 33 = @(3, 6)
    34 = @(3, 6); 35 = @(3, 6); 36 = @(2, 7); 37 = @(2, 7); 38 = @(1, 8); 39 = @(1, 8); 40 = @(2, 7)
}

# ================= 1. SILHOUETTE =================
Ell 19 13.5 10 10 'V'          # left eye bump
Ell 44 13.5 10 10 'V'          # right eye bump
$head = @{
    13 = 15; 14 = 17; 15 = 18; 16 = 19; 17 = 20; 18 = 20; 19 = 21; 20 = 21
    21 = 22; 22 = 22; 23 = 22; 24 = 22; 25 = 22; 26 = 21; 27 = 21; 28 = 21
    29 = 20; 30 = 20; 31 = 19; 32 = 17; 33 = 15; 34 = 12
}
foreach ($k in $head.Keys) { Row $k $head[$k] 'V' }

Rect 23 35 40 35 'V'           # shoulders, sloped in
Rect 21 36 42 36 'V'
Rect 19 37 44 50 'V'           # torso
Rect 13 37 19 52 'V'           # left arm
Rect 44 37 50 52 'V'           # right arm

if ($Who -eq 'mengdol') {
    Rect 21 51 42 54 'V'       # shorts
    Rect 23 55 30 57 'V'       # legs
    Rect 33 55 40 57 'V'
}
else {
    $skirt = @{ 47 = 14; 48 = 14; 49 = 15; 50 = 16; 51 = 17; 52 = 19; 53 = 20; 54 = 21; 55 = 20 }
    foreach ($k in $skirt.Keys) { Row $k $skirt[$k] 'V' }
    Rect 23 56 30 57 'V'
    Rect 33 56 40 57 'V'
    foreach ($x in $bow.Keys) { Rect $x $bow[$x][0] $x $bow[$x][1] 'V' }
    Rect 28 6 35 13 'V'      # fill the valley behind the bow so it has a solid backdrop
}

Rect 22 58 27 59 'V'; Rect 36 58 41 59 'V'   # sneaker ankle collar
Rect 20 60 29 60 'V'; Rect 34 60 43 60 'V'
Rect 19 61 30 62 'V'; Rect 33 61 44 62 'V'
Rect 18 63 31 63 'V'; Rect 32 63 45 63 'V'   # sole

Outline                        # the ONLY outline pass, so both sprites match

# ================= 2. BODY SHADING =================
for ($y = 0; $y -lt 64; $y++) {
    $mn = -1; $mx = -1
    for ($x = 0; $x -lt 64; $x++) { if ($script:rows[$y][$x] -eq 'V') { if ($mn -lt 0) { $mn = $x }; $mx = $x } }
    if ($mn -lt 0) { continue }
    for ($x = $mx - 4; $x -le $mx; $x++) { if ((Get $x $y) -eq 'V') { P $x $y 'v' } }
    for ($x = $mn; $x -le $mn + 2; $x++) { if ((Get $x $y) -eq 'V') { P $x $y 'L' } }
}
Shade 16 33 47 34 'v'          # soft chin shadow

# ================= 3. FACE =================
Ell 19 14 6 6 'Q'
Ell 44 14 6 6 'Q'
Rect 15 10 18 13 'W'           # main glint, upper-left on both eyes
Rect 40 10 43 13 'W'
Rect 21 17 22 18 'W'           # small lower-right glint
Rect 46 17 47 18 'W'
Ell 13 23 4.5 3 'P'            # blush
Ell 50 23 4.5 3 'P'
Rect 29 21 30 22 'Z'           # nostrils
Rect 33 21 34 22 'Z'
for ($x = 18; $x -le 45; $x++) { # smile arc, 2px thick
    $t = ($x - 31.5) / 13.5
    $yy = [math]::Round(24 + 4 * (1 - $t * $t))
    P $x $yy 'A'
    P $x ($yy - 1) 'A'
}

# ================= 4. CLOTHES =================
if ($Who -eq 'mengdol') {
    Shade 19 35 44 50 '1'      # hoodie body
    Shade 13 37 19 48 '2'      # sleeves, one step darker so the arms read
    Shade 44 37 50 48 '2'
    Shade 21 35 42 36 '3'      # hood bunched behind the neck
    Shade 28 35 35 35 'V'      # neck opening
    Shade 39 37 44 50 '2'      # right-side shade
    Shade 19 37 19 46 '3'      # sleeve seams
    Shade 44 37 44 46 '3'
    Shade 13 47 19 48 '3'      # cuffs
    Shade 44 47 50 48 '3'
    Shade 21 45 42 45 '3'      # pocket top edge
    Shade 21 46 42 48 '2'      # kangaroo pocket
    Shade 19 49 44 50 '3'      # hem rib
    Rect 28 37 28 42 'W'       # drawstrings
    Rect 35 37 35 42 'W'
    Rect 27 42 28 43 'W'       # aglets
    Rect 35 42 36 43 'W'
    Shade 13 49 19 52 'V'      # hands
    Shade 44 49 50 52 'v'
    Shade 21 51 42 54 '4'      # shorts
    Shade 21 51 42 51 '5'      # waistband
    Shade 38 52 42 54 '5'      # right-side shade
    Shade 21 54 42 54 '5'      # hem
    Shade 23 55 30 57 'V'      # legs
    Shade 33 55 40 57 'v'
    $solec = [char]'9'
}
else {
    Shade 19 35 44 46 '6'      # dress bodice
    Shade 39 37 44 46 '7'      # right-side shade
    Shade 13 37 19 41 '6'      # puff sleeves in dress pink
    Shade 44 37 50 41 '6'
    Shade 47 37 50 41 '7'
    Shade 13 41 19 41 'W'      # white cuff trim
    Shade 44 41 50 41 'W'
    Shade 21 35 42 36 'W'      # white collar
    Shade 28 35 35 35 'V'      # neck opening
    Shade 13 42 19 48 'V'      # bare arms
    Shade 44 42 50 48 'v'
    Shade 13 49 19 52 'V'      # hands
    Shade 44 49 50 52 'v'
    foreach ($y in 47, 48, 49, 50, 51, 52, 53, 54, 55) { Shade 0 $y 63 $y '6' }
    foreach ($y in 47, 48, 49, 50, 51, 52, 53, 54, 55) { Shade 38 $y 63 $y '7' }
    Shade 19 46 44 46 '0'      # waist seam, separates bodice from skirt
    Shade 0 55 63 55 'W'       # thin lace trim at the hem only
    Shade 23 56 30 57 'V'      # legs
    Shade 33 56 40 57 'v'
    # bow: dark backing first so it keeps a 1px edge where it sits on the head
    foreach ($x in $bow.Keys) {
        $t = $bow[$x][0]; $b = $bow[$x][1]
        for ($xx = $x - 1; $xx -le $x + 1; $xx++) {
            for ($yy = $t - 1; $yy -le $b + 1; $yy++) { if ((Get $xx $yy) -ne '.') { P $xx $yy 'A' } }
        }
    }
    foreach ($x in $bow.Keys) { Rect $x $bow[$x][0] $x $bow[$x][1] '6' }
    Shade 36 1 40 8 '7'        # right loop in shade
    Rect 30 3 33 6 '0'         # knot
    Rect 24 2 25 4 'W'         # highlight on the left loop
    Rect 28 28 35 32 'A'       # front teeth: dark border
    Rect 29 29 34 31 'W'
    $solec = [char]'0'
}

# ---- sneakers, identical construction on both ----
Shade 22 58 27 59 'W'; Shade 36 58 41 59 'W'      # ankle collar
Shade 19 60 30 62 'W'; Shade 33 60 44 62 'W'      # upper
Shade 27 60 30 62 '8'; Shade 41 60 44 62 '8'      # outer-side shade
Shade 21 61 26 61 '8'; Shade 35 61 40 61 '8'      # lace line
Shade 18 63 31 63 $solec; Shade 32 63 45 63 $solec # sole

# ================= 5. SAVE =================
$lines = @()
for ($y = 0; $y -lt 64; $y++) { $lines += (-join $script:rows[$y]) }
if ($Out -eq '') { $Out = Join-Path $PSScriptRoot ('art\' + $Who + '_idle.txt') }
Set-Content -Path $Out -Value $lines -Encoding ASCII
$bad = 0
foreach ($l in $lines) { if ($l.Length -ne 64) { $bad++ } }
Write-Output "$Out  rows=$($lines.Count)  badwidth=$bad"
