param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

function Assert-PngSet {
    param(
        [string]$Label,
        [System.IO.FileInfo[]]$Files,
        [int]$ExpectedCount,
        [int]$ExpectedWidth,
        [int]$ExpectedHeight,
        [int]$TransparentBorder
    )

    if ($Files.Count -ne $ExpectedCount) {
        throw "$Label count mismatch: expected $ExpectedCount, found $($Files.Count)."
    }

    foreach ($file in $Files) {
        $image = [System.Drawing.Bitmap]::FromFile($file.FullName)
        try {
            if ($image.Width -ne $ExpectedWidth -or $image.Height -ne $ExpectedHeight) {
                throw "$Label size mismatch: $($file.Name) is $($image.Width)x$($image.Height)."
            }
            if (-not [System.Drawing.Image]::IsAlphaPixelFormat($image.PixelFormat)) {
                throw "$Label has no alpha channel: $($file.Name)."
            }

            for ($y = 0; $y -lt $image.Height; $y++) {
                for ($x = 0; $x -lt $TransparentBorder; $x++) {
                    if ($image.GetPixel($x, $y).A -ne 0 -or $image.GetPixel($image.Width - 1 - $x, $y).A -ne 0) {
                        throw "$Label touches a side safety border: $($file.Name)."
                    }
                }
            }
            for ($x = $TransparentBorder; $x -lt ($image.Width - $TransparentBorder); $x++) {
                for ($y = 0; $y -lt $TransparentBorder; $y++) {
                    if ($image.GetPixel($x, $y).A -ne 0 -or $image.GetPixel($x, $image.Height - 1 - $y).A -ne 0) {
                        throw "$Label touches a top/bottom safety border: $($file.Name)."
                    }
                }
            }
        }
        finally { $image.Dispose() }
    }

    [PSCustomObject]@{
        Set = $Label
        Files = $Files.Count
        Size = "${ExpectedWidth}x${ExpectedHeight}"
        Alpha = 'PASS'
        TransparentBorder = "${TransparentBorder}px PASS"
    }
}

$results = [System.Collections.Generic.List[object]]::new()
foreach ($character in @('maengdol', 'maengsoon')) {
    $walkDir = Join-Path $ProjectRoot "assets\characters\runtime\$character\walk"
    $frames = @(Get-ChildItem -LiteralPath $walkDir -Filter '*.png' | Where-Object { $_.BaseName -notlike '*_strip' })
    $strips = @(Get-ChildItem -LiteralPath $walkDir -Filter '*_strip.png')
    $results.Add((Assert-PngSet -Label "$character walk frames" -Files $frames -ExpectedCount 80 -ExpectedWidth 320 -ExpectedHeight 426 -TransparentBorder 32))
    $results.Add((Assert-PngSet -Label "$character walk strips" -Files $strips -ExpectedCount 8 -ExpectedWidth 3200 -ExpectedHeight 426 -TransparentBorder 32))
}

$bedDir = Join-Path $ProjectRoot 'assets\characters\runtime\maengdol\bed'
$bedFrames = @(Get-ChildItem -LiteralPath $bedDir -Filter '*.png' | Where-Object { $_.BaseName -notlike '*_strip' })
$sleepFrames = @($bedFrames | Where-Object { $_.BaseName -like 'maengdol_sleep_*' })
$sleepStrips = @(Get-ChildItem -LiteralPath $bedDir -Filter 'maengdol_sleep_strip.png')
$results.Add((Assert-PngSet -Label 'maengdol sleep frames' -Files $sleepFrames -ExpectedCount 5 -ExpectedWidth 512 -ExpectedHeight 512 -TransparentBorder 48))
$results.Add((Assert-PngSet -Label 'maengdol sleep strip' -Files $sleepStrips -ExpectedCount 1 -ExpectedWidth 2560 -ExpectedHeight 512 -TransparentBorder 48))

# A foreign sliver from a neighboring sprite creates a second substantial
# horizontal alpha run. Every corrected frame must contain exactly one.
foreach ($file in $bedFrames) {
    $image = [System.Drawing.Bitmap]::FromFile($file.FullName)
    try {
        $activeColumns = [bool[]]::new($image.Width)
        for ($x = 0; $x -lt $image.Width; $x++) {
            $opaquePixels = 0
            for ($y = 0; $y -lt $image.Height; $y++) {
                if ($image.GetPixel($x, $y).A -ge 32) {
                    $opaquePixels++
                    if ($opaquePixels -ge 5) { break }
                }
            }
            $activeColumns[$x] = $opaquePixels -ge 5
        }
        $runCount = 0
        $insideRun = $false
        $firstActiveColumn = -1
        $lastActiveColumn = -1
        for ($x = 0; $x -lt $image.Width; $x++) {
            if ($activeColumns[$x]) {
                if ($firstActiveColumn -lt 0) { $firstActiveColumn = $x }
                $lastActiveColumn = $x
            }
            if ($activeColumns[$x] -and -not $insideRun) { $runCount++; $insideRun = $true }
            if (-not $activeColumns[$x]) { $insideRun = $false }
        }
        if ($runCount -ne 1) { throw "Neighbor contamination detected in $($file.Name): $runCount alpha runs." }
        $centerX = ($firstActiveColumn + $lastActiveColumn) / 2.0
        if ([Math]::Abs($centerX - 255.5) -gt 2.0) {
            throw "Horizontal anchor drift detected in $($file.Name): center is $centerX."
        }
    }
    finally { $image.Dispose() }
}

$results | Format-Table -AutoSize
Write-Output 'All character asset checks passed.'
