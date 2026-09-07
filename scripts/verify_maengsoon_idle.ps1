param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$idleDir = Join-Path $ProjectRoot 'assets\characters\runtime\maengsoon\idle'
$expectedSize = 704
$safeBorder = 48
$centers = [System.Collections.Generic.List[double]]::new()
$bottoms = [System.Collections.Generic.List[int]]::new()
$failures = [System.Collections.Generic.List[string]]::new()

for ($index = 1; $index -le 4; $index++) {
    $path = Join-Path $idleDir "maengsoon_idle_$index.png"
    if (-not (Test-Path -LiteralPath $path)) {
        $failures.Add("Missing frame: $path")
        continue
    }

    $image = [System.Drawing.Bitmap]::FromFile($path)
    try {
        if ($image.Width -ne $expectedSize -or $image.Height -ne $expectedSize) {
            $failures.Add("Frame $index has size $($image.Width)x$($image.Height), expected ${expectedSize}x${expectedSize}.")
            continue
        }

        $left = $image.Width
        $right = -1
        $top = $image.Height
        $bottom = -1
        $activeColumns = [bool[]]::new($image.Width)

        for ($x = 0; $x -lt $image.Width; $x++) {
            $columnPixels = 0
            for ($y = 0; $y -lt $image.Height; $y++) {
                if ($image.GetPixel($x, $y).A -gt 4) {
                    $columnPixels++
                    if ($x -lt $left) { $left = $x }
                    if ($x -gt $right) { $right = $x }
                    if ($y -lt $top) { $top = $y }
                    if ($y -gt $bottom) { $bottom = $y }
                }
            }
            $activeColumns[$x] = $columnPixels -ge 10
        }

        if ($right -lt 0) {
            $failures.Add("Frame $index is fully transparent.")
            continue
        }

        $runs = 0
        $insideRun = $false
        foreach ($active in $activeColumns) {
            if ($active -and -not $insideRun) { $runs++; $insideRun = $true }
            elseif (-not $active) { $insideRun = $false }
        }

        $rightMargin = $image.Width - 1 - $right
        $bottomMargin = $image.Height - 1 - $bottom
        $margins = @($left, $top, $rightMargin, $bottomMargin)
        if (($margins | Measure-Object -Minimum).Minimum -lt $safeBorder) {
            $failures.Add("Frame $index violates ${safeBorder}px safety border: L=$($margins[0]) T=$($margins[1]) R=$($margins[2]) B=$($margins[3]).")
        }
        if ($runs -ne 1) {
            $failures.Add("Frame $index contains $runs substantial horizontal alpha runs; possible adjacent-frame contamination.")
        }

        $center = ($left + $right) / 2.0
        $centers.Add($center)
        $bottoms.Add($bottom)
        Write-Output ("PASS frame {0}: bbox=({1},{2})-({3},{4}), margins L/T/R/B={5}/{6}/{7}/{8}, center={9:N1}, runs={10}" -f $index, $left, $top, $right, $bottom, $margins[0], $margins[1], $margins[2], $margins[3], $center, $runs)
    }
    finally { $image.Dispose() }
}

if ($centers.Count -eq 4) {
    $centerSpread = ($centers | Measure-Object -Maximum).Maximum - ($centers | Measure-Object -Minimum).Minimum
    $bottomSpread = ($bottoms | Measure-Object -Maximum).Maximum - ($bottoms | Measure-Object -Minimum).Minimum
    if ($centerSpread -gt 2.0) { $failures.Add("Horizontal center drift is $centerSpread px (maximum 2 px).") }
    if ($bottomSpread -gt 2) { $failures.Add("Foot baseline drift is $bottomSpread px (maximum 2 px).") }
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) { Write-Error $failure }
    exit 1
}

Write-Output 'MAENGSOON_IDLE_VERIFY_PASS: 4 safe, isolated, aligned frames.'
