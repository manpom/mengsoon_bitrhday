param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [int]$Padding = 128
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$resolvedPath = (Resolve-Path -LiteralPath $Path).Path
$source = [System.Drawing.Bitmap]::FromFile($resolvedPath)
try {
    $output = [System.Drawing.Bitmap]::new(
        $source.Width + ($Padding * 2),
        $source.Height + ($Padding * 2),
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )
    try {
        $graphics = [System.Drawing.Graphics]::FromImage($output)
        try {
            $graphics.Clear([System.Drawing.Color]::Transparent)
            $graphics.DrawImageUnscaled($source, $Padding, $Padding)
        }
        finally { $graphics.Dispose() }
        $temporaryPath = "$resolvedPath.padded.png"
        $output.Save($temporaryPath, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally { $output.Dispose() }
}
finally { $source.Dispose() }

Move-Item -LiteralPath "$resolvedPath.padded.png" -Destination $resolvedPath -Force
Write-Output "Added ${Padding}px transparent padding to $resolvedPath"

