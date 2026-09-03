# ============================================================
#  캐릭터 프레임 굽기 (A안 · 디오라마 스타일)
# ------------------------------------------------------------
#     powershell -ExecutionPolicy Bypass -File tools\build_char_soft.ps1
#  결과 -> assets/sprites/characters/mengdol/ · mengsoon/   (한 명당 25장)
#          tools/char_soft_preview.png  (전부 한 장에)
#
#  ★ 프레임은 192x192, 발이 텍스처 맨 아래에서 2px 위입니다.
#    Godot 에서 offset (0,-96) 을 주면 [b]노드 위치가 곧 발밑[/b]이 됩니다.
#    예전 도트(64x64, offset -32)와 같은 규칙을 2배로 옮긴 것입니다.
#
#  ★ 크게 그린 뒤 줄입니다. 460x470 에 그려서 192 로 축소하면
#    안티에일리어싱이 살아나 가장자리가 매끈해집니다. 작게 그리면 뭉갭니다.
# ============================================================

. (Join-Path $PSScriptRoot '_meng_soft.ps1')

$Root = Split-Path -Parent $PSScriptRoot
$OutRoot = Join-Path $Root 'assets\sprites\characters'

$FRAME = 192
$SRC_W = 460; $SRC_H = 470
$SRC_FOOT_Y = 382.0     # 원본에서 발이 닿는 y
$SRC_CX = 230.0
$TARGET_H = 176.0       # 프레임 안에서 캐릭터 키
$SRC_H_CHAR = 342.0     # 원본에서 캐릭터 키

# 굽을 프레임 목록
$JOBS = @(
    @{ n = 'down_idle'; dir = 'down'; step = 0 }
    @{ n = 'down_walk1'; dir = 'down'; step = 1 }
    @{ n = 'down_walk2'; dir = 'down'; step = -1 }
    @{ n = 'up_idle'; dir = 'up'; step = 0 }
    @{ n = 'up_walk1'; dir = 'up'; step = 1 }
    @{ n = 'up_walk2'; dir = 'up'; step = -1 }

    @{ n = 'face_happy'; face = 'happy' }
    @{ n = 'face_surprise'; face = 'surprise' }
    @{ n = 'face_sad'; face = 'sad' }
    @{ n = 'face_angry'; face = 'angry' }
    @{ n = 'face_sleepy'; face = 'sleepy' }
    @{ n = 'face_shy'; face = 'shy' }
    @{ n = 'face_laugh'; face = 'laugh' }

    # 침대에 누운 그림.
    # ★ 서 있는 그림을 통째로 90도 돌리면 그대로 누운 그림이 됩니다.
    #   등을 대고 누우면 정수리가 왼쪽(머리맡), 발이 오른쪽(발치)을 향하고
    #   얼굴은 천장 = 우리 쪽을 봅니다. 따로 그릴 필요가 없습니다.
    @{ n = 'lie'; face = 'sleepy'; rot = $true }

    # 욕실 컷신 (옷 없음)
    @{ n = 'nude_stand'; nude = $true }
    @{ n = 'nude_guard'; nude = $true; pose = 'guard' }
    @{ n = 'nude_punch1'; nude = $true; pose = 'punch1' }
    @{ n = 'nude_punch2'; nude = $true; pose = 'punch2' }
    @{ n = 'nude_surprise'; nude = $true; face = 'surprise' }
    @{ n = 'nude_shy'; nude = $true; face = 'shy' }
    @{ n = 'nude_laugh'; nude = $true; pose = 'laugh'; face = 'laugh' }

    # 리듬 파트 - 맹돌이는 내내 눈물 흘리며 웃습니다
    @{ n = 'nude_lol'; nude = $true; face = 'laugh' }
    @{ n = 'nude_lol_punch1'; nude = $true; pose = 'punch1'; face = 'laugh' }
    @{ n = 'nude_lol_punch2'; nude = $true; pose = 'punch2'; face = 'laugh' }
    @{ n = 'nude_lol_fart'; nude = $true; pose = 'fart'; face = 'laugh' }
)

# ============================================================
#  한 장 굽기
# ============================================================
function Bake([string]$who, [hashtable]$j, [string]$path) {
    $o = @{ who = $who }
    foreach ($k in 'dir', 'step', 'face', 'pose', 'nude') {
        if ($j.ContainsKey($k)) { $o[$k] = $j[$k] }
    }

    New-Soft $SRC_W $SRC_H
    Draw-Char $o $SRC_CX
    $big = Take-Soft

    $sc = $TARGET_H / $SRC_H_CHAR
    $out = New-Object System.Drawing.Bitmap($FRAME, $FRAME,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($out)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    # 원본의 발(230, 382) 이 프레임의 (96, 190) 에 오도록
    $dx = ($FRAME / 2.0) - $SRC_CX * $sc
    $dy = ($FRAME - 2.0) - $SRC_FOOT_Y * $sc
    $g.DrawImage($big, [single]$dx, [single]$dy, [single]($SRC_W * $sc), [single]($SRC_H * $sc))
    $g.Dispose(); $big.Dispose()
    if ($j.ContainsKey('rot') -and $j.rot) {
        $out.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone)
    }
    $out.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    return $out
}

# ============================================================
$sheet = @{}
foreach ($who in 'mengdol', 'mengsoon') {
    $dir = Join-Path $OutRoot $who
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    Write-Output $who
    foreach ($j in $JOBS) {
        $name = "${who}_$($j.n)"
        $p = Join-Path $dir ($name + '.png')
        $sheet[$name] = Bake $who $j $p
    }
    Write-Output ("  {0}장" -f $JOBS.Count)
}

# ---------- 미리보기 시트 ----------
$cols = 10
$cell = $FRAME + 8
$rows = [math]::Ceiling($sheet.Count / $cols)
$pv = New-Object System.Drawing.Bitmap(($cols * $cell + 8), ($rows * $cell + 8),
    [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g2 = [System.Drawing.Graphics]::FromImage($pv)
$g2.Clear((C '#EFE2CE'))
$i = 0
foreach ($k in ($sheet.Keys | Sort-Object)) {
    $x = 8 + ($i % $cols) * $cell
    $y = 8 + [math]::Floor($i / $cols) * $cell
    $g2.DrawImage($sheet[$k], $x, $y, $FRAME, $FRAME)
    $i++
}
$g2.Dispose()
foreach ($b in $sheet.Values) { $b.Dispose() }
$pv.Save((Join-Path $PSScriptRoot 'char_soft_preview.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$pv.Dispose()
Write-Output 'tools/char_soft_preview.png'
