param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

function Get-AlphaBounds {
    param([System.Drawing.Bitmap]$Bitmap)

    $left = $Bitmap.Width
    $top = $Bitmap.Height
    $right = -1
    $bottom = -1
    for ($y = 0; $y -lt $Bitmap.Height; $y++) {
        for ($x = 0; $x -lt $Bitmap.Width; $x++) {
            if ($Bitmap.GetPixel($x, $y).A -gt 0) {
                if ($x -lt $left) { $left = $x }
                if ($x -gt $right) { $right = $x }
                if ($y -lt $top) { $top = $y }
                if ($y -gt $bottom) { $bottom = $y }
            }
        }
    }
    if ($right -lt 0) { throw 'The image contains no visible pixels.' }
    return [PSCustomObject]@{
        Left = $left
        Top = $top
        Right = $right
        Bottom = $bottom
        RightMargin = $Bitmap.Width - 1 - $right
        BottomMargin = $Bitmap.Height - 1 - $bottom
    }
}

$checks = @(
    @{ Name = 'BackgroundWithIntegratedBed'; RelativePath = 'assets\backgrounds\room_with_bed_corner_v1.png'; Width = 1672; Height = 941; Transparent = $false },
    @{ Name = 'SleepCapture'; RelativePath = 'qa\bedroom_sleep_corner.png'; Width = 0; Height = 0; Transparent = $false },
    @{ Name = 'MovementCapture'; RelativePath = 'qa\bedroom_awake_corner.png'; Width = 0; Height = 0; Transparent = $false }
)

$results = foreach ($check in $checks) {
    $path = Join-Path $ProjectRoot $check.RelativePath
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing asset: $path" }
    $bitmap = [System.Drawing.Bitmap]::FromFile($path)
    try {
        if ($check.Width -gt 0 -and ($bitmap.Width -ne $check.Width -or $bitmap.Height -ne $check.Height)) {
            throw "$($check.Name) has unexpected size $($bitmap.Width)x$($bitmap.Height)."
        }
        if ($check.Name -like '*Capture') {
            $aspectRatio = $bitmap.Width / $bitmap.Height
            if ($bitmap.Width -lt 1280 -or [Math]::Abs($aspectRatio - (16.0 / 9.0)) -gt 0.01) {
                throw "GodotCapture must be at least 1280 px wide and 16:9; got $($bitmap.Width)x$($bitmap.Height)."
            }
        }

        $cornerAlpha = @(
            $bitmap.GetPixel(0, 0).A,
            $bitmap.GetPixel($bitmap.Width - 1, 0).A,
            $bitmap.GetPixel(0, $bitmap.Height - 1).A,
            $bitmap.GetPixel($bitmap.Width - 1, $bitmap.Height - 1).A
        )

        if ($check.Transparent -and ($cornerAlpha | Where-Object { $_ -ne 0 })) {
            throw "$($check.Name) must have transparent corners."
        }
        if (-not $check.Transparent -and ($cornerAlpha | Where-Object { $_ -ne 255 })) {
            throw "$($check.Name) must be opaque at every corner."
        }

        $bounds = if ($check.Transparent) { Get-AlphaBounds -Bitmap $bitmap } else { $null }
        if ($check.ContainsKey('MinMargin')) {
            $minimumMargin = @($bounds.Left, $bounds.Top, $bounds.RightMargin, $bounds.BottomMargin) | Measure-Object -Minimum
            if ($minimumMargin.Minimum -lt $check.MinMargin) {
                throw "$($check.Name) lacks the required $($check.MinMargin) px safety margin."
            }
        }

        [PSCustomObject]@{
            Asset = $check.Name
            Size = "$($bitmap.Width)x$($bitmap.Height)"
            AlphaBounds = if ($bounds) { "$($bounds.Left),$($bounds.Top)-$($bounds.Right),$($bounds.Bottom)" } else { 'opaque' }
            Status = 'PASS'
        }
    }
    finally { $bitmap.Dispose() }
}

$results | Format-Table -AutoSize
