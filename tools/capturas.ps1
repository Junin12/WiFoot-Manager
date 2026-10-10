# Gera as imagens da Play Store em loja/ com o Chrome headless (versão de nomes fictícios, pasta docs/):
#   capturas de celular 1080x2160 (proporção 2:1, o máximo aceito) e a imagem de destaque 1024x500.
# Requer o servidor local na porta 8765 servindo a pasta do projeto (tools/serve.ps1 ou similar).
param([string]$Root = (Resolve-Path "$PSScriptRoot\.."), [int]$Port = 8765)
$ErrorActionPreference = 'Stop'
$chrome = @("$env:ProgramFiles\Google\Chrome\Application\chrome.exe", "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
  "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
$out = Join-Path $Root 'loja'
New-Item -ItemType Directory -Force $out | Out-Null
function Shot([string]$Url, [string]$File, [int]$W, [int]$H, [double]$Scale, [int]$Budget) {
  $prof = Join-Path ([IO.Path]::GetTempPath()) ("wifoot-cap-" + [guid]::NewGuid())
  $args = @('--headless=new', '--disable-gpu', '--hide-scrollbars', "--user-data-dir=`"$prof`"", "--window-size=$W,$H",
    "--force-device-scale-factor=$Scale", "--virtual-time-budget=$Budget", "--screenshot=`"$File`"", "`"$Url`"")
  Start-Process -FilePath $chrome -ArgumentList $args -Wait -WindowStyle Hidden
  Remove-Item -Recurse -Force $prof -ErrorAction SilentlyContinue
  "$([IO.Path]::GetFileName($File)): $((Get-Item $File).Length) bytes"
}
$n = 1
foreach ($t in 'inicio', 'resumo', 'elenco', 'partida', 'resultado', 'carreira', 'trofeus') {
  Shot "http://localhost:$Port/tools/captura.html?tela=$t" (Join-Path $out ("tela-$n-$t.png")) 1080 2160 1 25000
  $n++
}
Shot "http://localhost:$Port/tools/destaque.html" (Join-Path $out 'destaque-1024x500.png') 1024 500 1 3000
