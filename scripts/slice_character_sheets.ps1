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

function Get-FractionalCell {
    param(
        [System.Drawing.Bitmap]$Image,
        [int]$Column,
        [int]$Row,
        [int]$Columns,
        [int]$Rows
    )

    $left = [int][Math]::Round($Column * $Image.Width / [double]$Columns)
    $right = [int][Math]::Round(($Column + 1) * $Image.Width / [double]$Columns)
    $top = [int][Math]::Round($Row * $Image.Height / [double]$Rows)
    $bottom = [int][Math]::Round(($Row + 1) * $Image.Height / [double]$Rows)
    return [System.Drawing.Rectangle]::new($left, $top, $right - $left, $bottom - $top)
}

function Get-SpriteCells {
    param(
        [System.Drawing.Bitmap]$Image,
        [int]$Row,
        [int]$Columns = 10,
        [int]$Rows = 2
    )

    $top = [int][Math]::Round($Row * $Image.Height / [double]$Rows)
    $bottom = [int][Math]::Round(($Row + 1) * $Image.Height / [double]$Rows)
    $active = [bool[]]::new($Image.Width)

    for ($x = 0; $x -lt $Image.Width; $x++) {
        $opaqueCount = 0
        for ($y = $top; $y -lt $bottom; $y++) {
            if ($Image.GetPixel($x, $y).A -ge 96) {
                $opaqueCount++
                if ($opaqueCount -ge 10) { break }
            }
        }
        $active[$x] = $opaqueCount -ge 10
    }

    $runs = [System.Collections.Generic.List[object]]::new()
    $start = -1
    for ($x = 0; $x -lt $Image.Width; $x++) {
        if ($active[$x] -and $start -lt 0) { $start = $x }
        if ((-not $active[$x] -or $x -eq ($Image.Width - 1)) -and $start -ge 0) {
            $end = if ($active[$x]) { $x } else { $x - 1 }
            if (($end - $start + 1) -ge 20) {
                $runs.Add([PSCustomObject]@{ Start = $start; End = $end })
            }
            $start = -1
        }
    }

    if ($runs.Count -ne $Columns -and $runs.Count -ne ($Columns + 1)) {
        throw "Expected $Columns sprites (or one repeated loop frame), found $($runs.Count) in row $Row."
    }

    $rectangles = [System.Collections.Generic.List[System.Drawing.Rectangle]]::new()
    for ($index = 0; $index -lt $Columns; $index++) {
        $left = if ($index -eq 0) {
            0
        }
        else {
            [int][Math]::Floor(($runs[$index - 1].End + $runs[$index].Start) / 2.0) + 1
        }

        $rightExclusive = if ($index -lt ($runs.Count - 1)) {
            [int][Math]::Floor(($runs[$index].End + $runs[$index + 1].Start) / 2.0) + 1
        }
        else {
            $Image.Width
        }

        $rectangles.Add([System.Drawing.Rectangle]::new($left, $top, $rightExclusive - $left, $bottom - $top))
    }

    return $rectangles.ToArray()
}

function Draw-Cell {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.Bitmap]$Source,
        [System.Drawing.Rectangle]$SourceRectangle,
        [int]$CellLeft,
        [int]$CellTop,
        [int]$ContentWidth,
        [int]$ContentHeight,
        [int]$Padding
    )

    $offsetX = [int][Math]::Floor(($ContentWidth - $SourceRectangle.Width) / 2.0)
    $offsetY = [int][Math]::Floor(($ContentHeight - $SourceRectangle.Height) / 2.0)
    $destination = [System.Drawing.Rectangle]::new(
        $CellLeft + $Padding + $offsetX,
        $CellTop + $Padding + $offsetY,
        $SourceRectangle.Width,
        $SourceRectangle.Height
    )
    $Graphics.DrawImage($Source, $destination, $SourceRectangle, [System.Drawing.GraphicsUnit]::Pixel)
}

function Save-Frame {
    param(
        [System.Drawing.Bitmap]$Source,
        [System.Drawing.Rectangle]$SourceRectangle,
        [int]$ContentWidth,
        [int]$ContentHeight,
        [int]$Padding,
        [string]$Destination
    )

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Destination) | Out-Null
    $frame = New-TransparentBitmap -Width ($ContentWidth + (2 * $Padding)) -Height ($ContentHeight + (2 * $Padding))
    try {
        $graphics = [System.Drawing.Graphics]::FromImage($frame)
        try {
            Draw-Cell -Graphics $graphics -Source $Source -SourceRectangle $SourceRectangle -CellLeft 0 -CellTop 0 -ContentWidth $ContentWidth -ContentHeight $ContentHeight -Padding $Padding
        }
        finally { $graphics.Dispose() }
        $frame.Save($Destination, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally { $frame.Dispose() }
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
    if ($right -lt 0) { throw 'No visible sprite was found inside a detected cell.' }

    $left = [Math]::Max($SearchRectangle.Left, $left - $Expansion)
    $top = [Math]::Max($SearchRectangle.Top, $top - $Expansion)
    $right = [Math]::Min($SearchRectangle.Right - 1, $right + $Expansion)
    $bottom = [Math]::Min($SearchRectangle.Bottom - 1, $bottom + $Expansion)
    return [System.Drawing.Rectangle]::new($left, $top, $right - $left + 1, $bottom - $top + 1)
}

function New-AnchoredSpriteFrame {
    param(
        [System.Drawing.Bitmap]$Source,
        [System.Drawing.Rectangle]$SourceRectangle,
        [int]$CanvasSize = 512,
        [int]$BaselineY = 448
    )

    if ($SourceRectangle.Width -gt ($CanvasSize - 96) -or $SourceRectangle.Height -gt ($CanvasSize - 96)) {
        throw "Sprite $SourceRectangle is too large for the ${CanvasSize}px canvas with 48px safety margins."
    }

    $frame = New-TransparentBitmap -Width $CanvasSize -Height $CanvasSize
    $graphics = [System.Drawing.Graphics]::FromImage($frame)
    try {
        # Every pose shares the same horizontal center and bottom anchor. This
        # removes source-sheet spacing jitter without scaling the artwork.
        $destinationX = [int][Math]::Round(($CanvasSize - $SourceRectangle.Width) / 2.0)
        $destinationY = $BaselineY - $SourceRectangle.Height
        $destination = [System.Drawing.Rectangle]::new(
            $destinationX,
            $destinationY,
            $SourceRectangle.Width,
            $SourceRectangle.Height
        )
        $graphics.DrawImage($Source, $destination, $SourceRectangle, [System.Drawing.GraphicsUnit]::Pixel)
    }
    finally { $graphics.Dispose() }
    return $frame
}

function Build-WalkAssets {
    param([string]$Character)

    $partRoot = Join-Path $ProjectRoot 'assets\characters\sprites\v2_parts'
    $parts = @(
        @{ File = "${Character}_walk_s-se_10f_v2.png"; Directions = @('s', 'se') },
        @{ File = "${Character}_walk_e-ne_10f_v2.png"; Directions = @('e', 'ne') },
        @{ File = "${Character}_walk_n-nw_10f_v2.png"; Directions = @('n', 'nw') },
        @{ File = "${Character}_walk_w-sw_10f_v2.png"; Directions = @('w', 'sw') }
    )

    $columns = 10
    $padding = 32
    # The generator occasionally emits a repeated 11th loop pose. We detect
    # sprites from transparent gaps and keep ten poses; 256 px leaves room for
    # uneven source spacing before the additional 32 px runtime padding.
    $contentWidth = 256
    $contentHeight = 362
    $paddedWidth = $contentWidth + (2 * $padding)
    $paddedHeight = $contentHeight + (2 * $padding)
    $runtimeDir = Join-Path $ProjectRoot "assets\characters\runtime\$Character\walk"
    New-Item -ItemType Directory -Force -Path $runtimeDir | Out-Null

    $master = New-TransparentBitmap -Width ($paddedWidth * $columns) -Height ($paddedHeight * 8)
    try {
        $masterGraphics = [System.Drawing.Graphics]::FromImage($master)
        try {
            $directionIndex = 0
            foreach ($part in $parts) {
                $sourcePath = Join-Path $partRoot $part.File
                $source = [System.Drawing.Bitmap]::FromFile($sourcePath)
                try {
                    if ($source.Width -ne 2172 -or $source.Height -ne 724) {
                        throw "Unexpected walk part size: $sourcePath ($($source.Width)x$($source.Height))"
                    }

                    for ($row = 0; $row -lt 2; $row++) {
                        $direction = $part.Directions[$row]
                        $spriteCells = Get-SpriteCells -Image $source -Row $row -Columns $columns -Rows 2
                        $strip = New-TransparentBitmap -Width ($paddedWidth * $columns) -Height $paddedHeight
                        try {
                            $stripGraphics = [System.Drawing.Graphics]::FromImage($strip)
                            try {
                                for ($column = 0; $column -lt $columns; $column++) {
                                    $sourceRectangle = $spriteCells[$column]
                                    Draw-Cell -Graphics $stripGraphics -Source $source -SourceRectangle $sourceRectangle -CellLeft ($column * $paddedWidth) -CellTop 0 -ContentWidth $contentWidth -ContentHeight $contentHeight -Padding $padding
                                    Draw-Cell -Graphics $masterGraphics -Source $source -SourceRectangle $sourceRectangle -CellLeft ($column * $paddedWidth) -CellTop ($directionIndex * $paddedHeight) -ContentWidth $contentWidth -ContentHeight $contentHeight -Padding $padding

                                    $framePath = Join-Path $runtimeDir "${Character}_walk_${direction}_$($column + 1).png"
                                    Save-Frame -Source $source -SourceRectangle $sourceRectangle -ContentWidth $contentWidth -ContentHeight $contentHeight -Padding $padding -Destination $framePath
                                }
                            }
                            finally { $stripGraphics.Dispose() }
                            $strip.Save((Join-Path $runtimeDir "${Character}_walk_${direction}_strip.png"), [System.Drawing.Imaging.ImageFormat]::Png)
                        }
                        finally { $strip.Dispose() }
                        $directionIndex++
                    }
                }
                finally { $source.Dispose() }
            }
        }
        finally { $masterGraphics.Dispose() }

        $masterPath = Join-Path $ProjectRoot "assets\characters\sprites\${Character}_walk_8dir_10frames_master_v2.png"
        $master.Save($masterPath, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally { $master.Dispose() }
}

function Build-SleepWakeAssets {
    param([string]$SourcePath)

    $source = [System.Drawing.Bitmap]::FromFile($SourcePath)
    try {
        if ($source.Width -ne 1983 -or $source.Height -ne 793) {
            throw "Unexpected sleep/wake size: $($source.Width)x$($source.Height)"
        }

        $columns = 5
        $canvasSize = 512
        $baselineY = 448
        $runtimeDir = Join-Path $ProjectRoot 'assets\characters\runtime\maengdol\bed'
        New-Item -ItemType Directory -Force -Path $runtimeDir | Out-Null
        $states = @('sleep', 'wake')

        for ($row = 0; $row -lt 2; $row++) {
            $state = $states[$row]
            $selectedColumns = if ($state -eq 'wake') { @(0, 1, 3, 4) } else { @(0, 1, 2, 3, 4) }
            # Detect the five real transparent-gap cells first. Equal-width
            # slicing cut frame 4 into frame 3 because the generated poses were
            # not placed on a mathematically uniform grid.
            $detectedCells = Get-SpriteCells -Image $source -Row $row -Columns $columns -Rows 2
            $strip = New-TransparentBitmap -Width ($canvasSize * $selectedColumns.Count) -Height $canvasSize
            try {
                $stripGraphics = [System.Drawing.Graphics]::FromImage($strip)
                try {
                    for ($outputIndex = 0; $outputIndex -lt $selectedColumns.Count; $outputIndex++) {
                        $column = $selectedColumns[$outputIndex]
                        $sourceRectangle = Get-OpaqueBounds -Image $source -SearchRectangle $detectedCells[$column]
                        $frame = New-AnchoredSpriteFrame -Source $source -SourceRectangle $sourceRectangle -CanvasSize $canvasSize -BaselineY $baselineY
                        $framePath = Join-Path $runtimeDir "maengdol_${state}_$($column + 1).png"
                        try {
                            $frame.Save($framePath, [System.Drawing.Imaging.ImageFormat]::Png)
                            $stripGraphics.DrawImageUnscaled($frame, $outputIndex * $canvasSize, 0)
                        }
                        finally { $frame.Dispose() }
                    }
                }
                finally { $stripGraphics.Dispose() }
                $strip.Save((Join-Path $runtimeDir "maengdol_${state}_strip.png"), [System.Drawing.Imaging.ImageFormat]::Png)
            }
            finally { $strip.Dispose() }
        }
    }
    finally { $source.Dispose() }
}

$spriteRoot = Join-Path $ProjectRoot 'assets\characters\sprites'
Build-WalkAssets -Character 'maengdol'
Build-WalkAssets -Character 'maengsoon'
Build-SleepWakeAssets -SourcePath (Join-Path $spriteRoot 'maengdol_sleep_wake_2x5_master_v3.png')

Write-Output 'Character sprite assets built successfully (5 sleep frames, 4 wake frames).'
