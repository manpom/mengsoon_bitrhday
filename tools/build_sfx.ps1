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

# 방귀. 낮은 톱니파를 부르르 떨게 만들고(피치 흔들기) 잡음을 섞습니다.
# $sputter 를 올리면 더 요란하게 부르르 떨립니다.
function New-Fart([double]$ms, [double]$f0, [double]$f1, [double]$sputter, [double]$gain) {
    $n = [int]($RATE * $ms / 1000.0)
    $out = New-Object double[] $n
    $phase = 0.0
    $lp = 0.0
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / [double]$n
        # 음이 아래로 미끄러지면서 부르르 떨린다
        $f = $f0 + ($f1 - $f0) * $t
        $f *= 1.0 + 0.22 * [math]::Sin(2 * [math]::PI * $sputter * $t)
        $phase += $f / $RATE
        $p = $phase % 1.0
        $saw = 2.0 * $p - 1.0
        if ($p -lt 0.32) { $sq = 1.0 } else { $sq = -1.0 }
        $lp = $lp + 0.22 * ((Noise) - $lp)          # 바람 소리
        $env = [math]::Min(1.0, $i / 50.0) * [math]::Exp(-2.4 * $t)
        $amp = 0.72 + 0.28 * [math]::Sin(2 * [math]::PI * ($sputter * 2.6) * $t)
        $out[$i] = ($saw * 0.5 + $sq * 0.32 + $lp * 0.4) * $env * $amp * $gain
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

Write-Output 'assets/audio/sfx/'
Save-Wav 'type'  (New-Blip 1180 42 0.30 0.42)
# 리듬용 메트로놈 "똑" - 원/투 를 세는 소리
Save-Wav 'tick'  (New-Blip 2100 28 0.45 0.30)
Save-Wav 'tock'  (New-Blip 1500 32 0.40 0.28)
# 뿡! 세 종류 (컷신용 큰 것 + 미니게임에서 돌려 쓸 두 종류)
Save-Wav 'bboong'  (New-Fart 620 105 62 7.0 0.85)
Save-Wav 'bboong2' (New-Fart 380 130 78 9.0 0.70)
Save-Wav 'bboong3' (New-Fart 260 155 95 12.0 0.62)
Save-Wav 'ding'  (New-Ding 1320 260 0.45)
Save-Wav 'step1' (New-Step 105 0.32 150 0.55)
Save-Wav 'step2' (New-Step 95 0.26 128 0.50)
Save-Wav 'bump'  (New-Step 150 0.14 92 0.70)
