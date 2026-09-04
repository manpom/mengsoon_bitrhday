# ============================================================
#  AI 레퍼런스(tools/ai_refs) 얼굴 표정을 게임 프레임(192x192)에 맞춰
#  자르고 배치해서 assets/sprites/characters/ 에 반영합니다.
# ------------------------------------------------------------
#     powershell -ExecutionPolicy Bypass -File tools\integrate_ai_faces.ps1
#
#  ★ 왜 얼굴 표정만 먼저 바꾸나요?
#    idle/walk 프레임을 바꾸면 같은 걷기 동작 안에서 절차적 그림과 AI
#    그림이 섞여 보여서 어색합니다(예: idle 만 AI, walk1/walk2 는 그대로).
#    표정(face_*)은 다른 프레임과 섞이지 않고 [b]혼자[/b] 표시되므로
#    지금 바로 바꿔도 안전합니다. idle/walk/포즈는 나머지 세트가 다
#    갖춰진 뒤에 한 번에 바꿉니다.
#
#  ★ 배치 규칙은 절차적 파이프라인과 동일합니다: 192x192 캔버스,
#    캐릭터 키 176px, 발이 텍스처 아래에서 2px 위. AI 그림에서 알파
#    채널로 캐릭터 영역을 찾아 그 규칙에 맞게 자동으로 맞춥니다.
# ============================================================

Add-Type -AssemblyName System.Drawing

$Root = Split-Path -Parent $PSScriptRoot
$RefDir = Join-Path $Root 'tools\ai_refs'
$CharDir = Join-Path $Root 'assets\sprites\characters'

$FRAME = 192
$TARGET_H = 176.0
$FOOT_Y = 190.0

function Get-AlphaBBox([System.Drawing.Bitmap]$bmp) {
    $w = $bmp.Width; $h = $bmp.Height
    $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
    $data = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $stride = $data.Stride
    $bytes = New-Object byte[] ($stride * $h)
    [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $bytes.Length)
    $bmp.UnlockBits($data)

    # 4픽셀 격자로 다운샘플한 뒤, 연결된 덩어리(캐릭터 본체) 중 가장 큰 것만
    # 골라서 경계를 잡습니다. AI 배경 제거가 남긴 작은 반짝이/얼룩(별개의
    # 작은 opaque 덩어리)이 경계상자를 엉뚱하게 늘리는 걸 막기 위함입니다.
    $STEP = 2
    $gw = [int]([math]::Ceiling($w / [double]$STEP))
    $gh = [int]([math]::Ceiling($h / [double]$STEP))
    $grid = New-Object bool[] ($gw * $gh)
    for ($gy = 0; $gy -lt $gh; $gy++) {
        $y = $gy * $STEP
        if ($y -ge $h) { continue }
        $row = $y * $stride
        for ($gx = 0; $gx -lt $gw; $gx++) {
            $x = $gx * $STEP
            if ($x -ge $w) { continue }
            # clean_ai_refs.ps1 이 이미 배경을 하드컷 + 최대덩어리만 남겨두므로
            # 문턱을 낮게(>16) 잡아야 페더링된 실루엣 가장자리까지 한 덩어리로 이어집니다.
            if ($bytes[$row + $x * 4 + 3] -gt 16) { $grid[$gy * $gw + $gx] = $true }
        }
    }

    $visited = New-Object bool[] ($gw * $gh)
    $label = New-Object int[] ($gw * $gh)   # 0 = 미지정, 그 외 = 덩어리 번호(1부터)
    $bestSize = 0
    $bestLabel = -1
    $bestMinX = -1; $bestMaxX = -1; $bestMinY = -1; $bestMaxY = -1
    $stackX = New-Object int[] ($gw * $gh)
    $stackY = New-Object int[] ($gw * $gh)
    $curLabel = 0
    for ($gy0 = 0; $gy0 -lt $gh; $gy0++) {
        for ($gx0 = 0; $gx0 -lt $gw; $gx0++) {
            $idx0 = $gy0 * $gw + $gx0
            if (-not $grid[$idx0] -or $visited[$idx0]) { continue }
            $curLabel++
            $sp = 0
            $stackX[$sp] = $gx0; $stackY[$sp] = $gy0; $sp++
            $visited[$idx0] = $true
            $label[$idx0] = $curLabel
            $size = 0
            $mnX = $gx0; $mxX = $gx0; $mnY = $gy0; $mxY = $gy0
            while ($sp -gt 0) {
                $sp--
                $cx = $stackX[$sp]; $cy = $stackY[$sp]
                $size++
                if ($cx -lt $mnX) { $mnX = $cx }
                if ($cx -gt $mxX) { $mxX = $cx }
                if ($cy -lt $mnY) { $mnY = $cy }
                if ($cy -gt $mxY) { $mxY = $cy }
                foreach ($d in @(@(1,0),@(-1,0),@(0,1),@(0,-1),@(1,1),@(1,-1),@(-1,1),@(-1,-1))) {
                    $nx = $cx + $d[0]; $ny = $cy + $d[1]
                    if ($nx -lt 0 -or $nx -ge $gw -or $ny -lt 0 -or $ny -ge $gh) { continue }
                    $nidx = $ny * $gw + $nx
                    if ($grid[$nidx] -and -not $visited[$nidx]) {
                        $visited[$nidx] = $true
                        $label[$nidx] = $curLabel
                        $stackX[$sp] = $nx; $stackY[$sp] = $ny; $sp++
                    }
                }
            }
            if ($size -gt $bestSize) {
                $bestSize = $size
                $bestLabel = $curLabel
                $bestMinX = $mnX; $bestMaxX = $mxX; $bestMinY = $mnY; $bestMaxY = $mxY
            }
        }
    }
    if ($bestSize -le 0) { return $null }
    $PAD = 6
    $minX = [math]::Max(0, $bestMinX * $STEP - $PAD)
    $maxX = [math]::Min($w - 1, $bestMaxX * $STEP + $PAD)
    $minY = [math]::Max(0, $bestMinY * $STEP - $PAD)
    $maxY = [math]::Min($h - 1, $bestMaxY * $STEP + $PAD)
    return @{ X0 = $minX; Y0 = $minY; X1 = $maxX; Y1 = $maxY; Label = $label; BestLabel = $bestLabel; GW = $gw; GH = $gh; Step = $STEP }
}

function Place-Frame([string]$srcPath, [string]$dstPath, [int]$CropX0 = -1, [int]$CropX1 = -1) {
    $raw = [System.Drawing.Bitmap]::FromFile($srcPath)
    if ($CropX0 -ge 0) {
        # 소스 한 장에 캐릭터가 두 마리(패널 2개) 들어있는 경우 한쪽만 잘라 씁니다.
        $cw = $CropX1 - $CropX0
        $src = New-Object System.Drawing.Bitmap($cw, $raw.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $cg = [System.Drawing.Graphics]::FromImage($src)
        $cg.DrawImage($raw, (New-Object System.Drawing.Rectangle(0, 0, $cw, $raw.Height)), $CropX0, 0, $cw, $raw.Height, [System.Drawing.GraphicsUnit]::Pixel)
        $cg.Dispose()
        $raw.Dispose()
    }
    else {
        $src = $raw
    }
    $bbox = Get-AlphaBBox $src
    if ($null -eq $bbox) {
        Write-Output "  !! 알파 영역을 못 찾음: $srcPath"
        $src.Dispose()
        return
    }
    $charH = $bbox.Y1 - $bbox.Y0
    $charW = $bbox.X1 - $bbox.X0
    $cx = ($bbox.X0 + $bbox.X1) / 2.0

    # 소스마다 해상도가 다르므로(제미니 ~1400px, GPT ~1700px) 절대 픽셀이 아니라
    # 캔버스 대비 비율로 검사합니다. 캐릭터 덩어리가 캔버스를 거의 꽉 채우면
    # (가로·세로 둘 다) 배경이 안 지워진 것이고, 어느 한 축이라도 15% 미만이면
    # 옷이 잘려나간 것이라 절차적 그림을 그대로 두고 건너뜁니다.
    $wr = $charW / [double]$src.Width
    $hr = $charH / [double]$src.Height
    if (($wr -gt 0.97 -and $hr -gt 0.97) -or $wr -lt 0.15 -or $hr -lt 0.15) {
        Write-Output ("  !! 크기 이상해서 건너뜀 (가로 {0:P0} 세로 {1:P0}): {2}" -f $wr, $hr, $srcPath)
        $src.Dispose()
        return
    }

    # 캐릭터 몸통(가장 큰 덩어리)에 안 속하는 픽셀은 전부 투명하게 지웁니다
    # (톨러런스를 낮게 잡아 옷을 안 먹게 하다 보니 배경이 덜 지워진 얼룩/
    # 반짝이가 남을 수 있는데, 이 덩어리 밖은 캐릭터가 아니란 게 확실하므로).
    # 격자 라벨을 1칸 팽창시켜서 안티에일리어싱된 가장자리는 보존합니다.
    $gw = $bbox.GW; $gh = $bbox.GH; $gstep = $bbox.Step; $lbl = $bbox.Label; $bl = $bbox.BestLabel
    $keep = New-Object bool[] ($gw * $gh)
    for ($gy = 0; $gy -lt $gh; $gy++) {
        for ($gx = 0; $gx -lt $gw; $gx++) {
            if ($lbl[$gy * $gw + $gx] -ne $bl) { continue }
            for ($dy = -1; $dy -le 1; $dy++) {
                for ($dx = -1; $dx -le 1; $dx++) {
                    $nx = $gx + $dx; $ny = $gy + $dy
                    if ($nx -lt 0 -or $nx -ge $gw -or $ny -lt 0 -or $ny -ge $gh) { continue }
                    $keep[$ny * $gw + $nx] = $true
                }
            }
        }
    }
    $srect = New-Object System.Drawing.Rectangle(0, 0, $src.Width, $src.Height)
    $sdata = $src.LockBits($srect, [System.Drawing.Imaging.ImageLockMode]::ReadWrite, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $sstride = $sdata.Stride
    $sbytes = New-Object byte[] ($sstride * $src.Height)
    [System.Runtime.InteropServices.Marshal]::Copy($sdata.Scan0, $sbytes, 0, $sbytes.Length)
    for ($yy = 0; $yy -lt $src.Height; $yy++) {
        $gy = [int]($yy / $gstep)
        if ($gy -ge $gh) { $gy = $gh - 1 }
        $rowOff = $yy * $sstride
        for ($xx = 0; $xx -lt $src.Width; $xx++) {
            $gx = [int]($xx / $gstep)
            if ($gx -ge $gw) { $gx = $gw - 1 }
            if (-not $keep[$gy * $gw + $gx]) { $sbytes[$rowOff + $xx * 4 + 3] = 0 }
        }
    }
    [System.Runtime.InteropServices.Marshal]::Copy($sbytes, 0, $sdata.Scan0, $sbytes.Length)
    $src.UnlockBits($sdata)

    $sc = $TARGET_H / $charH

    $out = New-Object System.Drawing.Bitmap($FRAME, $FRAME, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($out)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    $dw = $src.Width * $sc
    $dh = $src.Height * $sc
    # 원본의 (cx, bbox.Y1) 이 프레임의 (96, FOOT_Y) 에 오도록
    $dx = ($FRAME / 2.0) - $cx * $sc
    $dy = $FOOT_Y - $bbox.Y1 * $sc

    $g.DrawImage($src, [single]$dx, [single]$dy, [single]$dw, [single]$dh)
    $g.Dispose()
    $src.Dispose()

    $out.Save($dstPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $out.Dispose()
    Write-Output ("  {0,-40} char {1}x{2} -> scale {3:N2}" -f (Split-Path -Leaf $dstPath), $charW, $charH, $sc)
}

# 예전 제미니 소스 중엔 캐릭터 2마리가 한 캔버스에 나온 게 있어서 왼쪽 절반만
# 쓰던 표(`$TwoPanel`)가 있었는데, 지금은 14장 전부 GPT 단일 패널(clean_ai_refs.ps1
# 로 마젠타 키잉)이라 크롭이 필요 없습니다. 다시 2패널 소스를 쓰면 'who/face_expr'
# 키를 추가하고 Place-Frame 에 0 704 처럼 크롭 범위를 넘기세요.
$TwoPanel = @{ }
# 배경이 안 깨끗한 소스를 이번 통합에서 건너뛰고 싶으면 'who/face_expr' 키를 넣으세요.
$Skip = @{ }

Write-Output '얼굴 표정 AI 레퍼런스 -> 게임 프레임 배치'
foreach ($who in 'mengdol', 'mengsoon') {
    Write-Output $who
    $dir = Join-Path $CharDir $who
    foreach ($expr in 'happy', 'surprise', 'sad', 'angry', 'sleepy', 'shy', 'laugh') {
        $key = "$who/face_$expr"
        if ($Skip.ContainsKey($key)) {
            Write-Output "  (건너뜀 - 배경 정리 안됨: $expr)"
            continue
        }
        $srcName = "face_$expr.png"
        $src = Join-Path (Join-Path (Join-Path $RefDir $who) 'clean') $srcName
        if (-not (Test-Path $src)) {
            Write-Output "  (건너뜀 - 없음: $srcName)"
            continue
        }
        $dst = Join-Path $dir ("${who}_face_$expr.png")
        if ($TwoPanel.ContainsKey($key)) {
            Place-Frame $src $dst 0 704
        }
        else {
            Place-Frame $src $dst
        }
    }
}
Write-Output '완료'
