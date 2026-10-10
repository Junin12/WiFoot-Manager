# Gera os ícones PNG do app instalável (docs/icon-192.png, icon-512.png e versão "maskable")
param([string]$Out)
Add-Type -AssemblyName System.Drawing
function Icon([int]$S, [string]$File, [double]$Pad) {
  $bmp = New-Object System.Drawing.Bitmap $S, $S
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = 'AntiAliasGridFit'
  $rect = New-Object System.Drawing.Rectangle 0, 0, $S, $S
  $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, ([System.Drawing.Color]::FromArgb(31,138,76)), ([System.Drawing.Color]::FromArgb(20,107,57)), 45
  $g.FillRectangle($bg, $rect)
  # faixas de gramado
  $stripe = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(22,255,255,255))
  for ($x = 0; $x -lt $S; $x += [int]($S / 4)) { $g.FillRectangle($stripe, $x, 0, [int]($S / 8), $S) }
  # bola
  $r = $S * (0.5 - $Pad) * 0.62; $cx = $S / 2; $cy = $S * 0.43
  $g.FillEllipse([System.Drawing.Brushes]::White, [float]($cx - $r), [float]($cy - $r), [float](2 * $r), [float](2 * $r))
  $pts = 0..4 | ForEach-Object { $a = -[Math]::PI / 2 + $_ * 2 * [Math]::PI / 5; New-Object System.Drawing.PointF ([float]($cx + 0.42 * $r * [Math]::Cos($a))), ([float]($cy + 0.42 * $r * [Math]::Sin($a))) }
  $dark = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(20,38,26))
  $g.FillPolygon($dark, [System.Drawing.PointF[]]$pts)
  $pen = New-Object System.Drawing.Pen $dark, ([float]($S * 0.012))
  foreach ($p in $pts) { $dx = $p.X - $cx; $dy = $p.Y - $cy; $g.DrawLine($pen, $p, (New-Object System.Drawing.PointF ([float]($cx + $dx * 2.35)), ([float]($cy + $dy * 2.35)))) }
  # nome
  $font = New-Object System.Drawing.Font 'Segoe UI', ([float]($S * (0.5 - $Pad) * 0.30)), ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
  $fmt = New-Object System.Drawing.StringFormat; $fmt.Alignment = 'Center'
  $g.DrawString('WiFoot', $font, ([System.Drawing.Brushes]::White), [float]$cx, [float]($cy + $r * 1.12), $fmt)
  $bmp.Save($File, [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
}
Icon 192 "$Out\icon-192.png" 0.06
Icon 512 "$Out\icon-512.png" 0.06
Icon 512 "$Out\icon-maskable-512.png" 0.16
Get-ChildItem "$Out\*.png" | ForEach-Object { "$($_.Name): $($_.Length) bytes" }
