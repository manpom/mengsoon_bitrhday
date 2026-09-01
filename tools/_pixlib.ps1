# Shared 64x64 pixel-drawing primitives. Dot-source it:
#     . (Join-Path $PSScriptRoot '_pixlib.ps1')
#
# A canvas is an array of 64 char[] rows. '.' is transparent. Every helper
# takes the canvas as its first argument so several canvases can be drawn
# separately and stacked (that is how a part gets its own outline).
#
# ASCII-only comments on purpose: PS 5.1 reads BOM-less UTF-8 as ANSI and a
# mis-decoded byte can act as a line continuation, swallowing the next line.

function New-Canvas {
    $c = @()
    for ($y = 0; $y -lt 64; $y++) {
        $r = New-Object char[] 64
        for ($x = 0; $x -lt 64; $x++) { $r[$x] = '.' }
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

# a row centred on x=31.5. Mirror the right edge off the left one - rounding
# both ends independently would shift the row off centre by 1px.
function Row($cv, [int]$y, [double]$hw, [char]$ch) {
    $x0 = [int][math]::Floor(31.5 - $hw + 0.5)
    Rect $cv $x0 $y (63 - $x0) $y $ch
}
function Ell($cv, [double]$cx, [double]$cy, [double]$rx, [double]$ry, [char]$ch) {
    for ($y = [math]::Floor($cy - $ry); $y -le [math]::Ceiling($cy + $ry); $y++) {
        for ($x = [math]::Floor($cx - $rx); $x -le [math]::Ceiling($cx + $rx); $x++) {
            $dx = ($x - $cx) / $rx; $dy = ($y - $cy) / $ry
            if ($dx * $dx + $dy * $dy -le 1.0) { P $cv $x $y $ch }
        }
    }
}
# ellipse clipped to whatever is already painted (blush must stay on the face)
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

# ---- chunky mode: draw on a 32x32 logical grid, each cell a 2x2 block ----
function Blk($cv, [int]$lx, [int]$ly, [char]$ch) {
    Rect $cv ($lx * 2) ($ly * 2) ($lx * 2 + 1) ($ly * 2 + 1) $ch
}
function BlkRect($cv, [int]$lx0, [int]$ly0, [int]$lx1, [int]$ly1, [char]$ch) {
    for ($y = $ly0; $y -le $ly1; $y++) { for ($x = $lx0; $x -le $lx1; $x++) { Blk $cv $x $y $ch } }
}
function BlkRow($cv, [int]$ly, [int]$hw, [char]$ch) { BlkRect $cv (16 - $hw) $ly (15 + $hw) $ly $ch }
# outline on the 32x32 logical grid, so the border stays as chunky as the art
function BlkOutline($cv, [char]$ch) {
    $filled = New-Object 'bool[,]' 32, 32
    for ($ly = 0; $ly -lt 32; $ly++) {
        for ($lx = 0; $lx -lt 32; $lx++) { $filled[$lx, $ly] = ((G $cv ($lx * 2) ($ly * 2)) -ne '.') }
    }
    $dirs = @(@(0, -1), @(0, 1), @(-1, 0), @(1, 0))
    for ($ly = 0; $ly -lt 32; $ly++) {
        for ($lx = 0; $lx -lt 32; $lx++) {
            if ($filled[$lx, $ly]) { continue }
            foreach ($d in $dirs) {
                $nx = $lx + $d[0]; $ny = $ly + $d[1]
                if ($nx -ge 0 -and $nx -lt 32 -and $ny -ge 0 -and $ny -lt 32 -and $filled[$nx, $ny]) {
                    Blk $cv $lx $ly $ch; break
                }
            }
        }
    }
}

function Save-Canvas($cv, [string]$path) {
    $lines = @()
    for ($y = 0; $y -lt 64; $y++) { $lines += (-join $cv[$y]) }
    Set-Content -Path $path -Value $lines -Encoding ASCII
    $bad = 0
    foreach ($l in $lines) { if ($l.Length -ne 64) { $bad++ } }
    return $bad
}
