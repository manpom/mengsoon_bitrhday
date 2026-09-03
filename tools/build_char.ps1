# ============================================================
#  Character frame builder
# ------------------------------------------------------------
#  Calls build64.ps1 once per frame and bakes every result to PNG.
#
#  Run (from the project folder):
#     powershell -ExecutionPolicy Bypass -File tools\build_char.ps1
#
#  Output -> assets/sprites/characters/<who>/
#     <who>_down_idle.png   front, standing
#     <who>_down_walk1.png  front, left foot up
#     <who>_down_walk2.png  front, right foot up
#     <who>_up_*.png        seen from behind (walking away)
#     <who>_side_*.png      head turned to the right (flip for left)
#     <who>_face_happy.png  ... surprise / sad / angry / sleepy
#
#  The intermediate ASCII art goes to tools/art/frames/ so you can open any
#  single frame in a text editor and see exactly which pixel is wrong.
#
#  ASCII-only comments on purpose: PS 5.1 reads BOM-less UTF-8 as ANSI and a
#  mis-decoded byte can act as a line continuation, swallowing the next line.
# ============================================================

param([string[]]$Chars = @("mengdol", "mengsoon"))

Add-Type -AssemblyName System.Drawing

$Root     = Split-Path -Parent $PSScriptRoot
$ArtDir   = Join-Path $PSScriptRoot 'art'
$FrameDir = Join-Path $ArtDir 'frames'
$OutRoot  = Join-Path $Root 'assets\sprites\characters'
$Build64  = Join-Path $PSScriptRoot 'build64.ps1'

if (-not (Test-Path $FrameDir)) { New-Item -ItemType Directory -Force -Path $FrameDir | Out-Null }

# 채택된 얼굴 옵션 (README 참고)
$VARIANT = @{ mengdol = 0; mengsoon = 2 }

$DIRS  = @('down', 'up')
$STEPS = @(@{ n = 'idle'; v = 0 }, @{ n = 'walk1'; v = 1 }, @{ n = 'walk2'; v = -1 })
$FACES = @('happy', 'surprise', 'sad', 'angry', 'sleepy', 'shy')

# 추억 1 (원투 방구) 은 욕실이 배경이라 옷을 안 입은 그림이 필요합니다.
# @{ 이름 = 포즈, 얼굴 }
$NUDE = @(
    @{ n = 'stand';    pose = 'stand';  face = 'normal' }
    @{ n = 'guard';    pose = 'guard';  face = 'normal' }   # 복싱 자세
    @{ n = 'punch1';   pose = 'punch1'; face = 'normal' }   # 원 (왼손)
    @{ n = 'punch2';   pose = 'punch2'; face = 'normal' }   # 투 (오른손)
    @{ n = 'surprise'; pose = 'stand';  face = 'surprise' }
    @{ n = 'shy';      pose = 'stand';  face = 'shy' }      # 얼굴이 붉어짐
    @{ n = 'laugh';    pose = 'laugh';  face = 'laugh' }    # 배꼽 잡고 눈물나게 웃음
    # 리듬 파트용: 맹돌이는 처음부터 끝까지 눈물 흘리며 웃고 있습니다
    @{ n = 'lol';        pose = 'stand';  face = 'laugh' }
    @{ n = 'lol_punch1'; pose = 'punch1'; face = 'laugh' }   # 원
    @{ n = 'lol_punch2'; pose = 'punch2'; face = 'laugh' }   # 투
    @{ n = 'lol_fart';   pose = 'fart';   face = 'laugh' }   # 뿡
)

# ---------- palette ----------
$palette = New-Object System.Collections.Hashtable ([System.StringComparer]::Ordinal)
foreach ($line in Get-Content (Join-Path $ArtDir '_palette.txt')) {
    $t = $line.Trim()
    if ($t -eq '' -or $t.StartsWith('#')) { continue }
    $parts = $t -split '\s+'
    if ($parts[1] -eq 'none') {
        $palette[$parts[0]] = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)
    }
    else {
        $palette[$parts[0]] = [System.Drawing.Color]::FromArgb(255,
            [Convert]::ToInt32($parts[1].Substring(0, 2), 16),
            [Convert]::ToInt32($parts[1].Substring(2, 2), 16),
            [Convert]::ToInt32($parts[1].Substring(4, 2), 16))
    }
}

function ConvertTo-Png([string]$txt, [string]$png) {
    $rows = @(Get-Content $txt | Where-Object { $_ -ne '' })
    $h = $rows.Count
    $w = ($rows | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum
    $bmp = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    for ($y = 0; $y -lt $h; $y++) {
        for ($x = 0; $x -lt $w; $x++) {
            $ch = '.'
            if ($x -lt $rows[$y].Length) { $ch = $rows[$y].Substring($x, 1) }
            if ($palette.ContainsKey($ch)) { $bmp.SetPixel($x, $y, $palette[$ch]) }
            else {
                Write-Warning "$([System.IO.Path]::GetFileName($txt)) ($x,$y): unknown palette char '$ch'"
                $bmp.SetPixel($x, $y, [System.Drawing.Color]::Magenta)
            }
        }
    }
    $bmp.Save($png, [System.Drawing.Imaging.ImageFormat]::Png)
    return $bmp
}

$sheet = @{}

foreach ($who in $Chars) {
    $outDir = Join-Path $OutRoot $who
    if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }
    $v = $VARIANT[$who]
    Write-Output "$who (variant $v)"

    $jobs = @()
    foreach ($d in $DIRS) {
        foreach ($s in $STEPS) {
            $jobs += @{ name = "$($who)_$($d)_$($s.n)"; dir = $d; step = $s.v; face = 'normal' }
        }
    }
    foreach ($f in $FACES) {
        $jobs += @{ name = "$($who)_face_$f"; dir = 'down'; step = 0; face = $f }
    }
    # 침대에 누운 모습 (옆에서 본 침대에 머리만 베개 위로)
    $jobs += @{ name = "$($who)_lie"; dir = 'down'; step = 0; face = 'sleepy'; pose = 'lie' }
    # 욕실 컷신용 나체 포즈
    foreach ($n in $NUDE) {
        $jobs += @{ name = "$($who)_nude_$($n.n)"; dir = 'down'; step = 0
            face = $n.face; pose = $n.pose; nude = $true }
    }

    foreach ($j in $jobs) {
        $txt = Join-Path $FrameDir ($j.name + '.txt')
        $pose = 'stand'
        if ($j.ContainsKey('pose')) { $pose = $j.pose }
        if ($j.ContainsKey('nude')) {
            & $Build64 -Who $who -Variant $v -Dir $j.dir -Step $j.step -Face $j.face `
                -Pose $pose -Nude -Out $txt | Out-Null
        }
        else {
            & $Build64 -Who $who -Variant $v -Dir $j.dir -Step $j.step -Face $j.face `
                -Pose $pose -Out $txt | Out-Null
        }
        $png = Join-Path $outDir ($j.name + '.png')
        $bmp = ConvertTo-Png $txt $png
        $sheet[$j.name] = $bmp
        Write-Output ("  {0}" -f $j.name)
    }
}

# ---------- preview sheet (never shipped with the game) ----------
$scale = 3
$cols = 9
$cell = 64 * $scale + 6
$rows = [math]::Ceiling($sheet.Count / $cols)
$pv = New-Object System.Drawing.Bitmap(($cols * $cell + 6), ($rows * $cell + 6), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($pv)
$g.Clear([System.Drawing.Color]::FromArgb(255, 26, 18, 12))
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$i = 0
foreach ($k in ($sheet.Keys | Sort-Object)) {
    $cx = 6 + ($i % $cols) * $cell
    $cy = 6 + [math]::Floor($i / $cols) * $cell
    $g.DrawImage($sheet[$k], $cx, $cy, 64 * $scale, 64 * $scale)
    $i++
}
$g.Dispose()
$pv.Save((Join-Path $PSScriptRoot 'char_preview.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$pv.Dispose()
foreach ($b in $sheet.Values) { $b.Dispose() }
Write-Output "tools/char_preview.png"
