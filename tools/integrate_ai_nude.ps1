# ============================================================
#  나체 세트(욕실 컷신 * 리듬 파트)를 192x192 게임 프레임에 배치합니다.
# ------------------------------------------------------------
#     powershell -ExecutionPolicy Bypass -File tools\integrate_ai_nude.ps1
#
#  입력: tools/ai_refs/<who>/clean/nude_<pose>.png
#        (clean_ai_refs.ps1 이 마젠타 원본에서 키잉해 둔 것)
#  출력: assets/sprites/characters/<who>/<who>_nude_<pose>.png
#
#  ★ 애니메이션이 튀지 않게: 캐릭터당 nude_stand 의 캐릭터 키로 scale 을
#    한 번 정해서 그 캐릭터의 나체 포즈 전부에 동일 적용합니다 (팔을 벌리는
#    포즈라도 키는 그대로라 서 있는 자세 기준이면 충분합니다). 딛는 발은
#    전부 FOOT_Y 에 앵커.
#
#  실제 게임(scripts/)이 참조하는 파일만 있으면 되지만, 소스가 있는
#  포즈는 전부 배치합니다 (나머지 세트와의 그림 일관성을 위해).
# ============================================================

Add-Type -AssemblyName System.Drawing

$Root = Split-Path -Parent $PSScriptRoot
$RefDir = Join-Path $Root 'tools\ai_refs'
$CharDir = Join-Path $Root 'assets\sprites\characters'

$FRAME = 192
$TARGET_H = 176.0
$FOOT_Y = 190.0

function Get-Bbox([System.Drawing.Bitmap]$bmp) {
    $w = $bmp.Width; $h = $bmp.Height
    $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
    $d = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $st = [Math]::Abs($d.Stride)
    $by = New-Object byte[] ($st * $h)
    [System.Runtime.InteropServices.Marshal]::Copy($d.Scan0, $by, 0, $by.Length)
    $bmp.UnlockBits($d)
    $mnx = 999999; $mxx = -1; $mny = 999999; $mxy = -1
    for ($y = 0; $y -lt $h; $y++) {
        for ($x = 0; $x -lt $w; $x++) {
            if ($by[$y * $st + $x * 4 + 3] -gt 16) {
                if ($x -lt $mnx) { $mnx = $x }; if ($x -gt $mxx) { $mxx = $x }
                if ($y -lt $mny) { $mny = $y }; if ($y -gt $mxy) { $mxy = $y }
            }
        }
    }
    if ($mxx -lt 0) { return $null }
    return @{ X0 = $mnx; X1 = $mxx; Y0 = $mny; Y1 = $mxy }
}

function Place([System.Drawing.Bitmap]$src, [hashtable]$bb, [double]$sc, [string]$dstPath) {
    $cx = ($bb.X0 + $bb.X1) / 2.0
    $out = New-Object System.Drawing.Bitmap($FRAME, $FRAME, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($out)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $dw = $src.Width * $sc
    $dh = $src.Height * $sc
    $dx = ($FRAME / 2.0) - $cx * $sc
    $dy = $FOOT_Y - $bb.Y1 * $sc
    $g.DrawImage($src, [single]$dx, [single]$dy, [single]$dw, [single]$dh)
    $g.Dispose()
    $out.Save($dstPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $out.Dispose()
}

$Poses = 'nude_stand', 'nude_guard', 'nude_punch1', 'nude_punch2', 'nude_surprise',
'nude_shy', 'nude_laugh', 'nude_lol', 'nude_lol_punch1', 'nude_lol_punch2', 'nude_lol_fart'

Write-Output '나체 세트 AI 레퍼런스 -> 게임 프레임 배치'
foreach ($who in 'mengdol', 'mengsoon') {
    Write-Output $who
    $dir = Join-Path $CharDir $who
    $standP = Join-Path $RefDir ("$who\clean\nude_stand.png")
    if (-not (Test-Path $standP)) { Write-Output "  (건너뜀 - nude_stand 없음)"; continue }
    $stand = [System.Drawing.Bitmap]::FromFile($standP)
    $bStand = Get-Bbox $stand
    $charH = $bStand.Y1 - $bStand.Y0
    $sc = $TARGET_H / $charH
    $stand.Dispose()

    foreach ($pose in $Poses) {
        $srcP = Join-Path $RefDir ("$who\clean\$pose.png")
        if (-not (Test-Path $srcP)) { Write-Output "  (건너뜀 - 없음: $pose)"; continue }
        $src = [System.Drawing.Bitmap]::FromFile($srcP)
        $bb = Get-Bbox $src
        if ($null -eq $bb) { Write-Output "  !! 알파 없음: $pose"; $src.Dispose(); continue }
        $dst = Join-Path $dir ("${who}_$pose.png")
        Place $src $bb $sc $dst
        Write-Output ("  {0,-20} charW {1} charH {2} (sc {3:N3})" -f $pose, ($bb.X1 - $bb.X0), ($bb.Y1 - $bb.Y0), $sc)
        $src.Dispose()
    }
}
Write-Output '완료'
