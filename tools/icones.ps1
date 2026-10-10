# Gera os ícones PNG do app instalável a partir de tools/icone.svg (desenho original do WiFoot),
# usando o Chrome em modo headless: docs/icon-192.png, icon-512.png e icon-maskable-512.png
param([string]$Out)
$ErrorActionPreference = 'Stop'
$chrome = @("$env:ProgramFiles\Google\Chrome\Application\chrome.exe", "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
  "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $chrome) { throw 'Chrome não encontrado' }
$svg = Get-Content -Raw -Encoding UTF8 (Join-Path $PSScriptRoot 'icone.svg')
$tmp = Join-Path ([IO.Path]::GetTempPath()) 'wifoot-icone'
New-Item -ItemType Directory -Force $tmp | Out-Null
function Render([int]$S, [string]$File, [bool]$Mask) {
  # maskable: fundo cheio (sem cantos arredondados) e o escudo reduzido para caber na área segura
  $body = if ($Mask) {
    $inner = $svg -replace 'rx="116"', 'rx="0"' -replace '(<!-- escudo com sombra -->)', '<g transform="translate(256 262) scale(.78) translate(-256 -262)">$1' -replace '</svg>', '</g></svg>'
    $inner
  } else { $svg }
  $html = "<!doctype html><html><head><meta charset='utf-8'><style>html,body{margin:0;background:transparent}svg{display:block;width:${S}px;height:${S}px}</style></head><body>$body</body></html>"
  $page = Join-Path $tmp "i$S$Mask.html"
  [IO.File]::WriteAllText($page, $html, [Text.UTF8Encoding]::new($false))
  # perfil temporário: não mexe no Chrome que estiver aberto
  $args = @('--headless=new', '--disable-gpu', '--hide-scrollbars', '--default-background-color=00000000', "--user-data-dir=$tmp\perfil",
    "--window-size=$S,$S", "--screenshot=`"$File`"", "`"file:///$($page -replace '\\','/')`"") # aspas: caminhos com espaço
  Start-Process -FilePath $chrome -ArgumentList $args -Wait -WindowStyle Hidden
  "$([IO.Path]::GetFileName($File)): $((Get-Item $File).Length) bytes"
}
Render 192 (Join-Path $Out 'icon-192.png') $false
Render 512 (Join-Path $Out 'icon-512.png') $false
Render 512 (Join-Path $Out 'icon-maskable-512.png') $true
