# Elle kurulum ve neyin değiştiği

Betiği çalıştırmak istemezsen aynı şeyi elle yapabilirsin. Betiğin dokunduğu her şey burada.

## 1. Anahtar

<https://abacus.ai/app/profile/apikey> adresinden RouteLLM API anahtarını al.

Doğrulamak için (Windows PowerShell; `ANAHTAR` yerine kendi anahtarın):

```powershell
$h = @{ Authorization = 'Bearer ANAHTAR'; 'anthropic-version' = '2023-06-01' }
Invoke-RestMethod https://routellm.abacus.ai/v1/messages -Method POST -Headers $h -ContentType 'application/json' `
  -Body '{"model":"claude-haiku-5-5","max_tokens":1,"messages":[{"role":"user","content":"hi"}]}'
```

Yanlış anahtar `403` döner ("User not logged in").

## 2. Çalıştırma (en kısa yol)

Claude Code iki ortam değişkeniyle Abacus'a bağlanır:

| Değişken | Değer |
|---|---|
| `ANTHROPIC_BASE_URL` | `https://routellm.abacus.ai` |
| `ANTHROPIC_AUTH_TOKEN` | Abacus anahtarın |

Claude Code adresin sonuna `/v1/messages` ekler, bu yüzden adrese `/v1` yazma.

Model adları: `ANTHROPIC_MODEL`, `ANTHROPIC_DEFAULT_OPUS_MODEL`, `ANTHROPIC_DEFAULT_SONNET_MODEL`, `ANTHROPIC_DEFAULT_HAIKU_MODEL`, `CLAUDE_CODE_SUBAGENT_MODEL`. Geçerli adlar: <https://routellm.abacus.ai/v1/models> (herkese açık, anahtar istemez).

## 3. Betiğin yazdığı dosyalar

| Dosya (Windows) | Ne |
|---|---|
| `%USERPROFILE%\.config\abacus\abacus.anahtar` | DPAPI ile şifreli anahtar |
| `%USERPROFILE%\.config\abacus\anahtar-oku.ps1` | Anahtarı çözüp çağırana veren yardımcı |
| `%USERPROFILE%\.config\abacus\bin\claude-abacus.cmd` | Başlatıcı (ortam değişkenlerini ayarlar, `claude` çağırır) |
| `%USERPROFILE%\.claude-abacus\settings.json` | `/model` menüsü (`modelPicker`) |
| Kullanıcı PATH'i | `...\.config\abacus\bin` eklenir |

macOS/Linux'ta aynı yapı `~/.config/abacus/` altında; anahtar Keychain ya da secret-tool'da, `~/.bashrc` ya da `~/.zshrc`'ye `# >>> claude-abacus >>>` işaretli tek bir PATH bloğu eklenir.

`claude-abacus` ayrı bir ayar klasörü kullanır: `CLAUDE_CONFIG_DIR=~/.claude-abacus`. Böylece normal `claude`'un oturum geçmişi, ayarları ve hesabı karışmaz.

## 4. `/model` menüsü nasıl çalışıyor

Claude Code v2.1.242 ve üstünde ayar dosyasına `modelPicker` yazılabilir. Her satırın `model` alanı olduğu gibi gönderilir, bu yüzden Abacus'un Claude dışı model adları da (`gpt-6.1-sol`, `moonshotai/Kimi-K2.7-Code` vb.) çalışır:

```json
{
  "modelPicker": {
    "options": [
      { "model": "gpt-6.1-sol", "label": "GPT-6.1 Sol", "description": "Abacus RouteLLM" }
    ]
  }
}
```

Satırlar yerleşik listenin altına eklenir. `availableModels` bunun yerine bir kısıtlamadır ve Claude dışı adları satır olarak eklemez; o yüzden kullanılmadı.

## 5. Geri almak

`kaldir.ps1` / `kaldir.sh` yukarıdaki dosyaları siler, `modelPicker` anahtarını kaldırır, PATH'i temizler. `settings.json`'un yedekleri (`*.abacus-yedek-*`) ve oturum geçmişi kalır.
