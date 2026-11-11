# Claude Abacus Kurulumu

[Abacus AI](https://abacus.ai) hesabındaki **RouteLLM** anahtarıyla **Claude Code**'u çalıştırır. Tek komut kurar: `claude-abacus`. Normal `claude` komutun değişmez.

Anahtarın hiçbir ayar dosyasına düz yazı olarak girmez. Windows'ta DPAPI ile şifreli dosyada, macOS'ta Keychain'de, Linux'ta secret-tool'da (yoksa izni 600 olan dosyada) durur.

## Neden proxy gerekmiyor

Abacus'un RouteLLM ucu Anthropic formatını (`/v1/messages`) doğrudan konuşuyor. Claude Code'a yalnız adres ve anahtar vermek yetiyor.

## Kurulum

Önce [Claude Code](https://code.claude.com) kurulu olmalı, ve Abacus'tan bir API anahtarı almalısın: <https://abacus.ai/app/profile/apikey>

### Windows (PowerShell)

```powershell
git clone https://github.com/KULLANICI/claude-abacus-kurulum.git
cd claude-abacus-kurulum
copy .env.example .env
notepad .env
powershell -ExecutionPolicy Bypass -File .\kur.ps1
```

`.env` oluşturmak istemezsen betiği doğrudan çalıştır, anahtarı gizli olarak sorar.

### macOS ve Linux

```bash
git clone https://github.com/KULLANICI/claude-abacus-kurulum.git
cd claude-abacus-kurulum
cp .env.example .env
```

`.env` dosyasına anahtarını yapıştır, sonra:

```bash
./kur.sh
```

> `kur.sh` henüz bir macOS ya da Linux makinesinde denenmedi; yalnız Windows betiği (`kur.ps1`) denendi. Sorun çıkarsa issue aç.

## Betik ne yapar

1. Anahtarı Abacus'a sorup doğrular (1 tokenlik istek; yanlış anahtarı kaydetmez).
2. Güvenli depoya koyar, geri okuyarak kontrol eder, `.env`'deki değeri siler.
3. `claude-abacus` komutunu yazar ve PATH'e ekler.
4. Abacus'un herkese açık model listesini çekip `/model` menüsüne sohbet modellerini ekler (`~/.claude-abacus/settings.json`, mevcut dosyanın yedeğini alır).
5. Küçük bir deneme çağrısı atar.

Bittiğinde yeni bir terminal aç:

```bash
claude-abacus
```

İçinde `/model` yazınca Claude'lar, GPT, Gemini, Grok, Kimi, GLM, DeepSeek vb. görünür. Listede olmayan bir modeli `claude-abacus --model <id>` ile açabilirsin; adlar <https://routellm.abacus.ai/v1/models> adresinde.

Kaldırmak için: `./kaldir.sh` (Windows: `powershell -ExecutionPolicy Bypass -File .\kaldir.ps1`)

## Varsayılan modeller

| Rol | Model |
|---|---|
| Ana / Sonnet | `claude-sonnet-5-5` |
| Opus | `claude-opus-5-5` |
| Haiku | `claude-haiku-5-5` |
| Ek seçenek | `route-llm-code` (Abacus kodlama yönlendirici) |

Değiştirmek için `~/.config/abacus/bin/claude-abacus` (Windows: `claude-abacus.cmd`) dosyasındaki `ANTHROPIC_*MODEL` satırlarını düzenle.

## Kredi ve limit

Kullanım Abacus kredinden düşer; ChatLLM aboneliğinde aylık 20.000 kredi gelir (tahmini 10 $ dolayında API değeri). Claude Code her istekte yaklaşık 21.000 token sistem istemi gönderir, bu yüzden tek bir kısa komut bile birkaç sent tutabilir. Kredi sayacı panelde en fazla bir saat gecikmeli güncellenir. Kesin oran ve limitler için Abacus'un kendi sayfasına bak.

## Kullanmadan önce

- **İzin istemlerini kapatma.** Claude Code'a bilgisayarına erişim veriyorsun. Bu betik `--dangerously-skip-permissions` eklemez.
- **Claude dışı modeller** (GPT, Gemini, Kimi vb.) Claude Code'un araç çağırma biçiminde bazen sorun çıkarabilir. Claude modelleri en güvenlisi. Claude Code, tanımadığı model adlarında bağlam penceresini 200K varsayar ve bunu bir uyarı olarak yazar.
- Yazdığın her şey (promptlar, açtığın dosyalar) Abacus'a gider. Hassas projelerde kullanma.

## Bir agent'a kurdurmak

Bu repoyu Claude Code ile açıp "bunu kur" diyebilirsin; talimat [AGENTS.md](AGENTS.md)'de. Anahtarı agent'a söyleme.

## Destek

| Sistem | Betik | Anahtar deposu | Gerekenler |
|---|---|---|---|
| Windows | `kur.ps1` | DPAPI ile şifreli dosya | PowerShell 5.1 ya da 7, Claude Code |
| macOS | `kur.sh` | Keychain | `bash`, `curl`, `python3`, Claude Code |
| Linux | `kur.sh` | secret-tool (yoksa dosya, izin 600) | `bash`, `curl`, `python3`, Claude Code |

Bu repo Abacus AI ya da Anthropic ile bağlantılı değildir.

Lisans: MIT
