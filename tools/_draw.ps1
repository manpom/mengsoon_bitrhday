# ============================================================
#  Shared pixel-drawing helpers. Dot-source it:
#      . (Join-Path $PSScriptRoot '_draw.ps1')
#
#  Everything is axis-aligned rectangles and aliased ellipses,
#  so the output stays crisp pixel art with no soft edges.
#
#  NOTE: do not rename these to R / E / C / Erase / Clear.
#  PowerShell resolves ALIASES before functions, so those names
#  would call Invoke-History / Remove-Item / Clear-Host instead.
#
#  ASCII-only comments on purpose: PS 5.1 reads BOM-less UTF-8
#  as ANSI and a mis-decoded byte can swallow the next line.
# ============================================================

Add-Type -AssemblyName System.Drawing

# ---------- drawing helpers ----------
function Hex([string]$hex) {
    $r = [Convert]::ToInt32($hex.Substring(0, 2), 16)
    $g = [Convert]::ToInt32($hex.Substring(2, 2), 16)
    $b = [Convert]::ToInt32($hex.Substring(4, 2), 16)
    $a = 255
    if ($hex.Length -ge 8) { $a = [Convert]::ToInt32($hex.Substring(6, 2), 16) }
    return [System.Drawing.Color]::FromArgb($a, $r, $g, $b)
}

$script:Img = $null
$script:Gfx = $null
# every draw call is shifted by this, so a prop can be drawn in its own
# coordinates while the canvas around it is padded for a ground shadow
$script:Ox = 0

# how much empty room to leave under a prop for its contact shadow.
# prop.gd has the same number as "sprite_bottom_pad", so the base point of a
# prop stays exactly where the object touches the floor - not at the very
# bottom of the PNG. Change one, change the other.
$SHADOW_PAD = 6

function Start-Img([int]$w, [int]$h) {
    $script:Ox = 0
    $script:Img = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $script:Gfx = [System.Drawing.Graphics]::FromImage($script:Img)
    $script:Gfx.SmoothingMode   = [System.Drawing.Drawing2D.SmoothingMode]::None
    $script:Gfx.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $script:Gfx.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
    $script:Gfx.Clear([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
}

# filled rectangle
function Fill([int]$x, [int]$y, [int]$w, [int]$h, [string]$hex) {
    if ($w -le 0 -or $h -le 0) { return }
    $br = New-Object System.Drawing.SolidBrush (Hex $hex)
    $script:Gfx.FillRectangle($br, ($x + $script:Ox), $y, $w, $h)
    $br.Dispose()
}
# rectangle with a 1px outline
function Box([int]$x, [int]$y, [int]$w, [int]$h, [string]$fill, [string]$line) {
    Fill $x $y $w $h $line
    Fill ($x + 1) ($y + 1) ($w - 2) ($h - 2) $fill
}
# aliased ellipse
function Oval([int]$x, [int]$y, [int]$w, [int]$h, [string]$hex) {
    $br = New-Object System.Drawing.SolidBrush (Hex $hex)
    $script:Gfx.FillEllipse($br, ($x + $script:Ox), $y, $w, $h)
    $br.Dispose()
}

# An ellipse that ERASES. Oval() composites SourceOver, so painting with a
# transparent brush does nothing at all - a ring needs this instead.
function Hole([int]$x, [int]$y, [int]$w, [int]$h) {
    $old = $script:Gfx.CompositingMode
    $script:Gfx.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    $br = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
    $script:Gfx.FillEllipse($br, ($x + $script:Ox), $y, $w, $h)
    $br.Dispose()
    $script:Gfx.CompositingMode = $old
}

# A 1px outline drawn OUTSIDE whatever is already on the canvas.
# Turns a pile of overlapping ovals into one cartoon shape with a clean border.
# Call it after everything else and before Save-Img.
function Edge([string]$hex) {
    $w = $script:Img.Width; $h = $script:Img.Height
    $col = Hex $hex
    $mask = New-Object 'bool[,]' $w, $h
    for ($y = 0; $y -lt $h; $y++) {
        for ($x = 0; $x -lt $w; $x++) { $mask[$x, $y] = ($script:Img.GetPixel($x, $y).A -gt 8) }
    }
    $dirs = @(@(0, -1), @(0, 1), @(-1, 0), @(1, 0))
    for ($y = 0; $y -lt $h; $y++) {
        for ($x = 0; $x -lt $w; $x++) {
            if ($mask[$x, $y]) { continue }
            foreach ($d in $dirs) {
                $nx = $x + $d[0]; $ny = $y + $d[1]
                if ($nx -ge 0 -and $nx -lt $w -and $ny -ge 0 -and $ny -lt $h -and $mask[$nx, $ny]) {
                    $script:Img.SetPixel($x, $y, $col); break
                }
            }
        }
    }
}

# A prop canvas: 4px of slack on each side and $SHADOW_PAD at the bottom, with
# the contact shadow already painted in. Draw the object in its own 0..w / 0..h
# coordinates and it lands on top of the shadow.
function Start-Prop([int]$w, [int]$h) {
    Start-Img ($w + 8) ($h + $SHADOW_PAD)
    Oval (4 - [int]($w * 0.06)) ($h - 4) ([int]($w * 1.12)) 10 '00000024'
    Oval (4 + [int]($w * 0.06)) ($h - 3) ([int]($w * 0.88)) 8 '00000030'
    $script:Ox = 4
}

# A wall-mounted thing casts a small offset shadow onto the wall instead of a
# puddle on the floor. Same padding as Start-Prop so prop.gd can use one number.
function Start-Wall([int]$w, [int]$h) {
    Start-Img ($w + 8) ($h + $SHADOW_PAD)
    Fill 7 3 $w $h '0000002E'
    $script:Ox = 4
}

# Something that is part OF the wall (a door), not sitting in front of it.
# No shadow at all - it would give away that the door is a separate sprite.
# Keeps the same padding so prop.gd can still use one sprite_bottom_pad.
function Start-Flat([int]$w, [int]$h) {
    Start-Img ($w + 8) ($h + $SHADOW_PAD)
    $script:Ox = 4
}

function Save-Img([string]$dir, [string]$name) {
    $script:Gfx.Dispose()
    $path = Join-Path $dir ($name + '.png')
    $script:Img.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Output ("  {0,-16} {1}x{2}" -f ($name + '.png'), $script:Img.Width, $script:Img.Height)
    $script:Img.Dispose()
    $script:Img = $null
}
