# ============================================================
#  미니게임 1 「원 투 뿡!」 음악 + 채보 생성기
# ------------------------------------------------------------
#  실행 (프로젝트 폴더에서):
#     powershell -ExecutionPolicy Bypass -File tools\build_bgm.ps1
#
#  결과
#     assets/audio/bgm/one_two_bboong.wav      32초짜리 곡
#     scripts/minigames/one_two_chart.gd       그 곡의 채보 (자동 생성)
#
#  ★ 이 파일 하나가 음악과 채보를 같이 굽습니다.
#    아래 $BARS 표를 고치면 음악의 멜로디와 게임의 노트가 항상 같이 바뀝니다.
#    둘을 따로 관리하면 반드시 어긋납니다.
#
#  ASCII-only comments are NOT required here - this file has a BOM.
# ============================================================

$RATE = 22050
$BPM = 120.0
$SPB = 60.0 / $BPM          # 한 박 = 0.5초
$BARS_TOTAL = 16            # 16마디 x 2초 = 32초

$Root = Split-Path -Parent $PSScriptRoot
$BgmDir = Join-Path $Root 'assets\audio\bgm'
$ChartPath = Join-Path $Root 'scripts\minigames\one_two_chart.gd'
if (-not (Test-Path $BgmDir)) { New-Item -ItemType Directory -Force -Path $BgmDir | Out-Null }

# ------------------------------------------------------------ 채보
#
#  레인: L = 왼쪽 글러브(원, ← 키) · R = 오른쪽 글러브(투, → 키)
#        U = 위 맹순이 얼굴(뿡, 스페이스)
#  숫자는 그 마디 안에서의 박 (0 = 첫 박, 1.5 = 두 번째 박의 뒤쪽 반박)
#
#  0~1 마디는 노트가 없습니다. 여기서 3, 2, 1 카운트다운이 돕니다.
#  난이도 '보통': 대부분 "원 투 뿡" 한 마디에 3~4개이고,
#  ★ 표시한 마디에서 같은 박에 두 개를 같이 눌러야 합니다.
$BARS = @(
    @(),                                                   # 0  카운트다운
    @(),                                                   # 1
    @(@(0.0, 'L'), @(1.0, 'R'), @(2.0, 'U')),              # 2  원 투 뿡
    @(@(0.0, 'L'), @(1.0, 'R'), @(2.0, 'U')),              # 3
    @(@(0.0, 'L'), @(1.0, 'R'), @(2.0, 'U'), @(3.0, 'U')), # 4  뿡 두 번
    @(@(0.0, 'L'), @(1.0, 'R'), @(2.0, 'L'), @(3.0, 'R')), # 5  원 투 원 투
    @(@(0.0, 'L'), @(0.0, 'R'), @(2.0, 'U')),              # 6  ★ 양손 동시
    @(@(0.0, 'L'), @(1.0, 'R'), @(2.0, 'U')),              # 7
    @(@(0.0, 'L'), @(0.5, 'L'), @(1.0, 'R'), @(1.5, 'R'),
        @(2.5, 'U')),                                      # 8  원원 투투 ..뿡
    @(@(0.0, 'L'), @(0.0, 'R'), @(1.0, 'U'), @(2.0, 'L'),
        @(2.0, 'R'), @(3.0, 'U')),                         # 9  ★
    @(@(0.0, 'L'), @(1.0, 'R'), @(2.0, 'U'), @(3.0, 'U')), # 10
    @(@(0.0, 'L'), @(0.5, 'R'), @(1.5, 'U'), @(2.0, 'L'),
        @(2.5, 'R'), @(3.5, 'U')),                         # 11 8분음표
    @(@(0.0, 'L'), @(0.0, 'U'), @(1.5, 'R'), @(2.0, 'R'),
        @(2.0, 'U'), @(3.0, 'L')),                         # 12 ★ 글러브+얼굴 동시
    @(@(0.0, 'L'), @(1.0, 'R'), @(2.0, 'U'), @(3.0, 'U')), # 13
    @(@(0.0, 'L'), @(0.0, 'R'), @(1.0, 'U'), @(2.0, 'L'),
        @(2.0, 'R'), @(3.0, 'U')),                         # 14 ★
    @(@(0.0, 'L'), @(0.0, 'R'), @(1.0, 'U'), @(2.0, 'U'),
        @(3.0, 'L'), @(3.0, 'R'))                          # 15 ★ 마무리
)

# 절대 박으로 펴 둡니다 (0박 = 곡의 맨 앞)
$NOTES = @()
for ($b = 0; $b -lt $BARS.Count; $b++) {
    foreach ($n in $BARS[$b]) {
        $NOTES += , @(($b * 4.0 + [double]$n[0]), [string]$n[1])
    }
}
$NOTES = $NOTES | Sort-Object { $_[0] }

# ------------------------------------------------------------ 신디사이저

$script:seed = 987654321
function Noise {
    $script:seed = ($script:seed * 1103515245 + 12345) % 2147483648
    return ($script:seed / 1073741824.0) - 1.0
}

$TOTAL = [int]($BARS_TOTAL * 4 * $SPB * $RATE)
$mix = New-Object double[] $TOTAL

# 소리 하나를 $atBeat 위치에 더합니다.
function Add-Event([double[]]$buf, [double]$atBeat) {
    $off = [int]($atBeat * $SPB * $RATE)
    for ($i = 0; $i -lt $buf.Length; $i++) {
        $j = $off + $i
        if ($j -ge 0 -and $j -lt $TOTAL) { $mix[$j] += $buf[$i] }
    }
}

function New-Kick([double]$gain) {
    $n = [int]($RATE * 0.13)
    $out = New-Object double[] $n
    $ph = 0.0
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / [double]$n
        $ph += (58.0 - 22.0 * $t) / $RATE
        $out[$i] = [math]::Sin(2 * [math]::PI * $ph) * [math]::Exp(-6.0 * $t) * $gain
    }
    return $out
}

function New-Snare([double]$gain) {
    $n = [int]($RATE * 0.12)
    $out = New-Object double[] $n
    $ph = 0.0
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / [double]$n
        $ph += 185.0 / $RATE
        $body = [math]::Sin(2 * [math]::PI * $ph) * 0.35
        $out[$i] = ((Noise) * 0.65 + $body) * [math]::Exp(-13.0 * $t) * $gain
    }
    return $out
}

function New-Hat([double]$gain) {
    $n = [int]($RATE * 0.035)
    $out = New-Object double[] $n
    $lp = 0.0
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / [double]$n
        $s = Noise
        $lp = $lp + 0.6 * ($s - $lp)
        $out[$i] = ($s - $lp) * [math]::Exp(-30.0 * $t) * $gain    # 하이패스 = 원본 - 저역
    }
    return $out
}

# 둥글둥글한 베이스 (삼각파에 가깝게)
function New-Bass([double]$freq, [double]$beats, [double]$gain) {
    $n = [int]($RATE * $beats * $SPB)
    $out = New-Object double[] $n
    $ph = 0.0
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / [double]$n
        $ph += $freq / $RATE
        $p = $ph % 1.0
        $tri = 4.0 * [math]::Abs($p - 0.5) - 1.0
        $env = [math]::Min(1.0, $i / 200.0) * [math]::Exp(-2.2 * $t)
        $out[$i] = ($tri * 0.6 + [math]::Sin(2 * [math]::PI * $ph) * 0.4) * $env * $gain
    }
    return $out
}

# 멜로디 한 음. 노트가 있는 자리마다 이게 울리므로, 눈을 감고 소리만
# 들어도 원-투-뿡 박자가 그대로 들립니다. (리듬천국식 "귀로 치는" 설계)
function New-Lead([double]$freq, [double]$ms, [double]$gain) {
    $n = [int]($RATE * $ms / 1000.0)
    $out = New-Object double[] $n
    $ph = 0.0
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / [double]$n
        $ph += $freq / $RATE
        $p = $ph % 1.0
        $sq = if ($p -lt 0.42) { 1.0 } else { -1.0 }
        $env = [math]::Min(1.0, $i / 90.0) * [math]::Exp(-4.5 * $t)
        $out[$i] = ($sq * 0.35 + [math]::Sin(2 * [math]::PI * $ph) * 0.65) * $env * $gain
    }
    return $out
}

# 뿡 자리에 들어가는 짧은 방귀 톤 (효과음보다 훨씬 얌전하게)
function New-Toot([double]$ms, [double]$gain) {
    $n = [int]($RATE * $ms / 1000.0)
    $out = New-Object double[] $n
    $ph = 0.0
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / [double]$n
        $f = 300.0 - 150.0 * $t
        $f *= 1.0 + 0.18 * [math]::Sin(2 * [math]::PI * 9.0 * $t)
        $ph += $f / $RATE
        $p = $ph % 1.0
        $saw = 2.0 * $p - 1.0
        $env = [math]::Min(1.0, $i / 60.0) * [math]::Exp(-4.0 * $t)
        $out[$i] = $saw * $env * $gain
    }
    return $out
}

Write-Output ("BPM {0}  {1}마디  {2}초  노트 {3}개" -f $BPM, $BARS_TOTAL, ($BARS_TOTAL * 4 * $SPB), $NOTES.Count)

# ---- 드럼 + 베이스
$kick = New-Kick 0.55
$snare = New-Snare 0.30
$hat = New-Hat 0.13
# Am - F - C - G, 두 마디씩
$ROOTS = @(110.00, 87.31, 130.81, 98.00)
for ($bar = 0; $bar -lt $BARS_TOTAL; $bar++) {
    $b0 = $bar * 4.0
    Add-Event $kick $b0
    Add-Event $kick ($b0 + 2.0)
    Add-Event $kick ($b0 + 2.75)
    Add-Event $snare ($b0 + 1.0)
    Add-Event $snare ($b0 + 3.0)
    for ($h = 0; $h -lt 8; $h++) { Add-Event $hat ($b0 + $h * 0.5) }

    $root = $ROOTS[[int]([math]::Floor($bar / 2.0)) % 4]
    $bass = New-Bass $root 0.9 0.34
    $bass5 = New-Bass ($root * 1.5) 0.9 0.28
    Add-Event $bass $b0
    Add-Event $bass ($b0 + 1.0)
    Add-Event $bass5 ($b0 + 2.0)
    Add-Event $bass ($b0 + 3.0)
}

# ---- 멜로디 = 채보. 원은 낮게, 투는 한 음 위, 뿡은 방귀 톤.
$leadL = New-Lead 523.25 200 0.30       # C5  "원"
$leadR = New-Lead 659.25 200 0.30       # E5  "투"
$toot = New-Toot 240 0.26               #     "뿡"
foreach ($n in $NOTES) {
    switch ($n[1]) {
        'L' { Add-Event $leadL $n[0] }
        'R' { Add-Event $leadR $n[0] }
        'U' { Add-Event $toot $n[0] }
    }
}

# ---- 마지막 한 마디는 서서히 줄입니다 (뚝 끊기면 놀랍니다)
$fadeFrom = [int](($BARS_TOTAL * 4 - 1.0) * $SPB * $RATE)
for ($i = $fadeFrom; $i -lt $TOTAL; $i++) {
    $mix[$i] *= 1.0 - (($i - $fadeFrom) / [double]($TOTAL - $fadeFrom))
}

# ---- 클리핑 방지: 제일 큰 값에 맞춰 한 번에 줄입니다
$peak = 0.0
for ($i = 0; $i -lt $TOTAL; $i++) { if ([math]::Abs($mix[$i]) -gt $peak) { $peak = [math]::Abs($mix[$i]) } }
$norm = if ($peak -gt 0.0) { 0.88 / $peak } else { 1.0 }
Write-Output ("  peak {0:N3} -> x{1:N3}" -f $peak, $norm)

# ------------------------------------------------------------ 저장
$path = Join-Path $BgmDir 'one_two_bboong.wav'
$fs = [System.IO.File]::Create($path)
$bw = New-Object System.IO.BinaryWriter($fs)
$bw.Write([char[]]'RIFF'); $bw.Write([int](36 + $TOTAL * 2)); $bw.Write([char[]]'WAVE')
$bw.Write([char[]]'fmt '); $bw.Write([int]16); $bw.Write([int16]1); $bw.Write([int16]1)
$bw.Write([int]$RATE); $bw.Write([int]($RATE * 2)); $bw.Write([int16]2); $bw.Write([int16]16)
$bw.Write([char[]]'data'); $bw.Write([int]($TOTAL * 2))
for ($i = 0; $i -lt $TOTAL; $i++) {
    $v = [int][math]::Round($mix[$i] * $norm * 32000)
    if ($v -gt 32767) { $v = 32767 }
    if ($v -lt -32768) { $v = -32768 }
    $bw.Write([int16]$v)
}
$bw.Close(); $fs.Close()
Write-Output ("  {0}  {1:N0} KB" -f 'assets/audio/bgm/one_two_bboong.wav', ((Get-Item $path).Length / 1024))

# ------------------------------------------------------------ 채보를 GDScript 로
$LANE = @{ 'L' = 0; 'U' = 1; 'R' = 2 }
$lines = @()
$lines += '## 자동 생성 파일입니다. 직접 고치지 마세요.'
$lines += '## tools/build_bgm.ps1 이 음악(one_two_bboong.wav)과 이 채보를 같이 굽습니다.'
$lines += '## 채보를 바꾸려면 그 파일의 $BARS 표를 고치고 다시 실행하세요.'
$lines += 'extends RefCounted'
$lines += ''
$lines += ('const BPM := {0:0.0}' -f $BPM)
$lines += ('const BARS := {0}' -f $BARS_TOTAL)
$lines += ('const LENGTH := {0:0.000}' -f ($BARS_TOTAL * 4 * $SPB))
$lines += ''
$lines += '## 레인 번호. 화면 배치와 같은 순서입니다.'
$lines += 'const LEFT := 0    ## 왼쪽 - 복싱 글러브 - "원"'
$lines += 'const UP := 1      ## 위   - 맹순이 얼굴 - "뿡"'
$lines += 'const RIGHT := 2   ## 오른쪽 - 복싱 글러브 - "투"'
$lines += ''
$lines += '## [박, 레인] 목록. 박은 곡 맨 앞에서부터 센 절대 박입니다.'
$lines += 'const NOTES := ['
foreach ($n in $NOTES) {
    $lines += ("`t[{0:N2}, {1}]," -f $n[0], $LANE[[string]$n[1]])
}
$lines += ']'
# BOM 없는 UTF-8 로 씁니다 (Set-Content -Encoding UTF8 은 BOM 을 붙입니다)
[System.IO.File]::WriteAllLines($ChartPath, $lines, (New-Object System.Text.UTF8Encoding($false)))
Write-Output ("  {0}  ({1} notes)" -f 'scripts/minigames/one_two_chart.gd', $NOTES.Count)
