# ============================================================
#  Key out the flat magenta (#FF00FF) background from the GPT
#  reference images in tools/ai_refs/_gpt_raw/<who>_<expr>.png and
#  write clean transparent PNGs (feathered, de-spilled edges) to
#  tools/ai_refs/<who>/clean/face_<expr>.png
# ------------------------------------------------------------
#     powershell -ExecutionPolicy Bypass -File tools\clean_ai_refs.ps1
#
#  Why magenta + our own flood fill (not ChatGPT's "remove background"):
#    ChatGPT's "remove background" re-generates and re-crops the image,
#    so the careful full-body framing is lost. Keying a flat colour
#    ourselves keeps the exact framing. Flood fill starts from the
#    border, so interior pink dress / coral cheeks are never touched.
#    "magenta-ness" is a channel test (high R, high B, low G), robust
#    to the slight gradient ChatGPT bakes into the fill.
#
#  The heavy per-pixel work runs as compiled C# (Add-Type); PowerShell
#  loops over ~1.5M pixels are far too slow and mis-round integer math.
# ============================================================

Add-Type -AssemblyName System.Drawing

Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;

public static class MagentaKey
{
    // in/out: BGRA bytes, length = w*h*4. Modifies in place.
    public static void Process(byte[] px, int w, int h)
    {
        int n = w * h;
        double[] mag = new double[n];
        for (int i = 0; i < n; i++)
        {
            int o = i * 4;
            int b = px[o], g = px[o + 1], r = px[o + 2];
            int minRB = b < r ? b : r;
            double m = (minRB - g) / 110.0;
            if (m < 0) m = 0; else if (m > 1) m = 1;
            mag[i] = m;
        }

        // Flood fill the connected background region (m > 0.35) from every border pixel.
        bool[] isBg = new bool[n];
        int[] q = new int[n];
        int qh = 0, qt = 0;
        Action<int> seed = idx => { if (!isBg[idx] && mag[idx] > 0.35) { isBg[idx] = true; q[qt++] = idx; } };
        for (int x = 0; x < w; x++) { seed(x); seed((h - 1) * w + x); }
        for (int y = 0; y < h; y++) { seed(y * w); seed(y * w + w - 1); }
        while (qh < qt)
        {
            int idx = q[qh++];
            int cx = idx % w, cy = idx / w;
            if (cx + 1 < w) { int ni = idx + 1;  if (!isBg[ni] && mag[ni] > 0.35) { isBg[ni] = true; q[qt++] = ni; } }
            if (cx - 1 >= 0) { int ni = idx - 1;  if (!isBg[ni] && mag[ni] > 0.35) { isBg[ni] = true; q[qt++] = ni; } }
            if (cy + 1 < h) { int ni = idx + w;  if (!isBg[ni] && mag[ni] > 0.35) { isBg[ni] = true; q[qt++] = ni; } }
            if (cy - 1 >= 0) { int ni = idx - w;  if (!isBg[ni] && mag[ni] > 0.35) { isBg[ni] = true; q[qt++] = ni; } }
        }

        // Background -> alpha 0. Kept pixels with a magenta cast get de-spilled
        // (pull R,B toward G) and a partial alpha so the cut edge is soft.
        for (int i = 0; i < n; i++)
        {
            int o = i * 4;
            if (isBg[i]) { px[o] = 0; px[o + 1] = 0; px[o + 2] = 0; px[o + 3] = 0; continue; }
            double m = mag[i];
            if (m > 0.06)
            {
                int b = px[o], g = px[o + 1], r = px[o + 2];
                double k = m * 0.75;
                int nr = (int)(r - (r - g) * k);
                int nb = (int)(b - (b - g) * k);
                if (nr < 0) nr = 0; else if (nr > 255) nr = 255;
                if (nb < 0) nb = 0; else if (nb > 255) nb = 255;
                px[o] = (byte)nb;
                px[o + 2] = (byte)nr;
                double a = 1.0 - ((m - 0.06) / 0.94);
                if (a < 0) a = 0;
                int av = (int)(px[o + 3] * a);
                if (av < 0) av = 0; else if (av > 255) av = 255;
                px[o + 3] = (byte)av;
            }
        }

        // Keep only the largest 8-connected blob of alpha>16 pixels.
        bool[] vis = new bool[n];
        int[] stack = new int[n];
        List<int> best = null; int bestSize = 0;
        for (int i = 0; i < n; i++)
        {
            if (vis[i] || px[i * 4 + 3] <= 16) continue;
            int sp = 0; stack[sp++] = i; vis[i] = true;
            List<int> comp = new List<int>();
            while (sp > 0)
            {
                int cur = stack[--sp]; comp.Add(cur);
                int cx = cur % w, cy = cur / w;
                for (int dy = -1; dy <= 1; dy++)
                for (int dx = -1; dx <= 1; dx++)
                {
                    if (dx == 0 && dy == 0) continue;
                    int nx = cx + dx, ny = cy + dy;
                    if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
                    int ni = ny * w + nx;
                    if (!vis[ni] && px[ni * 4 + 3] > 16) { vis[ni] = true; stack[sp++] = ni; }
                }
            }
            if (comp.Count > bestSize) { bestSize = comp.Count; best = comp; }
        }
        if (best != null)
        {
            bool[] keep = new bool[n];
            foreach (int idx in best) keep[idx] = true;
            for (int i = 0; i < n; i++) if (!keep[i]) px[i * 4 + 3] = 0;
        }
    }
}
"@ -ReferencedAssemblies System.Drawing

$Root = Split-Path -Parent $PSScriptRoot
$RawDir = Join-Path $Root 'tools\ai_refs\_gpt_raw'
$OutRefDir = Join-Path $Root 'tools\ai_refs'

function Clean-One([string]$srcPath, [string]$dstPath) {
    $src = [System.Drawing.Bitmap]::FromFile($srcPath)
    $w = $src.Width; $h = $src.Height
    $bmp = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $gg = [System.Drawing.Graphics]::FromImage($bmp)
    $gg.DrawImage($src, 0, 0, $w, $h)
    $gg.Dispose(); $src.Dispose()

    $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
    $bd = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadWrite, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $len = [Math]::Abs($bd.Stride) * $h
    $buf = New-Object byte[] $len
    [System.Runtime.InteropServices.Marshal]::Copy($bd.Scan0, $buf, 0, $len)

    [MagentaKey]::Process($buf, $w, $h)

    [System.Runtime.InteropServices.Marshal]::Copy($buf, 0, $bd.Scan0, $len)
    $bmp.UnlockBits($bd)

    $dstDir = Split-Path -Parent $dstPath
    if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Force -Path $dstDir | Out-Null }
    $bmp.Save($dstPath, [System.Drawing.Imaging.ImageFormat]::Png)

    # report alpha bbox
    $r2 = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
    $bd2 = $bmp.LockBits($r2, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $buf2 = New-Object byte[] $len
    [System.Runtime.InteropServices.Marshal]::Copy($bd2.Scan0, $buf2, 0, $len)
    $bmp.UnlockBits($bd2)
    $st = [Math]::Abs($bd2.Stride)
    $mnx = 99999; $mxx = -1; $mny = 99999; $mxy = -1
    for ($y = 0; $y -lt $h; $y++) {
        for ($x = 0; $x -lt $w; $x++) {
            if ($buf2[$y * $st + $x * 4 + 3] -gt 20) {
                if ($x -lt $mnx) { $mnx = $x }; if ($x -gt $mxx) { $mxx = $x }
                if ($y -lt $mny) { $mny = $y }; if ($y -gt $mxy) { $mxy = $y }
            }
        }
    }
    $bmp.Dispose()
    Write-Output ("  {0,-26} {1}x{2}  char {3}x{4}  margin T{5} B{6} L{7} R{8}" -f (Split-Path -Leaf $dstPath), $w, $h, ($mxx - $mnx), ($mxy - $mny), $mny, ($h - 1 - $mxy), $mnx, ($w - 1 - $mxx))
}

Write-Output 'GPT magenta refs -> clean transparent PNG -> clean/'
foreach ($who in 'mengdol', 'mengsoon') {
    Write-Output $who
    # 표정: clean/face_<expr>.png
    foreach ($expr in 'happy', 'surprise', 'sad', 'angry', 'sleepy', 'shy', 'laugh') {
        $src = Join-Path $RawDir ("${who}_${expr}.png")
        if (-not (Test-Path $src)) { Write-Output "  (missing: ${who}_${expr}.png)"; continue }
        $dst = Join-Path $OutRefDir ("$who\clean\face_$expr.png")
        Clean-One $src $dst
    }
    # 이동(앞/뒤 서기·걷기): clean/<pose>.png  (integrate_ai_moves.ps1 이 씀)
    foreach ($pose in 'down_idle', 'down_walk', 'up_idle', 'up_walk') {
        $src = Join-Path $RawDir ("${who}_${pose}.png")
        if (-not (Test-Path $src)) { Write-Output "  (missing: ${who}_${pose}.png)"; continue }
        $dst = Join-Path $OutRefDir ("$who\clean\$pose.png")
        Clean-One $src $dst
    }
    # 나체 세트(욕실 컷신·리듬): clean/nude_<pose>.png  (integrate_ai_nude.ps1 이 씀)
    foreach ($pose in 'nude_stand', 'nude_guard', 'nude_punch1', 'nude_punch2', 'nude_surprise',
        'nude_shy', 'nude_laugh', 'nude_lol', 'nude_lol_punch1', 'nude_lol_punch2', 'nude_lol_fart') {
        $src = Join-Path $RawDir ("${who}_${pose}.png")
        if (-not (Test-Path $src)) { continue }
        $dst = Join-Path $OutRefDir ("$who\clean\$pose.png")
        Clean-One $src $dst
    }
}
Write-Output 'done'
