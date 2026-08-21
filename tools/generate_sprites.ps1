# ============================================================
#  맹꽁의 기억 - 픽셀 스프라이트 생성기
# ------------------------------------------------------------
#  tools/art/*.txt (아스키 도트 그림) + tools/art/_palette.txt
#  를 읽어서 assets/sprites/characters/*.png 로 구워냅니다.
#
#  사용법 (프로젝트 폴더에서):
#     powershell -ExecutionPolicy Bypass -File tools\generate_sprites.ps1
#
#  도트를 수정하고 싶으면 tools/art/*.txt 를 메모장으로 열어
#  글자만 바꾸고 이 스크립트를 다시 실행하면 됩니다.
# ============================================================

Add-Type -AssemblyName System.Drawing

$Root      = Split-Path -Parent $PSScriptRoot
$ArtDir    = Join-Path $PSScriptRoot 'art'
$OutDir    = Join-Path $Root 'assets\sprites\characters'
$PreviewOut= Join-Path $PSScriptRoot 'preview.png'

if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Force -Path $OutDir | Out-Null }

# ---------- 1. 팔레트 읽기 ----------
$palette = @{}
foreach ($line in Get-Content (Join-Path $ArtDir '_palette.txt')) {
    $t = $line.Trim()
    if ($t -eq '' -or $t.StartsWith('#')) { continue }
    $parts = $t -split '\s+'
    $ch  = $parts[0]
    $hex = $parts[1]
    if ($hex -eq 'none') {
        $palette[$ch] = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)
    } else {
        $r = [Convert]::ToInt32($hex.Substring(0,2), 16)
        $g = [Convert]::ToInt32($hex.Substring(2,2), 16)
        $b = [Convert]::ToInt32($hex.Substring(4,2), 16)
        $palette[$ch] = [System.Drawing.Color]::FromArgb(255, $r, $g, $b)
    }
}

# ---------- 2. 아스키 아트 -> Bitmap ----------
function ConvertTo-Bitmap([string]$path) {
    $rows = @(Get-Content $path | Where-Object { $_ -ne '' })
    $h = $rows.Count
    $w = ($rows | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum
    $bmp = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    for ($y = 0; $y -lt $h; $y++) {
        $row = $rows[$y]
        for ($x = 0; $x -lt $w; $x++) {
            $ch = '.'
            if ($x -lt $row.Length) { $ch = $row.Substring($x, 1) }
            if ($palette.ContainsKey($ch)) {
                $bmp.SetPixel($x, $y, $palette[$ch])
            } else {
                Write-Warning "$([System.IO.Path]::GetFileName($path)) ($x,$y): 팔레트에 없는 문자 '$ch'"
                $bmp.SetPixel($x, $y, [System.Drawing.Color]::Magenta)
            }
        }
    }
    return $bmp
}

$made = @{}
foreach ($f in Get-ChildItem $ArtDir -Filter '*.txt' | Where-Object { -not $_.Name.StartsWith('_') }) {
    $bmp = ConvertTo-Bitmap $f.FullName
    $out = Join-Path $OutDir ($f.BaseName + '.png')
    $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
    $made[$f.BaseName] = $bmp
    Write-Output ("생성: assets/sprites/characters/{0}.png  ({1}x{2})" -f $f.BaseName, $bmp.Width, $bmp.Height)
}

# ---------- 3. 확대 미리보기 (게임에 쓰이진 않음, 눈으로 확인용) ----------
$scale = 8
$gap   = 16
$totalW = 0
$maxH   = 0
foreach ($b in $made.Values) { $totalW += $b.Width * $scale + $gap; $maxH = [Math]::Max($maxH, $b.Height * $scale) }
$pv = New-Object System.Drawing.Bitmap(($totalW + $gap), ($maxH + $gap * 2), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gfx = [System.Drawing.Graphics]::FromImage($pv)
$gfx.Clear([System.Drawing.Color]::FromArgb(255, 40, 44, 60))
$gfx.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$gfx.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$cx = $gap
foreach ($b in $made.Values) {
    # 발바닥을 같은 바닥선에 맞춰서 키 차이가 보이게 배치
    $y = $gap + ($maxH - $b.Height * $scale)
    $gfx.DrawImage($b, $cx, $y, $b.Width * $scale, $b.Height * $scale)
    $cx += $b.Width * $scale + $gap
}
$gfx.Dispose()
$pv.Save($PreviewOut, [System.Drawing.Imaging.ImageFormat]::Png)
Write-Output "미리보기: tools/preview.png"

foreach ($b in $made.Values) { $b.Dispose() }
$pv.Dispose()
