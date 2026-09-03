# ============================================================
#  Sound effect generator
# ------------------------------------------------------------
#  Writes 16-bit mono PCM .wav files from scratch - no samples,
#  no downloads, no licensing to worry about.
#
#  Run (from the project folder):
#     powershell -ExecutionPolicy Bypass -File tools\build_sfx.ps1
#
#  Output -> assets/audio/sfx/
#     type.wav    the blip while dialogue letters appear
#     step1.wav   footstep A
#     step2.wav   footstep B (slightly different, so walking is not a metronome)
#     bump.wav    a soft thud, for later (walking into a wall)
#
#  ASCII-only comments on purpose: PS 5.1 reads BOM-less UTF-8 as ANSI and a
#  mis-decoded byte can act as a line continuation, swallowing the next line.
# ============================================================

$RATE = 22050

$Root = Split-Path -Parent $PSScriptRoot
$OutDir = Join-Path $Root 'assets\audio\sfx'
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Force -Path $OutDir | Out-Null }

# deterministic pseudo-noise, so re-running gives byte-identical files
$script:seed = 12345
function Noise {
    $script:seed = ($script:seed * 1103515245 + 12345) % 2147483648
    return ($script:seed / 1073741824.0) - 1.0
}

function Save-Wav([string]$name, [double[]]$samples) {
    $path = Join-Path $OutDir ($name + '.wav')
    $n = $samples.Count
    $fs = [System.IO.File]::Create($path)
    $bw = New-Object System.IO.BinaryWriter($fs)
    $bw.Write([char[]]'RIFF')
    $bw.Write([int](36 + $n * 2))
    $bw.Write([char[]]'WAVE')
    $bw.Write([char[]]'fmt ')
    $bw.Write([int]16)
    $bw.Write([int16]1)              # 1 = PCM
    $bw.Write([int16]1)              # mono
    $bw.Write([int]$RATE)
    $bw.Write([int]($RATE * 2))      # byte rate
    $bw.Write([int16]2)              # block align
    $bw.Write([int16]16)             # bits per sample
    $bw.Write([char[]]'data')
    $bw.Write([int]($n * 2))
    foreach ($s in $samples) {
        $v = [int][math]::Round($s * 32000)
        if ($v -gt 32767) { $v = 32767 }
        if ($v -lt -32768) { $v = -32768 }
        $bw.Write([int16]$v)
    }
    $bw.Close(); $fs.Close()
    Write-Output ("  {0,-10} {1,5} samples  {2:N0} ms" -f ($name + '.wav'), $n, ($n * 1000.0 / $RATE))
}

# a short square-wave blip that drops in pitch as it fades - reads as "tok"
function New-Blip([double]$freq, [double]$ms, [double]$drop, [double]$gain) {
    $n = [int]($RATE * $ms / 1000.0)
    $out = New-Object double[] $n
    $phase = 0.0
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / [double]$n
        $f = $freq * (1.0 - $drop * $t)
        $phase += $f / $RATE
        # square wave, softened by mixing in the sine so it is not harsh
        $sq = if (($phase % 1.0) -lt 0.5) { 1.0 } else { -1.0 }
        $sn = [math]::Sin(2 * [math]::PI * $phase)
        $env = [math]::Exp(-5.0 * $t) * [math]::Min(1.0, $i / 40.0)
        $out[$i] = ($sq * 0.45 + $sn * 0.55) * $env * $gain
    }
    return $out
}

# filtered noise burst - reads as a soft footstep on a wooden floor
function New-Step([double]$ms, [double]$cutoff, [double]$body, [double]$gain) {
    $n = [int]($RATE * $ms / 1000.0)
    $out = New-Object double[] $n
    $lp = 0.0
    $a = $cutoff        # 0..1, lower = duller
    $phase = 0.0
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / [double]$n
        $lp = $lp + $a * ((Noise) - $lp)
        # a little low sine underneath gives the step some weight
        $phase += ($body * (1.0 - 0.5 * $t)) / $RATE
        $thump = [math]::Sin(2 * [math]::PI * $phase) * [math]::Exp(-14.0 * $t)
        $env = [math]::Exp(-11.0 * $t) * [math]::Min(1.0, $i / 25.0)
        $out[$i] = ($lp * 0.75 * $env) + ($thump * 0.5)
        $out[$i] *= $gain
    }
    return $out
}

# 방귀.
#
# 예전 것은 "낮은 톱니파를 규칙적으로 흔든" 소리라 부저처럼 들렸습니다.
# 진짜 방귀에 가깝게 만드는 건 이 네 가지입니다.
#   1. 기본 주파수가 훨씬 낮습니다 (80~180Hz). 사람 목소리보다 아래입니다.
#   2. 떨림이 규칙적이지 않습니다. 사인파 하나가 아니라 서로 안 맞는
#      진동 두 개를 겹치고 랜덤 워크를 얹어 불규칙하게 만듭니다.
#   3. 소리가 끊겼다 이어집니다(부르르). 진폭을 0 가까이 떨어뜨렸다 올립니다.
#   4. 저역만 남긴 잡음("바람")이 항상 깔려 있고, 끝에서 pffft 하고 빠집니다.
function New-Fart([double]$ms, [double]$f0, [double]$f1, [double]$sputter, [double]$gain) {
    $n = [int]($RATE * $ms / 1000.0)
    $out = New-Object double[] $n
    $phase = 0.0
    $lp = 0.0
    $lp2 = 0.0
    $drift = 0.0
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / [double]$n

        # -- 1) 아래로 미끄러지는 기본음
        $f = $f0 + ($f1 - $f0) * $t

        # -- 2) 서로 안 맞는 떨림 두 개 + 느린 랜덤 워크 = 불규칙한 부르르
        $drift = $drift * 0.995 + (Noise) * 0.02
        $f *= 1.0 + 0.30 * [math]::Sin(2 * [math]::PI * $sputter * $t) `
            + 0.17 * [math]::Sin(2 * [math]::PI * $sputter * 1.61 * $t + 1.3) `
            + 0.22 * $drift
        if ($f -lt 40.0) { $f = 40.0 }
        $phase += $f / $RATE

        # -- 톱니 + 좁은 펄스. 펄스 폭이 흔들려서 배음이 계속 바뀝니다.
        $p = $phase % 1.0
        $saw = 2.0 * $p - 1.0
        $duty = 0.30 + 0.16 * [math]::Sin(2 * [math]::PI * $sputter * 0.7 * $t)
        if ($p -lt $duty) { $sq = 1.0 } else { $sq = -1.0 }

        # -- 4) 바람. 저역만 두 번 걸러서 "쉬-" 가 아니라 "푸-" 로 만듭니다.
        $lp = $lp + 0.16 * ((Noise) - $lp)
        $lp2 = $lp2 + 0.30 * ($lp - $lp2)

        # -- 3) 끊겼다 이어지는 진폭. 0 가까이 떨어지는 순간이 '부르르' 입니다.
        $gate = 0.55 + 0.45 * [math]::Sin(2 * [math]::PI * ($sputter * 2.3) * $t + 0.7)
        $gate *= 0.70 + 0.30 * [math]::Sin(2 * [math]::PI * ($sputter * 3.7) * $t)
        if ($gate -lt 0.0) { $gate = 0.0 }

        $env = [math]::Min(1.0, $i / 90.0) * [math]::Exp(-2.1 * $t)
        $tail = [math]::Exp(-3.5 * $t)          # 끝의 pffft 는 바람만 남습니다
        $out[$i] = (($saw * 0.42 + $sq * 0.30) * $tail + $lp2 * 1.15) * $env * $gate * $gain
    }
    return $out
}
# 딩! 하는 짧은 종소리 (판정 성공 / 강조)
function New-Ding([double]$freq, [double]$ms, [double]$gain) {
    $n = [int]($RATE * $ms / 1000.0)
    $out = New-Object double[] $n
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / [double]$n
        $env = [math]::Exp(-6.0 * $t) * [math]::Min(1.0, $i / 30.0)
        $out[$i] = ([math]::Sin(2 * [math]::PI * $freq * $i / $RATE) * 0.6 +
            [math]::Sin(2 * [math]::PI * $freq * 1.5 * $i / $RATE) * 0.4) * $env * $gain
    }
    return $out
}

# 빗나감. 낮은 사각파 두 음이 아래로 떨어지는 "삐-빅"
function New-Miss([double]$gain) {
    $n = [int]($RATE * 0.20)
    $out = New-Object double[] $n
    $phase = 0.0
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / [double]$n
        $f = if ($t -lt 0.45) { 300.0 } else { 190.0 }
        $phase += $f / $RATE
        $sq = if (($phase % 1.0) -lt 0.5) { 1.0 } else { -1.0 }
        $env = [math]::Exp(-2.2 * $t) * [math]::Min(1.0, $i / 40.0)
        $out[$i] = $sq * $env * $gain
    }
    return $out
}

Write-Output 'assets/audio/sfx/'
Save-Wav 'type'  (New-Blip 1180 42 0.30 0.42)
# 리듬용 메트로놈 "똑" - 원/투 를 세는 소리
Save-Wav 'tick'  (New-Blip 2100 28 0.45 0.30)
Save-Wav 'tock'  (New-Blip 1500 32 0.40 0.28)
# 뿡! 세 종류 (컷신용 큰 것 + 미니게임에서 돌려 쓸 두 종류)
Save-Wav 'bboong'  (New-Fart 700 148 74 5.2 0.95)
Save-Wav 'bboong2' (New-Fart 420 168 92 7.5 0.85)
Save-Wav 'bboong3' (New-Fart 300 132 80 10.0 0.78)
Save-Wav 'ding'  (New-Ding 1320 260 0.45)
Save-Wav 'step1' (New-Step 105 0.32 150 0.55)
Save-Wav 'step2' (New-Step 95 0.26 128 0.50)
Save-Wav 'bump'  (New-Step 150 0.14 92 0.70)
Save-Wav 'miss'  (New-Miss 0.40)
# 리듬 파트 판정음: 세 단계로 점점 밝아집니다
Save-Wav 'hit_cool'  (New-Ding 880 150 0.34)
Save-Wav 'hit_good'  (New-Ding 1180 180 0.40)
Save-Wav 'hit_great' (New-Ding 1660 230 0.46)
