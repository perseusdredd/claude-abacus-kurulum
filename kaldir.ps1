# kur.ps1'in yaptigi her seyi geri alir. Yedek dosyalara dokunmaz.
# Kullanim: powershell -ExecutionPolicy Bypass -File .\kaldir.ps1
$ErrorActionPreference = 'Stop'
$Dizin = Join-Path $HOME '.config\abacus'
$Bin = Join-Path $Dizin 'bin'
$Ayar = Join-Path $HOME '.claude-abacus\settings.json'
function Tamam($t) { Write-Host "  [OK] $t" -ForegroundColor Green }

# /model menusu ayari
if (Test-Path $Ayar) {
  try {
    $j = Get-Content $Ayar -Raw | ConvertFrom-Json
    if ($j.PSObject.Properties.Name -contains 'modelPicker') {
      $j.PSObject.Properties.Remove('modelPicker')
      [IO.File]::WriteAllText($Ayar, ($j | ConvertTo-Json -Depth 10), (New-Object Text.UTF8Encoding $false))
      Tamam 'settings.json: modelPicker silindi'
    }
  } catch { Write-Host '  settings.json JSON degil, elle kontrol et' }
}

# PATH
$yol = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($yol) {
  $yeni = (($yol -split ';') | Where-Object { $_ -and $_ -ne $Bin }) -join ';'
  if ($yeni -ne $yol) { [Environment]::SetEnvironmentVariable('Path', $yeni, 'User'); Tamam "PATH'ten $Bin cikarildi" }
}

if (Test-Path $Dizin) { Remove-Item -Recurse -Force $Dizin; Tamam "$Dizin silindi (sifreli anahtar dahil)" }
Write-Host '       Oturum gecmisi %USERPROFILE%\.claude-abacus icinde kalir; istersen elle sil.'
Write-Host '       Abacus anahtarini istersen abacus.ai/app/profile/apikey sayfasindan iptal et.'
Write-Host '       Yeni bir terminal ac.'
