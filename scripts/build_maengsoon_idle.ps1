param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

function New-TransparentBitmap {
    param([int]$Width, [int]$Height)

    $bitmap = [System.Drawing.Bitmap]::new($Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try { $graphics.Clear([System.Drawing.Color]::Transparent) }
    finally { $graphics.Dispose() }
    return $bitmap
}

function Get-OpaqueBounds {
    param(
        [System.Drawing.Bitmap]$Image,
        [System.Drawing.Rectangle]$SearchRectangle,
        [int]$AlphaThreshold = 4,
        [int]$Expansion = 2
    )

    $left = $SearchRectangle.Right
    $top = $SearchRectangle.Bottom
    $right = -1
    $bottom = -1
    for ($y = $SearchRectangle.Top; $y -lt $SearchRectangle.Bottom; $y++) {
        for ($x = $SearchRectangle.Left; $x -lt $SearchRectangle.Right; $x++) {
            if ($Image.GetPixel($x, $y).A -gt $AlphaThreshold) {
                if ($x -lt $left) { $left = $x }
                if ($x -gt $right) { $right = $x }
                if ($y -lt $top) { $top = $y }
                if ($y -gt $bottom) { $bottom = $y }
            }
        }
    }

    if ($right -lt 0) { throw "No visible sprite found in quadrant $SearchRectangle." }

    $left = [Math]::Max($SearchRectangle.Left, $left - $Expansion)
    $top = [Math]::Max($SearchRectangle.Top, $top - $Expansion)
    $right = [Math]::Min($SearchRectangle.Right - 1, $right + $Expansion)
    $bottom = [Math]::Min($SearchRectangle.Bottom - 1, $bottom + $Expansion)
    return [System.Drawing.Rectangle]::new($left, $top, $right - $left + 1, $bottom - $top + 1)
}

$sourcePath = Join-Path $ProjectRoot 'assets\characters\sprites\maengsoon_idle_2x2_4frames_v1.png'
$runtimeDir = Join-Path $ProjectRoot 'assets\characters\runtime\maengsoon\idle'
New-Item -ItemType Directory -Force -Path $runtimeDir | Out-Null

$source = [System.Drawing.Bitmap]::FromFile($sourcePath)
try {
    if ($source.Width -ne 1230 -or $source.Height -ne 1278) {
        throw "Unexpected Maengsoon idle source size: $($source.Width)x$($source.Height)"
    }

    # Large independent canvases deliberately preserve the original pixels.
    # The 64 px bottom and >=70 px top safety zones prevent texture filtering,
    # scaling, or future atlas packing from shaving off hands, feet, or eyes.
    $canvasSize = 704
    $baselineY = 640
    $strip = New-TransparentBitmap -Width ($canvasSize * 4) -Height $canvasSize
    try {
        $stripGraphics = [System.Drawing.Graphics]::FromImage($strip)
        try {
            for ($index = 0; $index -lt 4; $index++) {
                $row = [int][Math]::Floor($index / 2)
                $column = $index % 2
                $left = [int][Math]::Round($column * $source.Width / 2.0)
                $right = [int][Math]::Round(($column + 1) * $source.Width / 2.0)
                $top = [int][Math]::Round($row * $source.Height / 2.0)
                $bottom = [int][Math]::Round(($row + 1) * $source.Height / 2.0)
                $quadrant = [System.Drawing.Rectangle]::new($left, $top, $right - $left, $bottom - $top)
                $bounds = Get-OpaqueBounds -Image $source -SearchRectangle $quadrant

                if ($bounds.Width -gt ($canvasSize - 96) -or $bounds.Height -gt ($canvasSize - 96)) {
                    throw "Frame $($index + 1) is too large for a safe ${canvasSize}px canvas: $bounds"
                }

                $frame = New-TransparentBitmap -Width $canvasSize -Height $canvasSize
                try {
                    $graphics = [System.Drawing.Graphics]::FromImage($frame)
                    try {
                        $destinationX = [int][Math]::Round(($canvasSize - $bounds.Width) / 2.0)
                        $destinationY = $baselineY - $bounds.Height
                        $destination = [System.Drawing.Rectangle]::new($destinationX, $destinationY, $bounds.Width, $bounds.Height)
                        $graphics.DrawImage($source, $destination, $bounds, [System.Drawing.GraphicsUnit]::Pixel)
                    }
                    finally { $graphics.Dispose() }

                    $framePath = Join-Path $runtimeDir "maengsoon_idle_$($index + 1).png"
                    $frame.Save($framePath, [System.Drawing.Imaging.ImageFormat]::Png)
                    $stripGraphics.DrawImageUnscaled($frame, $index * $canvasSize, 0)
                }
                finally { $frame.Dispose() }
            }
        }
        finally { $stripGraphics.Dispose() }

        $strip.Save((Join-Path $runtimeDir 'maengsoon_idle_strip.png'), [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally { $strip.Dispose() }
}
finally { $source.Dispose() }

Write-Output 'Maengsoon idle frames built: 4 independent 704x704 PNGs.'
