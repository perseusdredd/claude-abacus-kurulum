# Agent talimatı: claude-abacus kurulumu

Kullanıcı "bunu kur" derse:

1. Anahtarı **sen isteme, sohbete yazdırma**. Kullanıcıya şunu söyle: `.env.example`'ı `.env` olarak kopyalayıp `ABACUS_API_KEY=` satırına anahtarını kendisi yapıştırsın, ya da betiği kendi terminalinde çalıştırsın (gizli sorar).
2. Windows'ta: `powershell -ExecutionPolicy Bypass -File .\kur.ps1`. macOS/Linux'ta: `./kur.sh`.
3. Betik anahtarı doğrulayamazsa (`403`) durur; kullanıcıya <https://abacus.ai/app/profile/apikey> sayfasından yeni anahtar almasını söyle.
4. Bittiğinde kullanıcıdan yeni bir terminal açıp `claude-abacus` yazmasını iste.

Kurallar:

- Anahtarı hiçbir dosyaya, komut satırına ya da çıktıya yazma. Betik onu şifreli depoya taşır.
- `--dangerously-skip-permissions` (modu baştan açar) ekleme. Başlatıcıdaki `--allow-dangerously-skip-permissions` bilerek var: bypass modunu yalnız Shift+Tab döngüsüne koyar, açmaz.
- `kur.ps1` dosyası bilerek ASCII; Türkçe karakter ekleme (Windows PowerShell 5.1 BOM'suz UTF-8'i yanlış okur).
- Normal `claude` komutuna ve `~/.claude` klasörüne dokunma. Her şey `~/.claude-abacus` ve `~/.config/abacus` altında kalır.
