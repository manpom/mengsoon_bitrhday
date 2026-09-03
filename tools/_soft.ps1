# ============================================================
#  부드러운 2D 일러스트용 그리기 도구 (도트용 _draw.ps1 의 대체)
# ------------------------------------------------------------
#  도트 파이프라인(_draw.ps1 / _pixlib.ps1)은 안티에일리어싱을 [b]끄고[/b]
#  사각형과 계단식 타원만 찍었습니다. 여기서는 정반대로 갑니다.
#
#    - 안티에일리어싱 켬 (부드러운 곡선)
#    - AddClosedCurve 로 몇 개의 점을 지나는 [b]몽글몽글한 곡선[/b] 생성
#    - 그라디언트로 은은한 명암 (단색 두 개로 나누지 않음)
#    - 그림자는 알파가 서서히 빠지는 방사형 그라디언트
#    - 외곽선은 검정이 아니라 [b]따뜻한 갈색[/b] (검정은 차갑고 싸구려로 보입니다)
#
#  쓰는 법:
#      . (Join-Path $PSScriptRoot '_soft.ps1')
#      New-Soft 400 400
#      $p = BlobPath @( (Pt 10 10), (Pt 90 20), ... )
#      FillPath $p '#A8D8A0'
#      Save-Soft 'out.png'
#
#  ASCII-only 주석이 아니어도 됩니다 - 이 파일에는 BOM 이 있습니다.
# ============================================================

Add-Type -AssemblyName System.Drawing

$script:SImg = $null
$script:SG = $null

function New-Soft([int]$w, [int]$h) {
    $script:SImg = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $script:SG = [System.Drawing.Graphics]::FromImage($script:SImg)
    $script:SG.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $script:SG.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $script:SG.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $script:SG.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $script:SG.Clear([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
}

# '#RRGGBB' 또는 '#RRGGBBAA'
function C([string]$hex) {
    $h = $hex.TrimStart('#')
    $r = [Convert]::ToInt32($h.Substring(0, 2), 16)
    $g = [Convert]::ToInt32($h.Substring(2, 2), 16)
    $b = [Convert]::ToInt32($h.Substring(4, 2), 16)
    $a = 255
    if ($h.Length -ge 8) { $a = [Convert]::ToInt32($h.Substring(6, 2), 16) }
    return [System.Drawing.Color]::FromArgb($a, $r, $g, $b)
}
# 같은 색을 알파만 바꿔서
function CA([string]$hex, [double]$alpha) {
    $c = C $hex
    return [System.Drawing.Color]::FromArgb([int](255 * $alpha), $c.R, $c.G, $c.B)
}
function Pt([double]$x, [double]$y) { return (New-Object System.Drawing.PointF([float]$x, [float]$y)) }

# ---------- 모양 만들기 ----------

# 점들을 부드럽게 지나는 닫힌 곡선. 이게 이 스타일의 핵심입니다.
# $tension 0.3~0.7 정도가 몽글몽글합니다. 1.0 을 넘으면 출렁거립니다.
function BlobPath($pts, [double]$tension = 0.5) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $p.AddClosedCurve([System.Drawing.PointF[]]$pts, [single]$tension)
    return $p
}
function EllipsePath([double]$cx, [double]$cy, [double]$rx, [double]$ry) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $p.AddEllipse([single]($cx - $rx), [single]($cy - $ry), [single]($rx * 2), [single]($ry * 2))
    return $p
}
function RoundRectPath([double]$x, [double]$y, [double]$w, [double]$h, [double]$r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    # 반지름이 0 이거나 변보다 크면 AddArc 가 "Parameter is not valid" 로 죽습니다.
    $r = [math]::Min($r, [math]::Min($w, $h) / 2.0)
    if ($r -le 0.5) {
        $p.AddRectangle((New-Object System.Drawing.RectangleF([single]$x, [single]$y, [single]$w, [single]$h)))
        return $p
    }
    $d = [single]($r * 2)
    $p.AddArc([single]$x, [single]$y, $d, $d, 180, 90)
    $p.AddArc([single]($x + $w - $r * 2), [single]$y, $d, $d, 270, 90)
    $p.AddArc([single]($x + $w - $r * 2), [single]($y + $h - $r * 2), $d, $d, 0, 90)
    $p.AddArc([single]$x, [single]($y + $h - $r * 2), $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}
# 열린 곡선 (입, 눈꺼풀 같은 선)
function CurveStroke($pts, [string]$hex, [double]$width, [double]$tension = 0.5) {
    $pen = New-Object System.Drawing.Pen((C $hex), [single]$width)
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    $script:SG.DrawCurve($pen, [System.Drawing.PointF[]]$pts, [single]$tension)
    $pen.Dispose()
}

# ---------- 칠하기 ----------

function FillPath($path, [string]$hex) {
    $br = New-Object System.Drawing.SolidBrush (C $hex)
    $script:SG.FillPath($br, $path)
    $br.Dispose()
}
function StrokePath($path, [string]$hex, [double]$width) {
    if ($width -le 0) { return }
    $pen = New-Object System.Drawing.Pen((C $hex), [single]$width)
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    $script:SG.DrawPath($pen, $path)
    $pen.Dispose()
}

# 모양 안쪽 음영.
#
# ★ 참고한 게임들(젤다 꿈꾸는 섬 / 알바 / 스미코구라시 / 츔츔)의 공통점은
#   "광택"이 아니라 "장난감"입니다. 넷 다 반짝이는 하이라이트가 없고,
#   대신 [b]위에서 오는 넓고 부드러운 확산광[/b]과 [b]바닥에 닿는 자리의
#   짙은 그늘[/b]로만 형태를 만듭니다. 그래야 플라스틱 피규어나 봉제 인형처럼
#   "집어 들 수 있는 물건"으로 보입니다.
#
#   그래서 이 함수는 방사형 광택 대신
#     1) 위쪽에 크고 흐린 빛 웅덩이
#     2) 아래쪽에 크고 흐린 접지 그늘
#   두 장을 겹칩니다. 밑칠(FillPath)은 호출하는 쪽에서 먼저 합니다.
function ShadeIn($path, [string]$lit, [string]$shade, [double]$atx, [double]$aty) {
    $b = $path.GetBounds()
    PushClip $path
    GroundShadow $atx $aty ($b.Width * 0.74) ($b.Height * 0.62) $lit 0.80
    GroundShadow ($b.X + $b.Width * 0.52) ($b.Y + $b.Height * 1.06) ($b.Width * 0.88) ($b.Height * 0.55) $shade 0.88
    PopClip
}

# ---------- 블러 · 틸트시프트 ----------

# 값싼 블러: 작게 줄였다가 다시 키웁니다. System.Drawing 에 가우시안이 없어서
# 이 방법을 쓰는데, 부드러운 그림에서는 차이가 거의 안 보입니다.
function BlurCopy([System.Drawing.Bitmap]$src, [double]$amount) {
    $w = $src.Width; $h = $src.Height
    $sw = [math]::Max(2, [int]($w / $amount)); $sh = [math]::Max(2, [int]($h / $amount))
    $small = New-Object System.Drawing.Bitmap($sw, $sh, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g1 = [System.Drawing.Graphics]::FromImage($small)
    $g1.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g1.DrawImage($src, 0, 0, $sw, $sh); $g1.Dispose()
    $big = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g2 = [System.Drawing.Graphics]::FromImage($big)
    $g2.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g2.DrawImage($small, 0, 0, $w, $h); $g2.Dispose()
    $small.Dispose()
    return $big
}

# 틸트시프트. 가운데 띠만 선명하고 위아래로 갈수록 흐려집니다.
#
# ★ 젤다 꿈꾸는 섬의 "작은 디오라마" 느낌은 사실상 이 효과 하나가 만듭니다.
#   실제 카메라로 미니어처를 찍으면 심도가 얕아서 위아래가 흐려지는데,
#   그 신호를 그림에 넣으면 뇌가 "작은 모형"으로 읽습니다.
#
#   그라디언트 알파 합성이 System.Drawing 에 없어서, 블러본을 가로 띠로
#   잘라 띠마다 알파를 달리해 덮는 방식으로 흉내 냅니다.
function TiltShift([System.Drawing.Bitmap]$src, [double]$f0, [double]$f1, [double]$amount, [int]$bands = 40) {
    $w = $src.Width; $h = $src.Height
    $blur = BlurCopy $src $amount
    $out = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($out)
    $g.DrawImage($src, 0, 0, $w, $h)
    $bh = [double]$h / $bands
    for ($i = 0; $i -lt $bands; $i++) {
        $y0 = $i * $bh
        $c = ($y0 + $bh / 2.0) / $h
        $a = 0.0
        if ($c -lt $f0) { $a = (($f0 - $c) / $f0) }
        elseif ($c -gt $f1) { $a = (($c - $f1) / (1.0 - $f1)) }
        if ($a -le 0.01) { continue }
        $a = [math]::Min(1.0, $a * 1.25)
        $m = New-Object System.Drawing.Imaging.ColorMatrix
        $m.Matrix33 = [single]$a
        $ia = New-Object System.Drawing.Imaging.ImageAttributes
        $ia.SetColorMatrix($m)
        # 인자 안에서 계산하면 PowerShell 이 "+ 1" 을 다음 인자로 읽습니다.
        # 미리 변수에 담아 두어야 오버로드를 찾습니다.
        $yi = [int]$y0
        $hi = [int][math]::Ceiling($bh) + 1
        if ($yi + $hi -gt $h) { $hi = $h - $yi }
        if ($hi -le 0) { $ia.Dispose(); continue }
        $rect = New-Object System.Drawing.Rectangle -ArgumentList 0, $yi, $w, $hi
        $g.DrawImage($blur, $rect, 0, $yi, $w, $hi, [System.Drawing.GraphicsUnit]::Pixel, $ia)
        $ia.Dispose()
    }
    $g.Dispose(); $blur.Dispose()
    return $out
}
# 위에서 아래로 흐르는 그라디언트
function GradIn($path, [string]$top, [string]$bottom, [double]$y0, [double]$y1) {
    $br = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (Pt 0 $y0), (Pt 0 $y1), (C $top), (C $bottom))
    $old = $script:SG.Clip
    $script:SG.SetClip($path)
    $script:SG.FillRectangle($br, 0, [single]($y0 - 2), [single]$script:SImg.Width, [single]($y1 - $y0 + 4))
    $script:SG.Clip = $old
    $br.Dispose()
}

# 어떤 모양 안쪽에만 다른 것을 그리고 싶을 때
function PushClip($path) { $script:SG.SetClip($path) }
function PopClip { $script:SG.ResetClip() }

# ---------- 그림자 ----------

# 바닥 그림자. 가운데가 진하고 가장자리로 갈수록 투명해집니다.
function GroundShadow([double]$cx, [double]$cy, [double]$rx, [double]$ry, [string]$hex, [double]$alpha = 0.28) {
    $p = EllipsePath $cx $cy $rx $ry
    $br = New-Object System.Drawing.Drawing2D.PathGradientBrush($p)
    $br.CenterPoint = (Pt $cx $cy)
    $br.CenterColor = (CA $hex $alpha)
    $br.SurroundColors = @((CA $hex 0.0))
    $script:SG.FillPath($br, $p)
    $br.Dispose(); $p.Dispose()
}

# 모양을 아래로 조금 밀어서 부드럽게 깔아 주는 그림자.
# 여러 겹을 조금씩 키우면서 겹치면 흐릿한 가장자리가 됩니다.
function DropShadow($path, [double]$dx, [double]$dy, [string]$hex, [double]$alpha = 0.18, [int]$layers = 5) {
    for ($i = $layers; $i -ge 1; $i--) {
        $m = New-Object System.Drawing.Drawing2D.Matrix
        $s = 1.0 + $i * 0.012
        $b = $path.GetBounds()
        $cx = $b.X + $b.Width / 2; $cy = $b.Y + $b.Height / 2
        $m.Translate([single]($cx + $dx), [single]($cy + $dy))
        $m.Scale([single]$s, [single]$s)
        $m.Translate([single](-$cx), [single](-$cy))
        $c = $path.Clone()
        $c.Transform($m)
        $br = New-Object System.Drawing.SolidBrush (CA $hex ($alpha / $layers))
        $script:SG.FillPath($br, $c)
        $br.Dispose(); $c.Dispose(); $m.Dispose()
    }
}

# ---------- 손그림 질감 (D안 전용) ----------
#
# A/B/C 는 전부 "깔끔한 벡터"라 결이 비슷합니다. D 안은 아예 다른 결로 갑니다:
# 선이 미세하게 흔들리고, 색이 종이에 번진 것처럼 고이고, 전체에 종이 결이 깔립니다.
#
# 무작위는 전부 [b]고정 시드[/b]입니다. 다시 실행해도 똑같은 그림이 나와야
# 하기 때문입니다 (매번 달라지면 그림 비교를 할 수가 없습니다).

$script:HSeed = 20261020
function HRand {
    $script:HSeed = ($script:HSeed * 1103515245 + 12345) % 2147483648
    return ($script:HSeed / 2147483648.0)
}
function HReset([int]$seed) { $script:HSeed = $seed }

# 점들을 조금씩 흔듭니다. 손으로 그린 선은 절대 자로 잰 듯 곧지 않습니다.
function JitterPts($pts, [double]$amt) {
    $out = @()
    foreach ($p in $pts) {
        $out += (Pt ($p.X + ((HRand) - 0.5) * 2 * $amt) ($p.Y + ((HRand) - 0.5) * 2 * $amt))
    }
    return $out
}

# 연필/크레용 선. 살짝 다르게 흔든 선을 여러 번 겹쳐 그으면
# 한 번에 그은 선보다 훨씬 손맛이 납니다.
function SketchClosed($pts, [string]$hex, [double]$width, [double]$tension, [double]$amt, [int]$passes = 3) {
    for ($i = 0; $i -lt $passes; $i++) {
        $j = JitterPts $pts $amt
        $p = BlobPath $j $tension
        $pen = New-Object System.Drawing.Pen((CA $hex (0.55 - $i * 0.12)), [single]($width * (1.0 - $i * 0.15)))
        $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
        $script:SG.DrawPath($pen, $p)
        $pen.Dispose(); $p.Dispose()
    }
}
function SketchOpen($pts, [string]$hex, [double]$width, [double]$tension, [double]$amt, [int]$passes = 3) {
    for ($i = 0; $i -lt $passes; $i++) {
        $j = JitterPts $pts $amt
        $pen = New-Object System.Drawing.Pen((CA $hex (0.60 - $i * 0.13)), [single]($width * (1.0 - $i * 0.15)))
        $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
        $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
        $script:SG.DrawCurve($pen, [System.Drawing.PointF[]]$j, [single]$tension)
        $pen.Dispose()
    }
}

# 수채화처럼 색이 고인 자국. 모양 안쪽에만 흐릿한 얼룩 몇 개를 겹칩니다.
# 가장자리에 색이 진하게 남는 것(edge darkening)이 수채화의 특징이라
# 안쪽 테두리를 넓고 옅게 한 번 더 두릅니다.
function WaterFill($path, [string]$base, [string]$pool, [int]$blots = 6) {
    FillPath $path $base
    PushClip $path
    $b = $path.GetBounds()
    for ($i = 0; $i -lt $blots; $i++) {
        $bx = $b.X + (HRand) * $b.Width
        $by = $b.Y + (HRand) * $b.Height
        $br = ($b.Width + $b.Height) * (0.14 + (HRand) * 0.22)
        GroundShadow $bx $by $br ($br * 0.85) $pool (0.26 + (HRand) * 0.22)
    }
    # 가장자리에 색이 고인 자국
    $pen = New-Object System.Drawing.Pen((CA $pool 0.42), [single](($b.Width + $b.Height) * 0.055))
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    $script:SG.DrawPath($pen, $path)
    $pen.Dispose()
    PopClip
}

# 종이 결. 전체에 아주 옅은 점을 뿌립니다.
function PaperGrain([int]$count, [string]$hex, [double]$alpha) {
    $w = $script:SImg.Width; $h = $script:SImg.Height
    $br = New-Object System.Drawing.SolidBrush (CA $hex $alpha)
    for ($i = 0; $i -lt $count; $i++) {
        $x = (HRand) * $w; $y = (HRand) * $h
        $s = 1 + [int]((HRand) * 2)
        $script:SG.FillRectangle($br, [single]$x, [single]$y, [single]$s, [single]$s)
    }
    $br.Dispose()
}

# ---------- 저장 ----------

function Save-Soft([string]$path) {
    $script:SG.Dispose()
    $script:SImg.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Output ("  {0,-28} {1}x{2}" -f (Split-Path -Leaf $path), $script:SImg.Width, $script:SImg.Height)
    $script:SImg.Dispose()
    $script:SImg = $null; $script:SG = $null
}

# 저장하지 않고 지금 캔버스를 그대로 넘겨받습니다 (합성용).
function Take-Soft {
    $script:SG.Dispose()
    $img = $script:SImg
    $script:SImg = $null; $script:SG = $null
    return $img
}

# 윗면 빛만 얹고 아래 그늘은 넣지 않습니다.
#
# ★ 얼굴에 ShadeIn 을 쓰면 안 됩니다. 아래쪽 그림자 웅덩이가 볼과 턱에
#   걸려서 "때가 탄 자국"처럼 보입니다. 얼굴은 빛만 받고 그늘은
#   턱 밑 접지선 하나로 충분합니다.
function ShadeTopOnly($path, [string]$lit, [double]$atx, [double]$aty) {
    $b = $path.GetBounds()
    PushClip $path
    GroundShadow $atx $aty ($b.Width * 0.80) ($b.Height * 0.68) $lit 0.70
    PopClip
}
