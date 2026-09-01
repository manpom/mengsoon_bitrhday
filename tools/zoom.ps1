param([int]$MengdolVariant = 0, [int]$MengsoonVariant = 2)

# quick eyeball helper: rebuild both 64x64 characters, bake the PNGs, and
# write tools/zoom.png at 10x so the pixels are readable.
#
# The defaults are the ADOPTED pair - mengdol variant 0 (the first published
# version: no front teeth) and mengsoon variant 2 (solid teeth, no divider).
# Pass different numbers to try another combination without editing anything.
$root = Split-Path -Parent $PSScriptRoot
& powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'build64.ps1') -Who mengdol -Variant $MengdolVariant
& powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'build64.ps1') -Who mengsoon -Variant $MengsoonVariant
& powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'generate_sprites.ps1')

Add-Type -AssemblyName System.Drawing
$s = 10; $gap = 8
$names = @('mengdol_idle', 'mengsoon_idle')
$pv = New-Object System.Drawing.Bitmap((2 * 64 * $s + 3 * $gap), (64 * $s + 2 * $gap))
$g = [System.Drawing.Graphics]::FromImage($pv)
$g.Clear([System.Drawing.Color]::FromArgb(255, 60, 66, 86))
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$cx = $gap
foreach ($n in $names) {
    $p = Join-Path $root ("assets\sprites\characters\$n.png")
    $b = [System.Drawing.Bitmap]::FromFile($p)
    $g.DrawImage($b, $cx, $gap, (64 * $s), (64 * $s))
    $cx += 64 * $s + $gap
    $b.Dispose()
}
$g.Dispose()
$pv.Save((Join-Path $PSScriptRoot 'zoom.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$pv.Dispose()
Write-Output "tools/zoom.png"
