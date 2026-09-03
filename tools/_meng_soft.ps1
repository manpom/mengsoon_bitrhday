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
        GroundShadow $cx ($hcy + $hry * 0.16) ($hrx * 0.88) ($hry * 0.46) $MP.flush 0.80
        foreach ($sd in @(-1, 1)) {
            GroundShadow ($cx + $sd * $hrx * 0.52) ($hcy + $hry * 0.20) ($hrx * 0.38) ($hry * 0.28) $MP.flushDeep 0.70
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

    # --- 눈썹
    # ★ 표정마다 눈만 다르면 "졸린 것"과 "웃는 것"이 실루엣에서 구분이 안 갑니다.
    #   웃음은 눈썹을 위로 튕기고, 부끄러움은 팔(八)자로 처지게 해서 신호를 더합니다.
    #   무표정 · sleepy 는 눈썹을 안 그립니다 (그게 오히려 "쉬는 얼굴"로 읽힘).
    switch ($face) {
        'laugh' {
            foreach ($sd in @(-1, 1)) {
                CurveStroke @(
                    (Pt ($cx + $sd * ($ex - $er * 0.85)) ($ey - $er * 1.42)),
                    (Pt ($cx + $sd * ($ex + $er * 0.35)) ($ey - $er * 1.86))
                ) $MP.eye 5 0.5
            }
        }
        'happy' {
            foreach ($sd in @(-1, 1)) {
                CurveStroke @(
                    (Pt ($cx + $sd * ($ex - $er * 0.7)) ($ey - $er * 1.28)),
                    (Pt ($cx + $sd * ($ex + $er * 0.3)) ($ey - $er * 1.58))
                ) $MP.eye 4.5 0.5
            }
        }
        'shy' {
            foreach ($sd in @(-1, 1)) {
                CurveStroke @(
                    (Pt ($cx + $sd * ($ex - $er * 0.55)) ($ey - $er * 1.5)),
                    (Pt ($cx + $sd * ($ex + $er * 0.85)) ($ey - $er * 1.1))
                ) $MP.eye 4.5 0.5
            }
        }
    }

    # --- 눈
    switch ($face) {
        'happy' {
            foreach ($sd in @(-1, 1)) {
                $px = $cx + $sd * $ex
                EyeArcSoft $px ($ey + 4) ($er * 0.95) 0.72 6
            }
        }
        'laugh' {
            # ★ 자는 눈과 헷갈리지 않도록 sleepy 보다 훨씬 깊고 두껍게 꽉 감습니다.
            #   (졸린 눈은 거의 일자, 웃는 눈은 눌러 감은 반원)
            foreach ($sd in @(-1, 1)) {
                $px = $cx + $sd * $ex
                EyeArcSoft $px ($ey + 2) ($er * 1.02) 1.55 10
                FillPath (EllipsePath ($px + $sd * 8) ($ey + 26) 8 11) $MP.tear
                FillPath (EllipsePath ($px + $sd * 6) ($ey + 21) 3 3) $MP.white
            }
        }
        'shy' {
            # 눈을 내리깔고 시선을 피하는 모습 - 아래로 처진 얇은 반달
            foreach ($sd in @(-1, 1)) { EyeArcSoft ($cx + $sd * $ex) ($ey + 12) ($er * 0.85) -0.30 5 }
        }
        'sleepy' {
            # 거의 일자에 가까운, 아주 얕은 처짐 - laugh 의 깊은 반원과 뚜렷이 다릅니다
            foreach ($sd in @(-1, 1)) { EyeArcSoft ($cx + $sd * $ex) ($ey + 6) ($er * 0.92) -0.55 5 }
            # 눈 밑 그늘 - 피곤함의 신호
            foreach ($sd in @(-1, 1)) {
                GroundShadow ($cx + $sd * $ex) ($ey + 15) ($er * 0.78) 6 '#7FA37A' 0.30
            }
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
    elseif ($face -eq 'happy') {
        # 자는 얼굴과 헷갈리지 않도록 다문 곡선이 아니라 [b]살짝 벌어진 웃음[/b]으로.
        # laugh 보다 작고, 눈물 · 혀 없이 하양만 살짝 보입니다.
        $mo = BlobPath @(
            (Pt ($cx - $hrx * 0.30) ($my - 2)), (Pt $cx ($my - 8)),
            (Pt ($cx + $hrx * 0.30) ($my - 2)), (Pt $cx ($my + 16))
        ) 0.5
        FillPath $mo $MP.mouthIn
        FillPath (BlobPath @(
                (Pt ($cx - $hrx * 0.21) ($my - 3)), (Pt $cx ($my - 7)),
                (Pt ($cx + $hrx * 0.21) ($my - 3)), (Pt $cx ($my + 4))
            ) 0.5) $MP.white
    }
    elseif ($face -eq 'shy') {
        # 당황해서 어쩔 줄 모르는 물결 입. 웃는 곡선이 아니라 지그재그입니다 -
        # 그래야 "부끄러움"이 "기쁨"으로 안 읽힙니다.
        CurveStroke @(
            (Pt ($cx - 15) ($my + 1)), (Pt ($cx - 6) ($my - 5)), (Pt $cx ($my + 3)),
            (Pt ($cx + 6) ($my - 5)), (Pt ($cx + 15) ($my + 1))
        ) '#6B5344' 5 0.3
    }
    elseif ($face -eq 'sleepy') {
        # 하품하듯 살짝 벌어진 작은 입. 미소 곡선이 아니라 둥근 구멍이라
        # "웃는 게 아니라 나른하다"가 바로 읽힙니다.
        FillPath (EllipsePath $cx ($my + 7) 9 7) $MP.mouthIn
    }
    else {
        # 무표정(normal) 은 하루 대부분을 차지하는 얼굴입니다. 너무 깊이 웃으면
        # "가만히 서 있는데도 씩 웃고 있다"로 보이므로 얕고 부드러운 곡선만 씁니다.
        $amp = 10.0; $mw = 0.52
        if ($face -eq 'sad' -or $face -eq 'angry') { $amp = -16.0; $mw = 0.60 }
        CurveStroke @(
            (Pt ($cx - $hrx * $mw) ($my - $amp * 0.45)),
            (Pt $cx ($my + $amp)),
            (Pt ($cx + $hrx * $mw) ($my - $amp * 0.45))
        ) '#6B5344' 7 0.6
        # 맹순이의 앞니 - 정체성이라 무표정에서도 유지합니다 (경계선 없이 한 덩어리)
        if ((-not $isBoy) -and $face -eq 'normal') {
            $ty = $my + $amp - 2
            FillPath (RoundRectPath ($cx - 16) $ty 32 20 8) $MP.white
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

# ============================================================
#  침대에 누웠을 때 - 이불 밖으로 얼굴만 내놓은 모습
# ------------------------------------------------------------
#  ★ 예전에는 서 있는 그림을 통째로 90도 돌렸습니다. 몸이 옆으로 길게
#    누워 보여서 "침대에 가로로 누워있다"는 지적을 받았습니다.
#    이제는 몸을 아예 그리지 않습니다. 이불 밖으로 [b]얼굴만[/b] 내놓은
#    정면 모습이고, 나머지는 이불색 둔덕으로 덮습니다. 베개에 머리를 대고
#    천장을 보는 자세이므로 서 있을 때와 같은 정면 얼굴을 그대로 씁니다.
#
#  ★ 머리 크기는 $MG 표준값(hrx=112, hry=99) 그대로 씁니다. 눈·코·입은
#    Draw-Face 안에서 $MG.eyeR 처럼 [b]고정 절대값[/b]을 쓰기 때문에,
#    머리만 따로 축소해서 그리면 눈이 머리에 비해 커져 버립니다.
#    그래서 300x300 캔버스에 표준 크기로 그린 다음, 정사각형이라
#    가로세로 같은 비율(0.64)로 통째로 축소해서 192 프레임에 넣습니다.
# ============================================================
function Draw-LieHead([string]$who) {
    $isBoy = ($who -eq 'mengdol')
    $cx = 150.0; $hcy = 128.0
    $hrx = $MG.headRx; $hry = $MG.headRy

    # --- 이불 둔덕 (얼굴 아래쪽을 덮습니다. 방의 이불과 같은 계열 색)
    # 방의 이불(build_room_iso.ps1 의 $C3.quilt*)과 [b]똑같은 색[/b]입니다 -
    # 다른 색이면 "이 이불이 그 이불이 맞나" 하는 어색함이 생깁니다.
    $quiltF = '#A2BE93'; $quiltT = '#BDD6AC'; $quiltS = '#8CA880'
    $mound = BlobPath @(
        (Pt -10 300), (Pt -10 234),
        (Pt ($cx - 96) 202), (Pt ($cx - 30) 222),
        (Pt $cx 208), (Pt ($cx + 30) 222), (Pt ($cx + 96) 202),
        (Pt 310 234), (Pt 310 300)
    ) 0.45
    FillPath $mound $quiltF
    ShadeTopOnly $mound $quiltT ($cx - 30) 216
    PushClip $mound
    GroundShadow ($cx + 60) 262 130 40 $quiltS 0.5
    PopClip
    CurveStroke @((Pt ($cx - 84) 234), (Pt ($cx - 16) 222), (Pt ($cx + 46) 230)) $quiltS 3 0.5

    # --- 머리 (Draw-Char 의 머리 모양과 똑같습니다 - 다른 프레임과 통일감)
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
    $head = BlobPath $hp 0.42
    DropShadow $head 0 6 '#6B5344' 0.12 4
    FillPath $head $MP.skin
    ShadeTopOnly $head $MP.skinLit ($cx - $hrx * 0.26) ($hcy - $hry * 0.52)
    PushClip $head
    GroundShadow ($cx - $hrx * 0.18) ($hcy - $hry * 0.82) ($hrx * 0.52) ($hry * 0.34) '#DCEFD2' 0.55
    PopClip
    PushClip $head
    FillPath (EllipsePath $cx ($hcy + $hry * 0.92) ($hrx * 0.76) ($hry * 0.42)) $MP.cream
    PopClip
    Draw-Face $cx $hcy $hrx $hry 'sleepy' $isBoy $head

    # --- 맹순이 리본 (누워도 정체성 유지)
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
