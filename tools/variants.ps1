# Build every -Variant of both characters and lay them out as one comparison
# sheet (tools/variants.png). Nothing here touches assets/ - it is a chooser.
#   powershell -ExecutionPolicy Bypass -File tools\variants.ps1
Add-Type -AssemblyName System.Drawing

$ArtDir = Join-Path $PSScriptRoot 'art'
$TmpDir = Join-Path $PSScriptRoot 'variants'
if (-not (Test-Path $TmpDir)) { New-Item -ItemType Directory -Force -Path $TmpDir | Out-Null }

# ---------- palette ----------
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
    $bmp = New-Object System.Drawing.Bitmap(64, $rows.Count, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    for ($y = 0; $y -lt $rows.Count; $y++) {
        for ($x = 0; $x -lt 64; $x++) {
            $ch = $rows[$y].Substring($x, 1)
            if ($palette.ContainsKey($ch)) { $bmp.SetPixel($x, $y, $palette[$ch]) }
            else { $bmp.SetPixel($x, $y, [System.Drawing.Color]::Magenta) }
        }
    }
    return $bmp
}

# ---------- build ----------
$variants = 1..5
$whos = @('mengdol', 'mengsoon')
foreach ($w in $whos) {
    foreach ($v in $variants) {
        & powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'build64.ps1') `
            -Who $w -Variant $v -Out (Join-Path $TmpDir "${w}_v$v.txt") | Out-Null
    }
}

# ---------- sheet ----------
$s = 6; $cellW = 64 * $s + 24; $cellH = 64 * $s + 40
$sheet = New-Object System.Drawing.Bitmap(($cellW * 5 + 24), ($cellH * 2 + 24))
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::FromArgb(255, 60, 66, 86))
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$font = New-Object System.Drawing.Font('Malgun Gothic', 15, [System.Drawing.FontStyle]::Bold)
$white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$names = @{ mengdol = '맹돌이'; mengsoon = '맹순이' }
$desc = @{ 1 = '구분선 있음'; 2 = '통짜 앞니'; 3 = '앞니 없음'; 4 = '큰 눈'; 5 = '작은 머리' }

for ($r = 0; $r -lt 2; $r++) {
    foreach ($v in $variants) {
        $p = Join-Path $TmpDir ("{0}_v{1}.txt" -f $whos[$r], $v)
        $b = ConvertTo-Bitmap $p
        $x = 12 + ($v - 1) * $cellW
        $y = 12 + $r * $cellH
        $g.DrawString(("{0} {1} · {2}" -f $names[$whos[$r]], $v, $desc[$v]), $font, $white, ($x + 6), ($y + 2))
        $g.DrawImage($b, ($x + 12), ($y + 34), (64 * $s), (64 * $s))
        $b.Dispose()
    }
}
$g.Dispose()
$sheet.Save((Join-Path $PSScriptRoot 'variants.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$sheet.Dispose()
Write-Output "tools/variants.png"

