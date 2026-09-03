# ============================================================
#  맹돌이 · 맹순이 그리기 (A안 「몽글 젤리」 제작용)
# ------------------------------------------------------------
#  concepts_soft.ps1 은 안을 고르기 위한 [b]시안[/b]이고, 이 파일이
#  게임에 들어갈 프레임을 굽는 [b]본품[/b]입니다. 방향 · 걷기 · 표정 · 포즈를
#  전부 매개변수로 받습니다.
#
#      Draw-Char @{ who='mengdol'; dir='down'; step=1; face='happy' }
#
#  ★ 명암 규칙 (방과 같아야 같은 세계에 있는 것으로 보입니다)
#     - 빛은 위에서. ShadeTopOnly 로 윗면만 밝힙니다.
#     - 얼굴에는 아래 그늘을 넣지 않습니다. 볼에 때가 낀 것처럼 보입니다.
#     - 몸통 · 팔 · 다리에는 밑단 그늘을 넣어 두께를 만듭니다.
#     - 외곽선은 없습니다. 형태는 명암으로만 나눕니다.
#
#  ★ 시점: 방을 위에서 내려다보므로 얼굴은 머리의 [b]아래쪽[/b]에 붙습니다.
#     그래야 정수리가 보이고 캐릭터가 바닥에 서 있는 것으로 읽힙니다.
# ============================================================

. (Join-Path $PSScriptRoot '_soft.ps1')

# ---------- 팔레트 ----------
$MP = @{
    skinLit   = '#CDE4C3'; skin = '#AFD3A6'; skinShd = '#8CB491'
    cream     = '#FFF6DE'; creamShd = '#F0DFBC'
    eye       = '#4E4048'; white = '#FFFFFF'
    blush     = '#EFACA4'
    flush     = '#FF7A7A'; flushDeep = '#E05555'
    mouthIn   = '#6E2233'; tongue = '#D9436B'
    tear      = '#AFD4F0'

    hoodie    = '#AFC4DC'; hoodieShd = '#95AAC6'; hoodieLit = '#C6D6E6'
    dress     = '#FFF4E6'; dressShd = '#EEDFC8'; dressLit = '#FFFDF6'
    skirt     = '#EFBAC3'; skirtShd = '#D79FAB'; skirtLit = '#F2CDD3'
    ribbon    = '#E9A2AB'; ribbonShd = '#CC8792'
}

# 캔버스 안에서의 기준 치수 (460x470 캔버스, 가운데 x=230)
$MG = @{
    headRx = 112.0; headRy = 99.0; headCy = 152.0
    bodyTop = 236.0; bodyW = 132.0; footY = 362.0
    eyeR = 21.0
}

# ============================================================
#  캐릭터 한 명
#    who  : mengdol | mengsoon
#    dir  : down 앞 | up 뒤
#    step : 0 서기 / 1 왼발 / -1 오른발
#    face : normal happy surprise sad angry sleepy shy laugh
#    pose : stand guard punch1 punch2 laugh fart
#    nude : 옷 벗김 (욕실 컷신 · 리듬 파트)
# ============================================================
function Draw-Char([hashtable]$o, [double]$cx = 230.0) {
    $who = $o.who
    $dir = if ($o.ContainsKey('dir')) { $o.dir } else { 'down' }
    $step = if ($o.ContainsKey('step')) { [int]$o.step } else { 0 }
    $face = if ($o.ContainsKey('face')) { $o.face } else { 'normal' }
    $pose = if ($o.ContainsKey('pose')) { $o.pose } else { 'stand' }
    $nude = ($o.ContainsKey('nude') -and $o.nude)

    $isBoy = ($who -eq 'mengdol')
    $isBack = ($dir -eq 'up')

    $hrx = $MG.headRx; $hry = $MG.headRy; $hcy = $MG.headCy
    $bw = $MG.bodyW; $by0 = $MG.bodyTop; $footY = $MG.footY
    $by1 = $footY - 26

    # 배꼽 잡고 웃을 때는 몸이 굽고 머리가 내려옵니다
    $headDy = 0.0
    if ($pose -eq 'laugh') { $headDy = 16.0; $by0 += 10.0 }
    $hcy += $headDy

    if ($nude) { $top = $MP.skin; $topShd = $MP.skinShd; $topLit = $MP.skinLit }
    elseif ($isBoy) { $top = $MP.hoodie; $topShd = $MP.hoodieShd; $topLit = $MP.hoodieLit }
    else { $top = $MP.dress; $topShd = $MP.dressShd; $topLit = $MP.dressLit }

    # ---------- 걷기 · 포즈에 따른 팔다리 위치 ----------
    # ★ 다리를 좌우로 벌리기만 하면 걷는 게 아니라 옆으로 미끄러지는 걸로 보입니다.
    #   한쪽 발을 [b]들어 올려야[/b] 걷기로 읽힙니다.
    $liftL = 0.0; $liftR = 0.0
    if ($step -eq 1) { $liftL = 16.0 }
    if ($step -eq -1) { $liftR = 16.0 }

    $armL = @(($cx - $bw * 0.60), ($by0 + 74))
    $armR = @(($cx + $bw * 0.60), ($by0 + 74))
    switch ($pose) {
        'guard' { $armL = @(($cx - 34), ($by0 + 26)); $armR = @(($cx + 34), ($by0 + 26)) }
        'punch1' { $armL = @(($cx - $bw * 1.02), ($by0 + 34)); $armR = @(($cx + 34), ($by0 + 26)) }
        'punch2' { $armL = @(($cx - 34), ($by0 + 26)); $armR = @(($cx + $bw * 1.02), ($by0 + 34)) }
        'laugh' { $armL = @(($cx - $bw * 0.30), ($by0 + 86)); $armR = @(($cx + $bw * 0.30), ($by0 + 86)) }
        'fart' { $armL = @(($cx - $bw * 0.98), ($by0 + 22)); $armR = @(($cx + $bw * 0.98), ($by0 + 22)) }
        default {
            if ($step -eq 1) { $armL[1] += 14; $armR[1] -= 14 }
            if ($step -eq -1) { $armL[1] -= 14; $armR[1] += 14 }
        }
    }

    # ---------- 팔 (몸통보다 먼저 = 옆으로 나온 것만 보임) ----------
    foreach ($a in @(@($armL, -1.0), @($armR, 1.0))) {
        $h = $a[0]; $sd = $a[1]
        $sx = $cx + $sd * ($bw * 0.42); $sy = $by0 + 26
        $arm = BlobPath @(
            (Pt ($sx - $sd * 14) ($sy - 14)),
            (Pt ($h[0] - $sd * 14) ($h[1] - 20)),
            (Pt ($h[0] + $sd * 12) ($h[1] + 14)),
            (Pt ($sx + $sd * 16) ($sy + 24))
        ) 0.5
        FillPath $arm $top
        ShadeTopOnly $arm $topLit $sx ($sy - 6)
        $hand = EllipsePath $h[0] $h[1] 20 19
        FillPath $hand $MP.skin
        ShadeTopOnly $hand $MP.skinLit ($h[0] - 6) ($h[1] - 7)
        PushClip $hand
        GroundShadow ($h[0] + 7) ($h[1] + 16) 18 12 $MP.skinShd 0.55
        PopClip
    }

    # ---------- 다리 + 물갈퀴 발 ----------
    foreach ($lg in @(@(-1.0, $liftL), @(1.0, $liftR))) {
        $fx = $cx + $lg[0] * $bw * 0.24
        $lift = [double]$lg[1]
        $fy = $footY - $lift
        $leg = RoundRectPath ($fx - 17) ($by1 - 16) 34 (40 - $lift) 16
        FillPath $leg $MP.skin
        ShadeTopOnly $leg $MP.skinLit $fx ($by1 - 8)
        $foot = BlobPath @(
            (Pt ($fx - 28) ($fy - 12)), (Pt ($fx - 33) ($fy + 2)),
            (Pt ($fx - 13) ($fy + 13)), (Pt ($fx + 21) ($fy + 12)),
            (Pt ($fx + 32) ($fy - 2)), (Pt ($fx + 9) ($fy - 15))
        ) 0.5
        FillPath $foot $MP.skin
        ShadeTopOnly $foot $MP.skinLit ($fx - 6) ($fy - 6)
        PushClip $foot
        GroundShadow ($fx + 7) ($fy + 15) 28 13 $MP.skinShd 0.5
        PopClip
    }

    # ---------- 몸통 ----------
    $body = BlobPath @(
        (Pt ($cx - $bw * 0.36) ($by0 - 4)),
        (Pt ($cx - $bw * 0.50) ($by0 + ($by1 - $by0) * 0.40)),
        (Pt ($cx - $bw * 0.46) ($by1 - 4)),
        (Pt $cx ($by1 + 6)),
        (Pt ($cx + $bw * 0.46) ($by1 - 4)),
        (Pt ($cx + $bw * 0.50) ($by0 + ($by1 - $by0) * 0.40)),
        (Pt ($cx + $bw * 0.36) ($by0 - 4))
    ) 0.5
    FillPath $body $top
    ShadeTopOnly $body $topLit ($cx - $bw * 0.18) ($by0 + 16)
    PushClip $body
    GroundShadow ($cx + $bw * 0.10) ($by1 + 6) ($bw * 0.62) 28 $topShd 0.60
    GroundShadow ($cx + $bw * 0.46) (($by0 + $by1) / 2) 20 ($by1 - $by0) $topShd 0.35
    PopClip

    # ---------- 옷 · 배 ----------
    if ($nude) {
        # 크림색 배
        $belly = EllipsePath $cx ($by0 + ($by1 - $by0) * 0.56) ($bw * 0.30) (($by1 - $by0) * 0.36)
        FillPath $belly $MP.cream
        ShadeTopOnly $belly '#FFFFFF' ($cx - 10) ($by0 + 40)
    }
    elseif ($isBoy) {
        if (-not $isBack) {
            foreach ($sd in @(-1, 1)) {
                CurveStroke @(
                    (Pt ($cx + $sd * 17) ($by0 + 4)),
                    (Pt ($cx + $sd * 13) ($by0 + 28)),
                    (Pt ($cx + $sd * 18) ($by0 + 50))
                ) $MP.white 8 0.5
            }
        }
        # 후드 - 앞모습에서는 목 뒤에 살짝, 뒷모습에서는 등에 크게
        # ★ PowerShell 은 인자 안에 if 를 인라인으로 못 씁니다.
        #   ($by0 + (if ... )) 는 파싱 에러입니다. 반드시 변수로 먼저 뺍니다.
        $hoodDy = 2.0; $hoodRx = $bw * 0.30; $hoodRy = 16.0
        if ($isBack) { $hoodDy = 40.0; $hoodRx = $bw * 0.40; $hoodRy = 42.0 }
        $hood = EllipsePath $cx ($by0 + $hoodDy) $hoodRx $hoodRy
        FillPath $hood $topShd
        ShadeTopOnly $hood $top $cx ($by0 + 6)
    }
    else {
        $sk = BlobPath @(
            (Pt ($cx - $bw * 0.42) ($by1 - 56)), (Pt ($cx - $bw * 0.66) ($by1 - 6)),
            (Pt $cx ($by1 + 8)), (Pt ($cx + $bw * 0.66) ($by1 - 6)),
            (Pt ($cx + $bw * 0.42) ($by1 - 56))
        ) 0.45
        FillPath $sk $MP.skirt
        ShadeTopOnly $sk $MP.skirtLit ($cx - $bw * 0.18) ($by1 - 44)
        PushClip $sk
        GroundShadow ($cx + $bw * 0.16) ($by1 + 10) ($bw * 0.66) 26 $MP.skirtShd 0.6
        PopClip
        if (-not $isBack) {
            foreach ($sd in @(-1, 1)) {
                $lp = EllipsePath ($cx + $sd * 22) ($by0 + 22) 18 14
                FillPath $lp $MP.ribbon
            }
            FillPath (EllipsePath $cx ($by0 + 22) 11 11) $MP.ribbonShd
        }
    }

    # ---------- 머리 ----------
    $hp = @(
        (Pt ($cx - $hrx * 0.46) ($hcy - $hry * 0.94)),
        (Pt ($cx - $hrx * 0.86) ($hcy - $hry * 0.62)),
        (Pt ($cx - $hrx * 1.00) ($hcy - $hry * 0.06)),
        (Pt ($cx - $hrx * 0.88) ($hcy + $hry * 0.54)),
        (Pt ($cx - $hrx * 0.48) ($hcy + $hry * 0.94)),
        (Pt $cx ($hcy + $hry * 1.00)),
        (Pt ($cx + $hrx * 0.48) ($hcy + $hry * 0.94)),
        (Pt ($cx + $hrx * 0.88) ($hcy + $hry * 0.54)),
        (Pt ($cx + $hrx * 1.00) ($hcy - $hry * 0.06)),
        (Pt ($cx + $hrx * 0.86) ($hcy - $hry * 0.62)),
        (Pt ($cx + $hrx * 0.46) ($hcy - $hry * 0.94)),
        (Pt $cx ($hcy - $hry * 0.86))
    )
    # 장력이 높으면 눈두덩 두 개가 뾰족하게 튀어 하트나 고양이 귀처럼 보입니다.
    $head = BlobPath $hp 0.42
    DropShadow $head 0 8 '#6B5344' 0.12 4
    FillPath $head $MP.skin
    ShadeTopOnly $head $MP.skinLit ($cx - $hrx * 0.26) ($hcy - $hry * 0.52)
    PushClip $head
    GroundShadow ($cx - $hrx * 0.18) ($hcy - $hry * 0.82) ($hrx * 0.52) ($hry * 0.34) '#DCEFD2' 0.55
    PopClip

    if ($isBack) {
        # 뒷모습: 얼굴이 없습니다. 눈두덩 사이 얕은 골만.
        PushClip $head
        GroundShadow $cx ($hcy + $hry * 0.10) ($hrx * 0.16) ($hry * 0.62) $MP.skinShd 0.35
        GroundShadow $cx ($hcy + $hry * 0.98) ($hrx * 0.70) ($hry * 0.24) $MP.skinShd 0.40
        PopClip
    }
    else {
        # 크림색 턱
        PushClip $head
        FillPath (EllipsePath $cx ($hcy + $hry * 0.92) ($hrx * 0.76) ($hry * 0.42)) $MP.cream
        PopClip
        Draw-Face $cx $hcy $hrx $hry $face $isBoy $head
    }

    # ---------- 맹순이 머리 리본 ----------
    if (-not $isBoy) {
        $ry0 = $hcy - $hry * 0.92
        foreach ($sd in @(-1, 1)) {
            $lp2 = BlobPath @(
                (Pt ($cx + $sd * 14) $ry0),
                (Pt ($cx + $sd * 44) ($ry0 - 30)),
                (Pt ($cx + $sd * 68) ($ry0 - 6)),
                (Pt ($cx + $sd * 48) ($ry0 + 22)),
                (Pt ($cx + $sd * 16) ($ry0 + 14))
            ) 0.55
            FillPath $lp2 $MP.ribbon
            ShadeTopOnly $lp2 '#F4C6CD' ($cx + $sd * 40) ($ry0 - 12)
        }
        FillPath (EllipsePath $cx ($ry0 + 5) 17 16) $MP.ribbonShd
    }
}

# ============================================================
#  얼굴
# ============================================================
function Draw-Face([double]$cx, [double]$hcy, [double]$hrx, [double]$hry,
    [string]$face, [bool]$isBoy, $headPath) {
    $ex = $hrx * 0.48
    $ey = $hcy - $hry * 0.30
    $er = $MG.eyeR
    $my = $hcy + $hry * 0.40

    # --- 부끄러움: 얼굴 전체가 벌겋게 (눈·입보다 먼저)
    # ★ 반드시 머리 안쪽으로 잘라야 합니다. 안 그러면 빨간 띠가 머리 밖으로
    #   삐져나와 얼굴에 띠를 두른 것처럼 보입니다.
    if ($face -eq 'shy') {
        PushClip $headPath
        GroundShadow $cx ($hcy + $hry * 0.16) ($hrx * 0.86) ($hry * 0.44) $MP.flush 0.72
        foreach ($sd in @(-1, 1)) {
            GroundShadow ($cx + $sd * $hrx * 0.52) ($hcy + $hry * 0.22) ($hrx * 0.34) ($hry * 0.24) $MP.flushDeep 0.62
        }
        PopClip
    }
    else {
        foreach ($sd in @(-1, 1)) {
            GroundShadow ($cx + $sd * $hrx * 0.70) ($hcy + $hry * 0.36) 26 16 $MP.blush 0.78
        }
    }

    # --- 콧구멍
    foreach ($sd in @(-1, 1)) {
        FillPath (EllipsePath ($cx + $sd * 12) ($hcy + $hry * 0.20) 4 3) '#8A6E59'
    }

    # --- 눈
    switch ($face) {
        { $_ -in 'happy', 'laugh' } {
            foreach ($sd in @(-1, 1)) {
                $px = $cx + $sd * $ex
                EyeArcSoft $px ($ey + 4) ($er * 0.95) 0.78 6
            }
            if ($face -eq 'laugh') {
                foreach ($sd in @(-1, 1)) {
                    $px = $cx + $sd * ($ex + $er * 0.95)
                    FillPath (EllipsePath ($px + $sd * 8) ($ey + 26) 8 11) $MP.tear
                    FillPath (EllipsePath ($px + $sd * 6) ($ey + 21) 3 3) $MP.white
                }
            }
        }
        'shy' {
            foreach ($sd in @(-1, 1)) { EyeArcSoft ($cx + $sd * $ex) ($ey + 8) ($er * 0.95) -0.5 7 }
        }
        'sleepy' {
            foreach ($sd in @(-1, 1)) { EyeArcSoft ($cx + $sd * $ex) ($ey + 4) ($er * 0.92) -0.18 6 }
        }
        default {
            $erx = $er * 0.94; $ery = $er
            if ($face -eq 'surprise') { $erx = $er * 1.12; $ery = $er * 1.18 }
            if ($face -eq 'sad') { $ery = $er * 0.9 }
            foreach ($sd in @(-1, 1)) {
                $px = $cx + $sd * $ex
                FillPath (EllipsePath $px $ey $erx $ery) $MP.eye
                FillPath (EllipsePath ($px - $er * 0.30) ($ey - $er * 0.38) ($er * 0.36) ($er * 0.32)) $MP.white
            }
            if ($face -eq 'sad') {
                FillPath (EllipsePath ($cx + $ex + $er * 0.7) ($ey + $er * 1.1) 7 10) $MP.tear
            }
            if ($face -eq 'angry') {
                foreach ($sd in @(-1, 1)) {
                    CurveStroke @(
                        (Pt ($cx + $sd * ($ex + $er * 0.9)) ($ey - $er * 1.34)),
                        (Pt ($cx + $sd * ($ex - $er * 0.7)) ($ey - $er * 0.94))
                    ) $MP.eye 8 0.5
                }
            }
        }
    }

    # --- 입
    if ($face -eq 'surprise') {
        FillPath (EllipsePath $cx ($my + 8) 15 18) $MP.mouthIn
    }
    elseif ($face -eq 'laugh') {
        $mo = BlobPath @(
            (Pt ($cx - $hrx * 0.32) $my), (Pt $cx ($my - 6)),
            (Pt ($cx + $hrx * 0.32) $my), (Pt $cx ($my + 30))
        ) 0.5
        FillPath $mo $MP.mouthIn
        FillPath (EllipsePath $cx ($my + 21) ($hrx * 0.15) 8) $MP.tongue
        FillPath (BlobPath @(
                (Pt ($cx - $hrx * 0.25) ($my + 1)), (Pt $cx ($my - 3)),
                (Pt ($cx + $hrx * 0.25) ($my + 1)), (Pt $cx ($my + 9))
            ) 0.5) $MP.white
    }
    else {
        $amp = 22.0
        if ($face -eq 'sad' -or $face -eq 'angry') { $amp = -16.0 }
        if ($face -eq 'sleepy' -or $face -eq 'shy') { $amp = 8.0 }
        CurveStroke @(
            (Pt ($cx - $hrx * 0.60) ($my - $amp * 0.45)),
            (Pt $cx ($my + $amp)),
            (Pt ($cx + $hrx * 0.60) ($my - $amp * 0.45))
        ) '#6B5344' 7 0.5
        # 맹순이의 앞니 - 정체성이라 웃는 얼굴에서 유지합니다 (경계선 없이 한 덩어리)
        if ((-not $isBoy) -and ($face -eq 'normal' -or $face -eq 'happy')) {
            $ty = $my + $amp - 4
            FillPath (RoundRectPath ($cx - 21) $ty 42 29 10) $MP.white
        }
    }
}

# 감은 눈. 선을 긋지 않고 [b]가는 덩어리[/b]로 칠합니다 -
# 이 스타일에는 외곽선이 없어서 선을 그으면 눈만 도트처럼 튑니다.
function EyeArcSoft([double]$cx, [double]$cy, [double]$rx, [double]$slope, [double]$thick) {
    $pts = @()
    for ($i = -6; $i -le 6; $i++) {
        $t = $i / 6.0
        $pts += (Pt ($cx + $t * $rx) ($cy + [math]::Abs($t) * $rx * $slope * -0.55))
    }
    for ($i = 6; $i -ge -6; $i--) {
        $t = $i / 6.0
        $pts += (Pt ($cx + $t * $rx) ($cy + [math]::Abs($t) * $rx * $slope * -0.55 + $thick))
    }
    FillPath (BlobPath $pts 0.3) $MP.eye
}
