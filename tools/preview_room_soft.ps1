# ============================================================
#  새 아트로 방을 한 장에 합쳐 봅니다 (게임에 들어가는 파일 아님)
# ------------------------------------------------------------
#     powershell -ExecutionPolicy Bypass -File tools\preview_room_soft.ps1
#  결과 -> tools/room_soft_preview.png
#
#  좌표는 전부 [b]2배[/b] 기준입니다 (방 1280x660).
#  캐릭터는 큰 캔버스에 그린 뒤 줄여서 붙입니다. 작게 그리면 디테일이
#  뭉개지지만, 크게 그려서 줄이면 안티에일리어싱이 살아납니다.
# ============================================================

$MengLibOnly = $true
. (Join-Path $PSScriptRoot 'concepts_soft.ps1')

$Root = Split-Path -Parent $PSScriptRoot
$PropDir = Join-Path $Root 'assets\sprites\props'

$A = $STYLES | Where-Object { $_.key -eq 'A' }

$W = 1280; $H = 660
$canvas = New-Object System.Drawing.Bitmap($W, $H, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

function Put([string]$name, [double]$x, [double]$y) {
    $b = [System.Drawing.Bitmap]::FromFile((Join-Path $PropDir ($name + '.png')))
    $g.DrawImage($b, [single]$x, [single]$y, [single]$b.Width, [single]$b.Height)
    $b.Dispose()
}
# 바닥에 서는 물건: x 는 가운데, y 는 발이 닿는 지점 (prop.gd 와 같은 규칙)
function Stand([string]$name, [double]$cx, [double]$footY, [int]$pad = 12) {
    $b = [System.Drawing.Bitmap]::FromFile((Join-Path $PropDir ($name + '.png')))
    $g.DrawImage($b, [single]($cx - $b.Width / 2.0), [single]($footY - ($b.Height - $pad)),
        [single]$b.Width, [single]$b.Height)
    $b.Dispose()
}

Put 'room_bg' 0 0

# ---------- 벽 ----------
# 빈 액자 5개 = 미니게임 5개 자리
Put 'frame_empty' 96 108
Put 'frame_empty' 228 158
Put 'frame_empty' 360 108
Put 'frame_empty' 700 100
Put 'frame_empty' 832 152
Stand 'window' 620 296 0
Put 'clock' 930 84
Stand 'door' 1146 316 0
Put 'shelf' 812 216

# ---------- 바닥에 놓인 것 ----------
Put 'rug' 430 404
Stand 'bed_base' 236 566
Put 'bed_quilt' 170 412
Stand 'wardrobe' 398 350
Stand 'desk' 960 500
Stand 'chair' 952 570
Stand 'plant' 1216 626
Stand 'toy' 88 604
Stand 'glove' 392 640

# 책상 위
Stand 'books' 906 370 0
Stand 'cup' 1016 368 0

# ---------- 캐릭터 ----------
# 큰 캔버스에 그린 뒤 줄여서 붙입니다.
function PutMeng([string]$who, [double]$cx, [double]$footY, [double]$targetH) {
    New-Soft 460 470
    Draw-Meng $A $who 230.0
    $img = Take-Soft
    # 원본에서 캐릭터는 대략 y 40~382 (높이 342), 가운데는 x 230
    $sc = $targetH / 342.0
    $g.DrawImage($img, [single]($cx - 230 * $sc), [single]($footY - 382 * $sc),
        [single](460 * $sc), [single](470 * $sc))
    $img.Dispose()
}
PutMeng 'dol' 636 610 172
PutMeng 'soon' 806 592 164

$g.Dispose()

# ★ 틸트시프트. 가운데 띠만 선명하고 위아래로 갈수록 흐려집니다.
#   젤다 꿈꾸는 섬의 "작은 디오라마" 느낌은 사실상 이 효과 하나가 만듭니다.
# 초점 띠는 캐릭터가 서 있는 높이를 통째로 품어야 합니다.
# 좁게 잡으면 주인공 발이 흐려져서 오히려 어색합니다.
$final = TiltShift $canvas 0.34 0.94 6.0
$canvas.Dispose()
$final.Save((Join-Path $PSScriptRoot 'room_soft_preview.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$final.Dispose()
Write-Output 'tools/room_soft_preview.png'
