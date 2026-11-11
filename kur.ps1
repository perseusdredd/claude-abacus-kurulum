# Claude Code'u Abacus AI (RouteLLM) anahtarina baglar ve `claude-abacus` komutunu kurar.
# Kullanim: powershell -ExecutionPolicy Bypass -File .\kur.ps1
# Anahtari .env dosyasindan (ABACUS_API_KEY=) ya da ortam degiskeninden okur; yoksa gizli sorar.
# Not: dosya bilerek ASCII; Windows PowerShell 5.1 BOM'suz UTF-8'i yanlis okur.
param(
  [switch]$PathEklemeden,   # kullanici PATH'ine dokunma
  [switch]$DenemeAtlama     # sonda deneme cagrisi atma
)
$ErrorActionPreference = 'Stop'
$Taban = 'https://routellm.abacus.ai'
$Dizin = Join-Path $HOME '.config\abacus'
$Bin = Join-Path $Dizin 'bin'
$AyarDizin = Join-Path $HOME '.claude-abacus'
$Utf8 = New-Object Text.UTF8Encoding $false

function Tamam($t) { Write-Host "  [OK] $t" -ForegroundColor Green }
function Bilgi($t) { Write-Host "  $t" }
function Hata($t) { Write-Host "  [HATA] $t" -ForegroundColor Red; exit 1 }

# 0. Claude Code kurulu mu
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
  Hata 'claude komutu bulunamadi. Once Claude Code kur: https://code.claude.com'
}

# 1. Anahtari al: ortam degiskeni > .env > gizli soru
$anahtar = $env:ABACUS_API_KEY
$envDosya = Join-Path $PSScriptRoot '.env'
if (-not $anahtar -and (Test-Path $envDosya)) {
  foreach ($satir in Get-Content $envDosya) {
    if ($satir -match '^\s*ABACUS_API_KEY\s*=\s*(.+?)\s*$') { $anahtar = $Matches[1].Trim('"', "'") }
  }
}
if (-not $anahtar) {
  $s = Read-Host 'Abacus RouteLLM API anahtarini yapistir (gorunmez)' -AsSecureString
  $b = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($s)
  try { $anahtar = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($b) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b) }
}
if (-not $anahtar) { Hata 'Anahtar bos.' }

# 2. Anahtari Abacus'a sorup dogrula (1 tokenlik istek; yanlis anahtari kaydetmez)
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
$govde = '{"model":"claude-haiku-5-5","max_tokens":1,"messages":[{"role":"user","content":"hi"}]}'
# PowerShell 5.1 ile 7 ikisinde de calisir: HTTP hata kodunu istisnadan okur
try {
  $r = Invoke-WebRequest -Uri "$Taban/v1/messages" -Method POST -Body $govde -ContentType 'application/json' -UseBasicParsing `
    -Headers @{ Authorization = "Bearer $anahtar"; 'anthropic-version' = '2023-06-01' } -TimeoutSec 40
  $kod = [int]$r.StatusCode
} catch {
  if ($_.Exception.Response) { $kod = [int]$_.Exception.Response.StatusCode } else { Hata "Abacus'a ulasilamadi: $($_.Exception.Message)" }
}
if ($kod -in 401, 403) { Hata "Anahtar reddedildi ($kod). abacus.ai/app/profile/apikey sayfasindan yenisini al." }
if ($kod -ne 200) { Hata "Beklenmeyen yanit: $kod" }
Tamam 'Anahtar gecerli'

# 3. Sifreli sakla (DPAPI: yalniz bu Windows hesabi cozer), geri okuyup kontrol et
New-Item -ItemType Directory -Force $Dizin, $Bin, $AyarDizin | Out-Null
$anahtarDosya = Join-Path $Dizin 'abacus.anahtar'
ConvertTo-SecureString $anahtar -AsPlainText -Force | ConvertFrom-SecureString | Set-Content -Path $anahtarDosya -Encoding ascii
$oku = @'
# Anahtari ekrana degil, cagiran programa verir (DPAPI).
$f = Join-Path $HOME ".config\abacus\abacus.anahtar"
if (-not (Test-Path $f)) { exit 1 }
$sec = Get-Content $f | ConvertTo-SecureString
$b = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
try { [Runtime.InteropServices.Marshal]::PtrToStringBSTR($b) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b) }
'@
[IO.File]::WriteAllText((Join-Path $Dizin 'anahtar-oku.ps1'), $oku, $Utf8)
$geri = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Dizin 'anahtar-oku.ps1')
if ("$geri".Trim() -ne $anahtar) { Hata 'Sifreli anahtar geri okunamadi.' }
Tamam "Anahtar sifreli saklandi: $anahtarDosya"
# .env'deki degeri sil
if (Test-Path $envDosya) { [IO.File]::WriteAllText($envDosya, "ABACUS_API_KEY=`r`n", $Utf8); Tamam '.env icindeki anahtar silindi' }

# 4. claude-abacus.cmd
$cmd = @'
@echo off
setlocal
set "ANTHROPIC_BASE_URL=https://routellm.abacus.ai"
set "_PSMP=%PSModulePath%"
set "PSModulePath="
set "ANTHROPIC_AUTH_TOKEN="
for /f "usebackq delims=" %%k in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\.config\abacus\anahtar-oku.ps1"`) do set "ANTHROPIC_AUTH_TOKEN=%%k"
set "PSModulePath=%_PSMP%"
if not defined ANTHROPIC_AUTH_TOKEN (
  echo Abacus anahtari bulunamadi. kur.ps1'i yeniden calistir.
  exit /b 1
)
set "ANTHROPIC_MODEL=claude-sonnet-5-5"
set "ANTHROPIC_DEFAULT_OPUS_MODEL=claude-opus-5-5"
set "ANTHROPIC_DEFAULT_SONNET_MODEL=claude-sonnet-5-5"
set "ANTHROPIC_DEFAULT_HAIKU_MODEL=claude-haiku-5-5"
set "CLAUDE_CODE_SUBAGENT_MODEL=claude-sonnet-5-5"
set "ANTHROPIC_CUSTOM_MODEL_OPTION=route-llm-code"
set "ANTHROPIC_CUSTOM_MODEL_OPTION_NAME=RouteLLM (Code)"
set "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1"
set "CLAUDE_CONFIG_DIR=%USERPROFILE%\.claude-abacus"
call claude --allow-dangerously-skip-permissions %*
'@
[IO.File]::WriteAllText((Join-Path $Bin 'claude-abacus.cmd'), ($cmd -replace "`r?`n", "`r`n"), [Text.Encoding]::ASCII)
Tamam "Komut yazildi: $Bin\claude-abacus.cmd"

# 5. /model menusu: Abacus'un model listesinden sohbet modellerini ekle
try {
  $liste = (Invoke-RestMethod "$Taban/v1/models" -TimeoutSec 40).data
  $sohbet = '^(claude-|gpt-[0-9]|gemini-[0-9]|grok-|route-llm|moonshotai/|zai-org/|deepseek-ai/|Qwen/|qwen|MiniMaxAI/|mimo-|muse-spark|openai/gpt-oss|google/gemma|jev-|thinkingmachines/|abacusai/)'
  $dislanan = 'transcribe|realtime|audio|tts|image|banana'
  $hazirSatir = '^(claude-opus-5-5|claude-sonnet-5-5|claude-haiku-5-5|claude-fable-5-2|route-llm-code)$'
  $satirlar = @($liste | Where-Object { $_.id -match $sohbet -and $_.id -notmatch $dislanan -and $_.id -notmatch $hazirSatir } | ForEach-Object {
      $ad = if ($_.display_name) { $_.display_name } else { $_.id }
      [ordered]@{ model = $_.id; label = "$ad"; description = 'Abacus RouteLLM' }
    })
  $ayarDosya = Join-Path $AyarDizin 'settings.json'
  $ayar = [pscustomobject]@{}
  if (Test-Path $ayarDosya) {
    Copy-Item $ayarDosya "$ayarDosya.abacus-yedek-$(Get-Date -Format yyyyMMddHHmmss)"
    try { $ayar = Get-Content $ayarDosya -Raw | ConvertFrom-Json } catch { Bilgi 'settings.json okunamadi, yedegi alindi; yenisi yaziliyor.' }
  }
  $ayar | Add-Member -NotePropertyName modelPicker -NotePropertyValue ([ordered]@{ options = $satirlar }) -Force
  [IO.File]::WriteAllText($ayarDosya, ($ayar | ConvertTo-Json -Depth 10), $Utf8)
  Tamam "/model menusune $($satirlar.Count) model eklendi"
} catch { Bilgi "Model listesi eklenemedi ($($_.Exception.Message)); komut yine de calisir." }

# 6. PATH
if (-not $PathEklemeden) {
  $yol = [Environment]::GetEnvironmentVariable('Path', 'User')
  if (-not (($yol -split ';') -contains $Bin)) {
    [Environment]::SetEnvironmentVariable('Path', ($yol.TrimEnd(';') + ';' + $Bin), 'User')
    Tamam "PATH'e eklendi: $Bin"
  } else { Tamam 'PATH zaten ekli' }
}

# 7. Deneme cagrisi
if (-not $DenemeAtlama) {
  Bilgi 'Deneme cagrisi atiliyor (kucuk bir kredi harcar)...'
  $cikti = & (Join-Path $Bin 'claude-abacus.cmd') -p 'Sadece tek kelime yaz: tamam' 2>&1
  if ("$cikti".Trim()) { Tamam "claude-abacus cevap verdi: $("$cikti".Trim())" } else { Hata 'claude-abacus bos cevap verdi.' }
}

Write-Host ''
Write-Host '  Bitti. Yeni bir terminal ac ve su komutu yaz: claude-abacus' -ForegroundColor Cyan
Write-Host '  Normal `claude` komutun degismedi.'
