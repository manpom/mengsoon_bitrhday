# ============================================================
#  이동 프레임(앞/뒤 × 서기/걷기)을 192x192 게임 프레임에 배치합니다.
# ------------------------------------------------------------
#     powershell -ExecutionPolicy Bypass -File tools\integrate_ai_moves.ps1
#
#  입력: tools/ai_refs/<who>/clean/{down_idle,down_walk,up_idle,up_walk}.png
#        (clean_ai_refs.ps1 이 마젠타 원본에서 키잉해 둔 것)
#  출력: assets/sprites/characters/<who>/<who>_{down,up}_{idle,walk1,walk2}.png
#
#  ★ 애니메이션이 튀지 않게 하는 규칙:
#    - 방향(앞/뒤)마다 idle 의 캐릭터 키로 scale 을 한 번 정하고
#      walk 에도 같은 scale 을 씁니다 (프레임마다 크기가 맥동하면 안 됨).
#    - idle·walk 모두 알파 bbox 의 바닥(딛는 발)을 FOOT_Y 에 맞춥니다.
#    - walk2 = walk1 을 좌우반전 (한 포즈만 생성했으므로 반대 보폭은 미러).
#      게임은 이동 방향에 따라 추가로 flip_h 하지만, 두 프레임이 미러라
#      L스텝→모음→R스텝→모음 사이클이 그대로 성립합니다.
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

# src 를 sc 배율로, (cx, bboxY1) 이 (96, FOOT_Y) 에 오도록 192 프레임에 그림.
# $mirror 면 최종 결과를 좌우반전.
function Place([System.Drawing.Bitmap]$src, [hashtable]$bb, [double]$sc, [string]$dstPath, [bool]$mirror) {
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
    if ($mirror) { $out.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX) }
    $out.Save($dstPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $out.Dispose()
}

Write-Output '이동 프레임 AI 레퍼런스 -> 게임 프레임 배치'
foreach ($who in 'mengdol', 'mengsoon') {
    Write-Output $who
    $dir = Join-Path $CharDir $who
    foreach ($face in 'down', 'up') {
        $idleSrcP = Join-Path $RefDir ("$who\clean\${face}_idle.png")
        $walkSrcP = Join-Path $RefDir ("$who\clean\${face}_walk.png")
        if (-not (Test-Path $idleSrcP) -or -not (Test-Path $walkSrcP)) {
            Write-Output "  (건너뜀 - clean 없음: ${face}_idle/${face}_walk)"
            continue
        }
        $idle = [System.Drawing.Bitmap]::FromFile($idleSrcP)
        $walk = [System.Drawing.Bitmap]::FromFile($walkSrcP)
        $bi = Get-Bbox $idle
        $bw = Get-Bbox $walk
        if ($null -eq $bi -or $null -eq $bw) { Write-Output "  !! 알파 없음: $face"; $idle.Dispose(); $walk.Dispose(); continue }

        # 방향 공통 배율 = idle 캐릭터 키 기준
        $charH = $bi.Y1 - $bi.Y0
        $sc = $TARGET_H / $charH

        Place $idle $bi $sc (Join-Path $dir "${who}_${face}_idle.png")  $false
        Place $walk $bw $sc (Join-Path $dir "${who}_${face}_walk1.png") $false
        Place $walk $bw $sc (Join-Path $dir "${who}_${face}_walk2.png") $true

        Write-Output ("  {0}: idle charH {1} -> sc {2:N3} | walk charW {3} charH {4}" -f $face, $charH, $sc, ($bw.X1 - $bw.X0), ($bw.Y1 - $bw.Y0))
        $idle.Dispose(); $walk.Dispose()
    }
}
Write-Output '완료'
