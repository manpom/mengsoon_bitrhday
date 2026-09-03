# ============================================================
#  캐릭터 아트 디렉션 안 (컨펌용)
# ------------------------------------------------------------
#  실행:
#     powershell -ExecutionPolicy Bypass -File tools\concepts_soft.ps1
#  결과 -> tools/concepts/soft_A.png ... soft_D.png
#
#    A 「몽글 젤리」    외곽선 없음. 머리가 제일 크고 가장 말랑함.  ← 채택
#    B 「그림책 크레용」굵은 갈색 선 + 납작한 파스텔.
#    C 「모던 마스코트」얇고 또렷한 선 + 림라이트.
#    D 「손그림 수채」  흔들리는 연필선 + 번진 물감 + 종이 결.
#
#  A~C 는 마감만 다른 "깔끔한 벡터" 계열이고, D 는 결 자체가 다릅니다.
#
#  네 안 모두 지키는 것 (캐릭터 정체성):
#    큰 머리 / 위에 눈두덩 두 개 / 얼굴만큼 넓은 개구리 입 / 크림색 턱과 배 /
#    맹순이의 앞니와 머리 리본 / 맹돌이의 후드티
# ============================================================

. (Join-Path $PSScriptRoot '_soft.ps1')

$OutDir = Join-Path $PSScriptRoot 'concepts'
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Force -Path $OutDir | Out-Null }

# ---------- 파스텔 팔레트 ----------
# 쨍한 원색을 피하고 전부 한 톤 낮춘 따뜻한 색으로 통일했습니다.
$P = @{
    paper     = '#FBF3E7'
    paper2    = '#F4E7D5'
    paperWarm = '#F7EBD8'
    line      = '#6B5344'   # 외곽선 - 검정이 아니라 따뜻한 갈색
    lineSoft  = '#8A6E59'

    skinLit   = '#CDE4C3'
    skin      = '#AFD3A6'
    skinShd   = '#8CB491'

    cream     = '#FFF6DE'
    creamShd  = '#F0DFBC'

    eye       = '#4E4048'
    eyeSoft   = '#5E4A56'
    white     = '#FFFFFF'
    blush     = '#EFACA4'

    hoodie    = '#AFC4DC'
    hoodieShd = '#95AAC6'
    hoodieLit = '#C6D6E6'

    dress     = '#FFF4E6'
    dressShd  = '#EEDFC8'
    skirt     = '#EFBAC3'
    skirtShd  = '#D79FAB'
    ribbon    = '#E9A2AB'
    ribbonShd = '#CC8792'
}

$STYLES = @(
    @{
        key = 'A'; name = '몽글 젤리'
        headRx = 112.0; headRy = 99.0; headCy = 152.0
        bodyTop = 236.0; bodyW = 132.0; footY = 362.0
        line = 0.0; eye = 'dot'; eyeR = 21.0; soft = 0.62
        rim = $true; hand = $false; wobble = 0.0
    },
    @{
        key = 'B'; name = '그림책 크레용'
        headRx = 104.0; headRy = 94.0; headCy = 156.0
        bodyTop = 240.0; bodyW = 126.0; footY = 364.0
        line = 5.0; eye = 'lid'; eyeR = 19.0; soft = 0.5
        rim = $false; hand = $false; wobble = 0.0
    },
    @{
        key = 'C'; name = '모던 마스코트'
        headRx = 94.0; headRy = 86.0; headCy = 138.0
        bodyTop = 216.0; bodyW = 116.0; footY = 366.0
        line = 3.0; eye = 'almond'; eyeR = 18.0; soft = 0.42
        rim = $true; hand = $false; wobble = 0.0
    },
    @{
        key = 'D'; name = '손그림 수채'
        headRx = 106.0; headRy = 96.0; headCy = 154.0
        bodyTop = 238.0; bodyW = 136.0; footY = 364.0
        line = 6.5; eye = 'ink'; eyeR = 17.0; soft = 0.55
        rim = $false; hand = $true; wobble = 4.2
    }
)

# ============================================================
#  스타일에 따라 칠하고 긋는 방식이 달라집니다.
#  hand 안은 물감이 번지고 선이 흔들리고, 나머지는 매끈한 그라디언트입니다.
# ============================================================
function SFill([hashtable]$s, $path, [string]$base, [string]$lit, [string]$shd, [double]$lx, [double]$ly) {
    if ($s.hand) { WaterFill $path $base $shd 9 }
    else {
        FillPath $path $base
        ShadeIn $path $lit $shd $lx $ly
    }
}
function SStroke([hashtable]$s, $path, $pts, [string]$hex, [double]$w, [double]$tension) {
    if ($w -le 0) { return }
    if ($s.hand -and $null -ne $pts) { SketchClosed $pts $hex $w $tension $s.wobble }
    else { StrokePath $path $hex $w }
}
function SCurve([hashtable]$s, $pts, [string]$hex, [double]$w, [double]$tension) {
    if ($s.hand) { SketchOpen $pts $hex $w $tension ($s.wobble * 0.7) }
    else { CurveStroke $pts $hex $w $tension }
}

# ============================================================
#  캐릭터 한 명.  $who: 'dol' 맹돌이 / 'soon' 맹순이
# ============================================================
function Draw-Meng([hashtable]$s, [string]$who, [double]$ox) {
    $isBoy = ($who -eq 'dol')
    $cx = $ox
    $hcy = $s.headCy; $hrx = $s.headRx; $hry = $s.headRy
    $lw = $s.line

    if ($isBoy) { $top = $P.hoodie; $topShd = $P.hoodieShd; $topLit = $P.hoodieLit }
    else { $top = $P.dress; $topShd = $P.dressShd; $topLit = '#FFFDF6' }

    $bw = $s.bodyW; $by0 = $s.bodyTop; $by1 = $s.footY - 26

    GroundShadow $cx ($s.footY + 8) ($bw * 0.86) 22 '#8A6E59' 0.30

    # ---------- 팔 (몸통보다 먼저 = 옆으로 삐져나온 것만 보임) ----------
    foreach ($sd in @(-1, 1)) {
        $ax = $cx + $sd * ($bw * 0.54)
        $ay = $by0 + ($by1 - $by0) * 0.34
        $ap = @(
            (Pt ($ax - $sd * 10) ($ay - 20)),
            (Pt ($ax + $sd * 26) ($ay - 4)),
            (Pt ($ax + $sd * 28) ($ay + 26)),
            (Pt ($ax + $sd * 6) ($ay + 36)),
            (Pt ($ax - $sd * 14) ($ay + 14))
        )
        $arm = BlobPath $ap 0.55
        SFill $s $arm $top $topLit $topShd $ax ($ay - 6)
        SStroke $s $arm $ap $P.line $lw 0.55
        $hp = @(
            (Pt ($ax + $sd * 33) ($ay + 32)), (Pt ($ax + $sd * 17) ($ay + 20)),
            (Pt ($ax + $sd * 1) ($ay + 32)), (Pt ($ax + $sd * 17) ($ay + 46))
        )
        $hand = BlobPath $hp 0.6
        SFill $s $hand $P.skin $P.skinLit $P.skinShd ($ax + $sd * 12) ($ay + 27)
        SStroke $s $hand $hp $P.line $lw 0.6
    }

    # ---------- 다리 + 물갈퀴 발 ----------
    # 위에서 내려다보므로 발은 앞으로 눕혀서 납작한 타원으로 보입니다.
    foreach ($sd in @(-1, 1)) {
        $fx = $cx + $sd * $bw * 0.24
        $lp = @(
            (Pt ($fx - 15) ($by1 - 18)), (Pt ($fx + 15) ($by1 - 18)),
            (Pt ($fx + 15) ($by1 + 20)), (Pt ($fx - 15) ($by1 + 20))
        )
        $leg = RoundRectPath ($fx - 15) ($by1 - 18) 30 36 14
        SFill $s $leg $P.skin $P.skinLit $P.skinShd $fx ($by1 - 10)
        SStroke $s $leg $lp $P.line $lw 0.3
        $fp = @(
            (Pt ($fx - 26) ($s.footY - 12)), (Pt ($fx - 31) ($s.footY + 2)),
            (Pt ($fx - 12) ($s.footY + 12)), (Pt ($fx + 20) ($s.footY + 11)),
            (Pt ($fx + 30) ($s.footY - 2)), (Pt ($fx + 8) ($s.footY - 14))
        )
        $foot = BlobPath $fp 0.5
        FillPath $foot $P.skin
        ShadeTopOnly $foot $P.skinLit ($fx - 6) ($s.footY - 6)
        PushClip $foot
        GroundShadow ($fx + 6) ($s.footY + 14) 26 12 $P.skinShd 0.5
        PopClip
        SStroke $s $foot $fp $P.line $lw 0.5
    }

    # ---------- 몸통 ----------
    $bp = @(
        (Pt ($cx - $bw * 0.36) ($by0 - 4)),
        (Pt ($cx - $bw * 0.50) ($by0 + ($by1 - $by0) * 0.40)),
        (Pt ($cx - $bw * 0.46) ($by1 - 4)),
        (Pt $cx ($by1 + 6)),
        (Pt ($cx + $bw * 0.46) ($by1 - 4)),
        (Pt ($cx + $bw * 0.50) ($by0 + ($by1 - $by0) * 0.40)),
        (Pt ($cx + $bw * 0.36) ($by0 - 4))
    )
    $body = BlobPath $bp 0.5
    FillPath $body $top
    ShadeTopOnly $body $topLit ($cx - $bw * 0.18) ($by0 + 16)
    # 밑단 쪽 그늘 - 몸이 원기둥처럼 두께를 가집니다
    PushClip $body
    GroundShadow ($cx + $bw * 0.10) ($by1 + 6) ($bw * 0.62) 28 $topShd 0.60
    GroundShadow ($cx + $bw * 0.46) (($by0 + $by1) / 2) 20 ($by1 - $by0) $topShd 0.35
    PopClip
    SStroke $s $body $bp $P.line $lw 0.5

    # ---------- 옷 디테일 ----------
    if ($isBoy) {
        PushClip $body
        $pk = BlobPath @(
            (Pt ($cx - $bw * 0.34) ($by1 - 62)), (Pt ($cx - $bw * 0.30) ($by1 - 14)),
            (Pt $cx ($by1 - 4)), (Pt ($cx + $bw * 0.30) ($by1 - 14)),
            (Pt ($cx + $bw * 0.34) ($by1 - 62))
        ) 0.45
        FillPath $pk (CAHex $topShd)
        PopClip
        foreach ($sd in @(-1, 1)) {
            SCurve $s @(
                (Pt ($cx + $sd * 17) ($by0 + 4)),
                (Pt ($cx + $sd * 13) ($by0 + 26)),
                (Pt ($cx + $sd * 18) ($by0 + 46))
            ) $P.white 8 0.5
        }
    }
    else {
        $skp = @(
            (Pt ($cx - $bw * 0.42) ($by1 - 56)), (Pt ($cx - $bw * 0.66) ($by1 - 6)),
            (Pt $cx ($by1 + 8)), (Pt ($cx + $bw * 0.66) ($by1 - 6)),
            (Pt ($cx + $bw * 0.42) ($by1 - 56))
        )
        $sk = BlobPath $skp 0.45
        SFill $s $sk $P.skirt '#F2CDD3' $P.skirtShd ($cx - $bw * 0.2) ($by1 - 44)
        SStroke $s $sk $skp $P.line $lw 0.45
        foreach ($sd in @(-1, 1)) {
            $lp2 = EllipsePath ($cx + $sd * 22) ($by0 + 22) 18 14
            FillPath $lp2 $P.ribbon
            StrokePath $lp2 $P.line ($lw * 0.8)
        }
        $knot = EllipsePath $cx ($by0 + 22) 11 11
        FillPath $knot $P.ribbonShd
        StrokePath $knot $P.line ($lw * 0.8)
    }

    # ---------- 머리 ----------
    # 위의 눈두덩 두 개는 아주 얕게 솟습니다. 골을 깊게 파면 곡선이 튀어서
    # 고양이 귀나 하트처럼 보입니다.
    $hp2 = @(
        (Pt ($cx - $hrx * 0.50) ($hcy - $hry * 0.96)),
        (Pt ($cx - $hrx * 0.86) ($hcy - $hry * 0.62)),
        (Pt ($cx - $hrx * 1.00) ($hcy - $hry * 0.06)),
        (Pt ($cx - $hrx * 0.88) ($hcy + $hry * 0.54)),
        (Pt ($cx - $hrx * 0.48) ($hcy + $hry * 0.94)),
        (Pt $cx ($hcy + $hry * 1.00)),
        (Pt ($cx + $hrx * 0.48) ($hcy + $hry * 0.94)),
        (Pt ($cx + $hrx * 0.88) ($hcy + $hry * 0.54)),
        (Pt ($cx + $hrx * 1.00) ($hcy - $hry * 0.06)),
        (Pt ($cx + $hrx * 0.86) ($hcy - $hry * 0.62)),
        (Pt ($cx + $hrx * 0.50) ($hcy - $hry * 0.96)),
        (Pt $cx ($hcy - $hry * 0.80))
    )
    $head = BlobPath $hp2 $s.soft
    DropShadow $head 0 8 '#6B5344' 0.14 4
    # 얼굴은 빛만 받습니다 (아래 그늘을 넣으면 볼에 때처럼 보입니다)
    FillPath $head $P.skin
    ShadeTopOnly $head $P.skinLit ($cx - $hrx * 0.26) ($hcy - $hry * 0.52)
    # 정수리에 한 겹 더. 머리가 공처럼 둥글게 읽힙니다.
    PushClip $head
    GroundShadow ($cx - $hrx * 0.18) ($hcy - $hry * 0.82) ($hrx * 0.52) ($hry * 0.34) '#DCEFD2' 0.55
    PopClip

    PushClip $head
    # 크림색 턱 - 입선 아래에 낮고 넓게. 너무 크면 턱받이처럼 보입니다.
    FillPath (EllipsePath $cx ($hcy + $hry * 0.92) ($hrx * 0.76) ($hry * 0.42)) $P.cream
    PopClip
    SStroke $s $head $hp2 $P.line $lw $s.soft

    # ---------- 눈 ----------
    $ex = $hrx * 0.48
    # ★ 방을 위에서 내려다보므로 얼굴도 머리의 아래쪽에 붙습니다.
    #   그래야 정수리가 보이고 캐릭터가 같은 시점에 있는 것으로 읽힙니다.
    $ey = $hcy - $hry * 0.30
    $er = $s.eyeR
    foreach ($sd in @(-1, 1)) {
        $px = $cx + $sd * $ex
        switch ($s.eye) {
            'dot' {
                FillPath (EllipsePath $px $ey ($er * 0.94) $er) $P.eye
                FillPath (EllipsePath ($px - $er * 0.30) ($ey - $er * 0.38) ($er * 0.36) ($er * 0.32)) $P.white
            }
            'lid' {
                $e = EllipsePath $px $ey ($er * 0.90) ($er * 1.06)
                FillPath $e $P.white
                StrokePath $e $P.line ($lw * 0.8)
                FillPath (EllipsePath $px ($ey + $er * 0.12) ($er * 0.62) ($er * 0.74)) $P.eyeSoft
                FillPath (EllipsePath ($px - $er * 0.24) ($ey - $er * 0.28) ($er * 0.28) ($er * 0.25)) $P.white
                CurveStroke @(
                    (Pt ($px - $er * 0.98) ($ey - $er * 0.66)),
                    (Pt $px ($ey - $er * 1.00)),
                    (Pt ($px + $er * 0.98) ($ey - $er * 0.66))
                ) $P.line ($lw * 0.95) 0.5
            }
            'almond' {
                $e = BlobPath @(
                    (Pt ($px - $er * 1.02) ($ey + $er * 0.08)),
                    (Pt $px ($ey - $er * 1.00)),
                    (Pt ($px + $er * 1.02) ($ey + $er * 0.08)),
                    (Pt $px ($ey + $er * 0.92))
                ) 0.5
                FillPath $e $P.eye
                FillPath (EllipsePath ($px - $er * 0.28) ($ey - $er * 0.32) ($er * 0.32) ($er * 0.28)) $P.white
            }
            'ink' {
                # 잉크로 콕 찍은 눈. 완벽한 동그라미가 아니라 살짝 일그러집니다.
                $ip = @(
                    (Pt ($px - $er * 1.00) ($ey - $er * 0.10)),
                    (Pt ($px - $er * 0.20) ($ey - $er * 1.05)),
                    (Pt ($px + $er * 0.95) ($ey - $er * 0.15)),
                    (Pt ($px + $er * 0.15) ($ey + $er * 1.00))
                )
                FillPath (BlobPath (JitterPts $ip 1.6) 0.65) $P.eye
                FillPath (EllipsePath ($px - $er * 0.30) ($ey - $er * 0.34) ($er * 0.26) ($er * 0.22)) $P.white
            }
        }
    }

    foreach ($sd in @(-1, 1)) {
        GroundShadow ($cx + $sd * $hrx * 0.70) ($hcy + $hry * 0.36) 26 16 $P.blush 0.78
    }

    # 콧구멍 - 작게. 크면 돼지코처럼 보입니다.
    foreach ($sd in @(-1, 1)) {
        FillPath (EllipsePath ($cx + $sd * 11) ($hcy + $hry * 0.10) 3.2 2.6) $P.lineSoft
    }

    # ---------- 입 ----------
    # 개구리라 입이 얼굴만큼 넓습니다. 이게 정체성의 절반입니다.
    $my = $hcy + $hry * 0.40
    SCurve $s @(
        (Pt ($cx - $hrx * 0.66) ($my - 10)),
        (Pt ($cx - $hrx * 0.34) ($my + 14)),
        (Pt $cx ($my + 20)),
        (Pt ($cx + $hrx * 0.34) ($my + 14)),
        (Pt ($cx + $hrx * 0.66) ($my - 10))
    ) $P.line ([math]::Max(5.0, $lw)) 0.5

    # 맹순이의 앞니 - 정체성이라 네 안 모두 유지합니다.
    # ★ 가운데 경계선은 넣지 않습니다. 한 덩어리로 두는 쪽이 훨씬 귀엽습니다.
    if (-not $isBoy) {
        $ty = $my + 17
        $teeth = RoundRectPath ($cx - 20) $ty 40 27 9
        FillPath $teeth $P.white
        StrokePath $teeth $P.line ([math]::Max(3.0, $lw * 0.8))
    }

    # ---------- 머리 리본 (맹순이) ----------
    if (-not $isBoy) {
        $ry0 = $hcy - $hry * 0.92
        foreach ($sd in @(-1, 1)) {
            $rp = @(
                (Pt ($cx + $sd * 14) $ry0),
                (Pt ($cx + $sd * 44) ($ry0 - 30)),
                (Pt ($cx + $sd * 68) ($ry0 - 6)),
                (Pt ($cx + $sd * 48) ($ry0 + 22)),
                (Pt ($cx + $sd * 16) ($ry0 + 14))
            )
            $lp3 = BlobPath $rp 0.55
            SFill $s $lp3 $P.ribbon '#F4C6CD' $P.ribbonShd ($cx + $sd * 40) ($ry0 - 12)
            SStroke $s $lp3 $rp $P.line $lw 0.55
        }
        $kn = EllipsePath $cx ($ry0 + 5) 17 16
        FillPath $kn $P.ribbonShd
        StrokePath $kn $P.line $lw
    }
}

# 색 문자열을 그대로 돌려줍니다 (가독성용 별칭)
function CAHex([string]$hex) { return $hex }

# ============================================================
function Draw-Concept([hashtable]$s) {
    $W = 720; $H = 470
    HReset 20261020

    # D안은 색조도 다릅니다. 수채화는 안료가 물에 풀리면서 채도가 떨어지므로,
    # 같은 파스텔이라도 한 단계 더 흐리고 흙빛에 가깝게 잡아야 결이 맞습니다.
    $keep = @{}
    if ($s.hand) {
        foreach ($k in @('skin', 'skinLit', 'skinShd', 'cream', 'creamShd', 'hoodie', 'hoodieLit',
                'hoodieShd', 'skirt', 'skirtShd', 'ribbon', 'ribbonShd', 'line', 'lineSoft', 'eye')) {
            $keep[$k] = $P[$k]
        }
        $P.skin = '#9FC79A'; $P.skinLit = '#BFDDB4'; $P.skinShd = '#7EA97F'
        $P.cream = '#F6EBD2'; $P.creamShd = '#E3D2B2'
        $P.hoodie = '#9EB8D4'; $P.hoodieLit = '#BACDE2'; $P.hoodieShd = '#7E9AB8'
        $P.skirt = '#E9AEB8'; $P.skirtShd = '#CE8B9A'
        $P.ribbon = '#E39AA6'; $P.ribbonShd = '#C57887'
        $P.line = '#7A6350'; $P.lineSoft = '#947C66'; $P.eye = '#453A3A'
    }

    New-Soft $W $H
    if ($s.hand) { FillPath (RoundRectPath 0 0 $W $H 0) $P.paperWarm }
    else { FillPath (RoundRectPath 0 0 $W $H 0) $P.paper }
    GroundShadow ($W / 2) ($H * 0.52) ($W * 0.62) ($H * 0.60) $P.paper2 0.9

    Draw-Meng $s 'dol' 224.0
    Draw-Meng $s 'soon' 496.0

    # 종이 결은 맨 마지막에 전체 위로
    if ($s.hand) {
        PaperGrain 16000 '#6B5344' 0.055
        PaperGrain 7000 '#FFFFFF' 0.09
    }

    $sw = @($P.skin, $P.cream, $P.hoodie, $P.skirt, $P.ribbon, $P.creamShd, $P.line)
    $x = $W - 24 - ($sw.Count * 30)
    foreach ($c in $sw) {
        FillPath (RoundRectPath $x ($H - 40) 24 24 8) $c
        StrokePath (RoundRectPath $x ($H - 40) 24 24 8) '#00000022' 2
        $x += 30
    }
    Save-Soft (Join-Path $OutDir ("soft_" + $s.key + ".png"))

    foreach ($k in $keep.Keys) { $P[$k] = $keep[$k] }
}

# $MengLibOnly 가 서 있으면 그리지 않고 함수만 내어 줍니다 (다른 스크립트가 재사용)
if (-not $MengLibOnly) {
Write-Output 'tools/concepts/'
foreach ($s in $STYLES) { Draw-Concept $s }
}
