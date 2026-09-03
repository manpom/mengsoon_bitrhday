# ============================================================
#  Mengdol house - room background + furniture generator
# ------------------------------------------------------------
#  Everything in this room is drawn out of axis-aligned
#  rectangles and aliased ellipses, so the output stays crisp
#  pixel art with no anti-aliased edges.
#
#  Run (from the project folder):
#     powershell -ExecutionPolicy Bypass -File tools\build_room.ps1
#
#  Output:
#     assets/sprites/props/*.png
#     assets/sprites/ui/prompt.png
#     tools/room_preview.png   (2x, for eyeballing only)
#
#  ASCII-only comments on purpose: PS 5.1 reads BOM-less UTF-8
#  as ANSI and a mis-decoded byte can swallow the next line.
# ============================================================

Add-Type -AssemblyName System.Drawing

$Root    = Split-Path -Parent $PSScriptRoot
$PropDir = Join-Path $Root 'assets\sprites\props'
$UiDir   = Join-Path $Root 'assets\sprites\ui'
foreach ($d in @($PropDir, $UiDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
}

# ---------- palette (RRGGBB or RRGGBBAA) ----------
$OUT     = '2A1B14'   # near-black brown outline
$WD_D    = '4A3323'   # wood, dark
$WD_M    = '6B4A31'   # wood, mid
$WD_L    = '85603F'   # wood, light
$WD_H    = '9C7550'   # wood, highlight
$SIDE    = '3B2819'   # side walls (in shadow)
$TRIM    = '553A26'   # baseboard
$FL_A    = 'A8804F'   # floorboard A
$FL_B    = '9C7548'   # floorboard B
$FL_LN   = '7A5636'   # floorboard seam
$FL_SH   = '8A6640'   # floor shadow next to the wall
$CREAM   = 'F6EBD0'
$CREAM_D = 'D9C7A2'
$WHITE   = 'FFFDF4'
$SAGE    = '7FA96A'
$SAGE_D  = '5C8450'
$SAGE_L  = '9CC287'
$SAGE_O  = '35502C'
$SKY_1   = '2E3A5C'   # dawn sky, top
$SKY_2   = '5B5680'
$SKY_3   = 'C98F7E'
$SKY_4   = 'F0C08A'   # dawn sky, horizon
$METAL   = 'C9B489'
$PAPER   = 'F2E9D2'
$INK     = '3E4E80'
$RUG_O   = '43536A'
$RUG_M   = '5C6E86'
$RUG_L   = '75879C'
$DUSK    = '5A4A55'   # empty picture frame interior

# ---------- drawing helpers (tools/_draw.ps1 에 공용으로 들어 있습니다) ----------
. (Join-Path $PSScriptRoot '_draw.ps1')

Write-Output 'assets/sprites/props/'

# ============================================================
#  room_bg.png - 640x360 wall + floor. Nothing here collides;
#  the walls you actually bump into live in the level scene.
# ============================================================
$RW = 640; $RH = 330; $WALL_H = 152; $SIDE_W = 24

Start-Img $RW $RH

# side walls first, the back wall is then painted on top of them
Fill 0 0 $RW $RH $SIDE
for ($x = 0; $x -lt $SIDE_W; $x += 8) {
    Fill $x 0 1 $RH $OUT
    Fill ($RW - 1 - $x) 0 1 $RH $OUT
}

# back wall: horizontal planks, 16px tall, alternating tone
$bandIdx = 0
for ($y = 0; $y -lt ($WALL_H - 10); $y += 16) {
    if ($bandIdx % 2 -eq 0) { $col = $WD_M } else { $col = $WD_L }
    Fill $SIDE_W $y ($RW - $SIDE_W * 2) 15 $col
    Fill $SIDE_W ($y + 15) ($RW - $SIDE_W * 2) 1 $WD_D
    $bandIdx++
}
# a few knots / nail heads so the planks are not perfectly flat
foreach ($k in @(@(96, 20), @(268, 52), @(430, 20), @(520, 100), @(160, 116), @(360, 84))) {
    Fill $k[0] $k[1] 2 2 $WD_D
    Fill ($k[0] + 2) ($k[1] + 1) 1 1 $WD_H
}

# baseboard
Fill $SIDE_W ($WALL_H - 10) ($RW - $SIDE_W * 2) 10 $TRIM
Fill $SIDE_W ($WALL_H - 10) ($RW - $SIDE_W * 2) 1 $WD_H
Fill $SIDE_W ($WALL_H - 1)  ($RW - $SIDE_W * 2) 1 $OUT

# floor: 14px boards, seams staggered row by row
$rowIdx = 0
for ($y = $WALL_H; $y -lt $RH; $y += 14) {
    if ($rowIdx % 2 -eq 0) { $col = $FL_A } else { $col = $FL_B }
    Fill $SIDE_W $y ($RW - $SIDE_W * 2) 13 $col
    Fill $SIDE_W ($y + 13) ($RW - $SIDE_W * 2) 1 $FL_LN
    # long boards: butt joints are rare and staggered, otherwise the
    # floor reads as brickwork instead of planks
    $off = @(0, 104, 56, 152, 24, 128)[$rowIdx % 6]
    for ($x = $SIDE_W + $off; $x -lt ($RW - $SIDE_W); $x += 208) {
        Fill $x $y 1 13 $FL_LN
    }
    $rowIdx++
}
# the floor picks up a little shadow where it meets the wall
Fill $SIDE_W $WALL_H ($RW - $SIDE_W * 2) 5 $FL_SH

# inner corner of each side wall
Fill ($SIDE_W - 1) 0 1 $RH $OUT
Fill ($RW - $SIDE_W) 0 1 $RH $OUT

Save-Img $PropDir 'room_bg'

# ============================================================
#  window.png - 104x78, sits on the back wall. Dawn sky.
# ============================================================
Start-Wall 104 78
Box 0 0 104 70 $WD_L $OUT
Fill 4 4 96 62 $OUT                     # glass recess
Fill 5 5 94 60 $SKY_1                   # sky, top band
Fill 5 25 94 14 $SKY_2
Fill 5 39 94 12 $SKY_3
Fill 5 51 94 14 $SKY_4
foreach ($s in @(@(18, 11), @(34, 18), @(66, 9), @(84, 20), @(50, 14))) { Fill $s[0] $s[1] 1 1 $CREAM }
Fill 74 12 5 5 $CREAM                   # small crescent moon
Fill 76 12 4 4 $SKY_1
# muntins (the wooden cross)
Fill 47 4 8 62 $OUT
Fill 48 5 6 60 $WD_L
Fill 4 31 96 8 $OUT
Fill 5 32 94 6 $WD_L
# sill
Box 0 66 104 12 $WD_H $OUT
Fill 2 76 100 2 $WD_D
Save-Img $PropDir 'window'

# ============================================================
#  frame_empty.png - 40x34. An empty photo frame: this is where
#  an unlocked memory will eventually be hung.
# ============================================================
Start-Wall 40 34
Fill 19 0 2 4 $WD_D                     # nail + cord
Box 0 3 40 31 $WD_D $OUT
Fill 4 7 32 23 $OUT
Fill 5 8 30 21 $DUSK
Fill 5 8 30 1 '6B5B66'
Save-Img $PropDir 'frame_empty'

# ============================================================
#  wardrobe.png - 64x88, stands against the back wall
# ============================================================
Start-Prop 64 88
Box 2 6 60 82 $WD_M $OUT             # body
Box 0 0 64 9  $WD_L $OUT             # cornice, overhangs the body
Box 5 12 26 66 $WD_L $WD_D           # left door
Box 33 12 26 66 $WD_L $WD_D          # right door
Fill 9 16 18 58 $WD_M                   # inset panels
Fill 37 16 18 58 $WD_M
Fill 28 42 2 7 $METAL                   # knobs
Fill 34 42 2 7 $METAL
Fill 5 80 8 6 $WD_D                     # feet
Fill 51 80 8 6 $WD_D
Fill 2 86 60 2 $OUT
Save-Img $PropDir 'wardrobe'

# ============================================================
#  door.png - 68x88. A hole in the wall, NOT a wardrobe standing
#  in front of it. So: no ground shadow, and it is placed with its
#  bottom edge exactly on the wall/floor line (y = 152).
#  The "set into the wall" feel comes from the shadow drawn on the
#  INSIDE of the frame (top + left), not from a drop shadow.
# ============================================================
Start-Flat 68 88
Box 0 0 68 88 $WD_D $OUT             # door casing
Fill 5 5 58 83 $OUT                  # recess line
Fill 6 6 56 82 $WD_M                 # the door slab
Fill 6 6 56 3 '3A2818'               # shadow the casing throws, top ...
Fill 6 6 3 82 '3A2818'               # ... and left
Box 13 13 42 28 $WD_L $WD_D          # upper panel
Box 13 47 42 36 $WD_L $WD_D          # lower panel
Oval 45 44 8 8 $OUT                  # knob
Oval 47 46 5 5 $METAL
Fill 6 85 56 3 '241710'              # the dark gap under the door
Save-Img $PropDir 'door'

# ============================================================
#  bed_base.png - 156x104, seen FROM THE SIDE.
#
#  The whole room is drawn face-on, so the bed lies down like everything else:
#  headboard on the left, pillow next to it, feet off to the right.
#
#  ★ Why it is this tall. The sleeper's face has to point at the CEILING, so
#    mengdol_lie is the front face rotated 90 degrees - which makes the head
#    34 wide and 48 TALL. The old bed had a 24px mattress; the head hung off
#    it by half its height. The mattress is now 52px so a lying head sits on
#    it properly. (Drawing the mattress top as a tall band is the usual RPG
#    cheat: the bed is side-on, the sleeper is seen from above, and nobody
#    notices as long as the mattress is deep enough to hold them.)
# ============================================================
Start-Prop 156 104
Box 0 0 18 104 $WD_L $OUT            # headboard
for ($y = 8; $y -lt 66; $y += 11) { Fill 4 $y 10 5 $WD_M }
Box 138 30 18 74 $WD_L $OUT          # footboard
Fill 16 34 124 8 $WD_M               # frame rail behind the mattress
Box 14 30 128 56 $CREAM $CREAM_D     # mattress
Fill 16 78 124 6 $CREAM_D            # its shaded underside
Fill 16 32 124 3 $WHITE              # a sheen along the top edge
Box 14 82 128 14 $WD_M $OUT          # bed frame under the mattress
Box 20 22 46 44 $WHITE $CREAM_D      # pillow
Fill 25 42 36 1 $CREAM_D             # a crease in the pillow
Fill 25 52 36 1 $CREAM_D
Fill 4 96 10 8 $WD_D                 # legs
Fill 142 96 10 8 $WD_D
Save-Img $PropDir 'bed_base'

# ============================================================
#  bed_quilt.png - 96x56. Covers the sleeper from the chest down.
#  Y-sort draws it in FRONT of the player, which is what sells
#  "lying in bed" without needing a second character sprite.
#
#  ★ The folded-over sheet is the band down the LEFT edge, not across the top.
#    The sleeper's head is at the left, so that is where a real quilt gets
#    folded back - at the chest, next to the pillow. A band across the top
#    reads as "the quilt is lying the wrong way round".
# ============================================================
Start-Img 96 56
Box 0 0 96 50 $SAGE $SAGE_O          # quilt
for ($x = 22; $x -lt 94; $x += 18) { Fill $x 4 1 42 $SAGE_D }
Fill 16 24 78 1 $SAGE_D
Fill 17 3 76 3 $SAGE_L               # top highlight
Box 0 0 16 50 $CREAM $CREAM_D        # folded-back sheet, at the pillow side
Fill 4 4 8 42 $WHITE
Fill 0 50 96 6 $SAGE_O               # the edge hanging over the frame
Save-Img $PropDir 'bed_quilt'

# ============================================================
#  glove.png - 복싱 글러브 두 짝을 정면에서 본 모습. 추억 1 의 방아쇠라
#  한눈에 "복싱 글러브"로 읽혀야 합니다.
#
#  글러브로 읽히게 하는 건 결국 이 네 가지입니다.
#    1. 위가 둥글고 아래로 갈수록 좁아지는 주먹 덩어리
#    2. 옆으로 튀어나온 엄지, 그리고 그 사이의 진한 골
#    3. 손가락 마디를 가로지르는 곡선 한 줄
#    4. 크림색 손목 밴드 + 구멍 + X 자로 엮인 끈
#  네 개 중 하나라도 빠지면 그냥 빨간 덩어리로 보입니다.
# ============================================================
$GL_R  = 'E4574D'   # 글러브 빨강
$GL_RD = 'A83431'   # 그늘
$GL_RM = 'C4433F'   # 중간톤
$GL_RL = 'F7907F'   # 하이라이트
$GL_O  = '3E1210'   # 외곽선
$LC    = 'F2E6CC'   # 손목 밴드
$LC_D  = 'BFA37A'
$LC_O  = '6B4A31'

# 한 짝. $dir = -1 이면 엄지가 왼쪽(왼손), +1 이면 오른쪽(오른손).
function Mitt([int]$x, [int]$y, [int]$dir) {
    if ($dir -lt 0) { $tx = $x - 6 } else { $tx = $x + 18 }

    # --- 엄지 (주먹보다 먼저 = 뒤에 깔림)
    Oval $tx ($y + 9) 12 14 $GL_O
    Oval ($tx + 1) ($y + 10) 10 12 $GL_RM
    Oval ($tx + 2) ($y + 10) 7 9 $GL_R

    # --- 주먹. 위는 둥글고 아래로 좁아집니다.
    Oval ($x - 1) ($y - 1) 28 26 $GL_O
    Fill ($x + 1) ($y + 10) 24 14 $GL_O
    Oval $x $y 26 24 $GL_R
    Fill ($x + 2) ($y + 11) 22 12 $GL_R
    Fill ($x + 3) ($y + 22) 20 2 $GL_R

    # --- 명암: 왼쪽 위가 밝고 오른쪽 아래가 어둡습니다 (방 조명과 같은 방향)
    Oval ($x + 9) ($y + 4) 18 20 $GL_RM
    Fill ($x + 13) ($y + 12) 11 11 $GL_RM
    Oval ($x + 15) ($y + 8) 12 16 $GL_RD
    Fill ($x + 18) ($y + 14) 6 9 $GL_RD
    Oval ($x + 3) ($y + 2) 11 8 $GL_RL
    Fill ($x + 4) ($y + 2) 8 3 $GL_RL

    # --- 손가락 마디를 가로지르는 골 한 줄. 이게 있어야 "쥔 주먹"이 됩니다.
    Fill ($x + 2) ($y + 13) 22 1 $GL_O
    Fill ($x + 3) ($y + 14) 20 1 $GL_RD
    if ($dir -lt 0) { Fill ($x + 1) ($y + 9) 2 6 $GL_O } else { Fill ($x + 23) ($y + 9) 2 6 $GL_O }

    # --- 손목 밴드 + 구멍 + X 자 끈
    Box ($x + 3) ($y + 23) 20 11 $LC $LC_O
    Fill ($x + 4) ($y + 31) 18 2 $LC_D
    foreach ($ex in 7, 17) {
        Fill ($x + $ex) ($y + 26) 2 2 $LC_O
        Fill ($x + $ex) ($y + 29) 2 2 $LC_O
    }
    for ($k = 0; $k -lt 4; $k++) {
        Fill ($x + 8 + $k * 2) ($y + 26 + $k) 2 1 $LC_D
        Fill ($x + 16 - $k * 2) ($y + 26 + $k) 2 1 $LC_D
    }
}

Start-Prop 66 36
Mitt 8 0 -1
Mitt 32 2 1
Save-Img $PropDir 'glove'
# ============================================================
#  desk.png - 120x74, with a burnt-down candle and a closed book
# ============================================================
Start-Prop 120 74
Fill 21 1 2 3 $SKY_4                    # candle flame
Fill 20 4 4 12 $CREAM                   # candle
Fill 20 4 1 12 $WHITE
Box 16 15 12 5 $METAL $OUT           # candle holder
Box 80 6 28 12 $INK $OUT             # book
Fill 83 16 22 2 $PAPER
Box 0 18 120 11 $WD_L $OUT           # desktop
Fill 2 28 116 2 $WD_D
Box 10 29 100 24 $WD_M $OUT          # drawer block
Box 13 32 44 18 $WD_L $WD_D
Box 63 32 44 18 $WD_L $WD_D
Fill 29 40 12 2 $METAL
Fill 79 40 12 2 $METAL
Box 6 29 9 45 $WD_D $OUT             # legs
Box 105 29 9 45 $WD_D $OUT
Save-Img $PropDir 'desk'

# ============================================================
#  chair.png - 30x44
# ============================================================
Start-Prop 30 44
Box 2 0 26 22 $WD_M $OUT             # backrest
Fill 8 4 4 14 $WD_L
Fill 18 4 4 14 $WD_L
Box 0 20 30 9 $WD_L $OUT             # seat
Box 3 28 5 16 $WD_D $OUT             # legs
Box 22 28 5 16 $WD_D $OUT
Save-Img $PropDir 'chair'

# ============================================================
#  rug.png - 240x120
# ============================================================
Start-Img 240 120
Oval 0 0 239 119 $RUG_O
Oval 4 4 231 111 $RUG_M
Oval 26 15 187 89 $RUG_O
Oval 30 19 179 81 $RUG_L
Oval 66 37 107 45 $RUG_M
Save-Img $PropDir 'rug'

# ============================================================
#  shadow.png - 40x14, a soft blob under the character.
#  Three rings instead of two so the edge does not look like a sticker.
# ============================================================
Start-Img 40 14
Oval 0 0 39 13 '0000001E'
Oval 4 2 31 10 '00000032'
Oval 9 4 21 6 '00000044'
Save-Img $PropDir 'shadow'

# ============================================================
#  prompt.png        - cream "!" = just something to look at
#  prompt_story.png  - yellow "!" = talking to this moves the story on
#                      (this is where a minigame will start)
# ============================================================
Write-Output 'assets/sprites/ui/'
$STORY   = 'FFD24A'   # warm yellow
$STORY_D = 'C98F1E'   # its shadow side

function Draw-Prompt([string]$fillCol, [string]$shadeCol) {
    Start-Img 16 18
    Box 0 0 16 14 $fillCol $OUT
    Fill 1 10 14 3 $shadeCol             # a little depth inside the bubble
    Fill 6 13 5 4 $OUT                   # tail
    Fill 6 13 3 3 $fillCol
    Fill 7 3 2 6 $OUT                    # exclamation mark
    Fill 7 10 2 2 $OUT
}

Draw-Prompt $CREAM $CREAM_D
Save-Img $UiDir 'prompt'

Draw-Prompt $STORY $STORY_D
Save-Img $UiDir 'prompt_story'

# ============================================================
#  tap.png - the little ring that blinks where you tapped to walk
# ============================================================
Start-Img 24 12
Oval 0 0 23 11 'F6EBD066'
Oval 2 1 19 9 '2A1B1400'
$script:Gfx.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
Oval 3 2 17 7 '00000000'          # punch the middle out
$script:Gfx.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
Save-Img $UiDir 'tap'

# ============================================================
#  preview sheet (never shipped with the game)
# ============================================================
$files = @(Get-ChildItem $PropDir -Filter '*.png' | Where-Object { $_.BaseName -ne 'room_bg' })
$bg = [System.Drawing.Image]::FromFile((Join-Path $PropDir 'room_bg.png'))
$scale = 2
$pv = New-Object System.Drawing.Bitmap(($bg.Width * $scale), (($bg.Height + 300) * $scale), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$pg = [System.Drawing.Graphics]::FromImage($pv)
$pg.Clear((Hex '1A120C'))
$pg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$pg.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$pg.DrawImage($bg, 0, 0, $bg.Width * $scale, $bg.Height * $scale)
$cx = 8; $cy = $bg.Height + 8; $rowH = 0
foreach ($f in $files) {
    $im = [System.Drawing.Image]::FromFile($f.FullName)
    if (($cx + $im.Width) -gt ($bg.Width - 8)) { $cx = 8; $cy += $rowH + 8; $rowH = 0 }
    $pg.DrawImage($im, ($cx * $scale), ($cy * $scale), ($im.Width * $scale), ($im.Height * $scale))
    $cx += $im.Width + 8
    if ($im.Height -gt $rowH) { $rowH = $im.Height }
    $im.Dispose()
}
$pg.Dispose(); $bg.Dispose()
$pv.Save((Join-Path $PSScriptRoot 'room_preview.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$pv.Dispose()
Write-Output 'tools/room_preview.png'
