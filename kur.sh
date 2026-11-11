#!/usr/bin/env bash
# Claude Code'u Abacus AI (RouteLLM) anahtarina baglar ve `claude-abacus` komutunu kurar.
# Kullanim: ./kur.sh   (anahtari .env'den ya da ABACUS_API_KEY ortam degiskeninden okur; yoksa gizli sorar)
set -euo pipefail

TABAN="https://routellm.abacus.ai"
DIZIN="$HOME/.config/abacus"
BIN="$DIZIN/bin"
AYAR_DIZIN="$HOME/.claude-abacus"
BLOK_BAS="# >>> claude-abacus >>>"
BLOK_SON="# <<< claude-abacus <<<"
BETIK_DIZIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

tamam() { printf '  \033[32m[OK]\033[0m %s\n' "$1"; }
bilgi() { printf '  %s\n' "$1"; }
hata()  { printf '  \033[31m[HATA]\033[0m %s\n' "$1" >&2; exit 1; }

command -v claude >/dev/null 2>&1 || hata "claude komutu bulunamadi. Once Claude Code kur: https://code.claude.com"
command -v curl >/dev/null 2>&1 || hata "curl gerekli."
command -v python3 >/dev/null 2>&1 || hata "python3 gerekli."

# 1. Anahtar: ortam degiskeni > .env > gizli soru
ANAHTAR="${ABACUS_API_KEY:-}"
if [ -z "$ANAHTAR" ] && [ -f "$BETIK_DIZIN/.env" ]; then
  ANAHTAR="$(sed -n 's/^[[:space:]]*ABACUS_API_KEY[[:space:]]*=[[:space:]]*//p' "$BETIK_DIZIN/.env" | tr -d '"'"'"' \r' | head -n1)"
fi
if [ -z "$ANAHTAR" ]; then
  printf 'Abacus RouteLLM API anahtarini yapistir (gorunmez): '
  read -rs ANAHTAR; echo
fi
[ -n "$ANAHTAR" ] || hata "Anahtar bos."

# 2. Dogrula (1 tokenlik istek)
KOD="$(curl -s -o /dev/null -w '%{http_code}' --max-time 40 -X POST "$TABAN/v1/messages" \
  -H "Authorization: Bearer $ANAHTAR" -H 'anthropic-version: 2023-06-01' -H 'content-type: application/json' \
  -d '{"model":"claude-haiku-5-5","max_tokens":1,"messages":[{"role":"user","content":"hi"}]}' || echo 000)"
case "$KOD" in
  200) tamam "Anahtar gecerli" ;;
  401|403) hata "Anahtar reddedildi ($KOD). abacus.ai/app/profile/apikey sayfasindan yenisini al." ;;
  000) hata "Abacus'a ulasilamadi." ;;
  *) hata "Beklenmeyen yanit: $KOD" ;;
esac

# 3. Sakla: macOS Keychain > secret-tool > dosya (izin 600)
mkdir -p "$BIN" "$AYAR_DIZIN"
chmod 700 "$DIZIN"
if [ "$(uname)" = "Darwin" ]; then
  security add-generic-password -U -s claude-abacus -a abacus -w "$ANAHTAR"
  DEPO="macOS Keychain"
elif command -v secret-tool >/dev/null 2>&1 && printf '%s' "$ANAHTAR" | secret-tool store --label='claude-abacus' service claude-abacus 2>/dev/null; then
  DEPO="secret-tool"
else
  ( umask 177; printf '%s' "$ANAHTAR" > "$DIZIN/abacus.anahtar" )
  DEPO="dosya ($DIZIN/abacus.anahtar, izin 600)"
fi
cat > "$DIZIN/anahtar-oku.sh" <<'EOF'
#!/usr/bin/env bash
if [ "$(uname)" = "Darwin" ]; then
  security find-generic-password -s claude-abacus -a abacus -w 2>/dev/null
elif command -v secret-tool >/dev/null 2>&1 && secret-tool lookup service claude-abacus 2>/dev/null; then
  :
else
  cat "$HOME/.config/abacus/abacus.anahtar" 2>/dev/null
fi
EOF
chmod 700 "$DIZIN/anahtar-oku.sh"
[ "$("$DIZIN/anahtar-oku.sh")" = "$ANAHTAR" ] || hata "Saklanan anahtar geri okunamadi."
tamam "Anahtar saklandi: $DEPO"
[ -f "$BETIK_DIZIN/.env" ] && printf 'ABACUS_API_KEY=\n' > "$BETIK_DIZIN/.env" && tamam ".env icindeki anahtar silindi"

# 4. claude-abacus
cat > "$BIN/claude-abacus" <<'EOF'
#!/usr/bin/env bash
export ANTHROPIC_BASE_URL="https://routellm.abacus.ai"
ANTHROPIC_AUTH_TOKEN="$("$HOME/.config/abacus/anahtar-oku.sh")"
[ -n "$ANTHROPIC_AUTH_TOKEN" ] || { echo "Abacus anahtari bulunamadi. kur.sh'i yeniden calistir." >&2; exit 1; }
export ANTHROPIC_AUTH_TOKEN
export ANTHROPIC_MODEL="claude-sonnet-5-5"
export ANTHROPIC_DEFAULT_OPUS_MODEL="claude-opus-5-5"
export ANTHROPIC_DEFAULT_SONNET_MODEL="claude-sonnet-5-5"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="claude-haiku-5-5"
export CLAUDE_CODE_SUBAGENT_MODEL="claude-sonnet-5-5"
export ANTHROPIC_CUSTOM_MODEL_OPTION="route-llm-code"
export ANTHROPIC_CUSTOM_MODEL_OPTION_NAME="RouteLLM (Code)"
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
export CLAUDE_CONFIG_DIR="$HOME/.claude-abacus"
exec claude --allow-dangerously-skip-permissions "$@"
EOF
chmod 755 "$BIN/claude-abacus"
tamam "Komut yazildi: $BIN/claude-abacus"

# 5. /model menusu
if python3 - "$TABAN" "$AYAR_DIZIN/settings.json" <<'PY'
import json, re, sys, shutil, time, os, urllib.request
taban, dosya = sys.argv[1], sys.argv[2]
liste = json.load(urllib.request.urlopen(taban + "/v1/models", timeout=40))["data"]
sohbet = re.compile(r"^(claude-|gpt-[0-9]|gemini-[0-9]|grok-|route-llm|moonshotai/|zai-org/|deepseek-ai/|Qwen/|qwen|MiniMaxAI/|mimo-|muse-spark|openai/gpt-oss|google/gemma|jev-|thinkingmachines/|abacusai/)")
disla = re.compile(r"transcribe|realtime|audio|tts|image|banana")
hazir = re.compile(r"^(claude-opus-5-5|claude-sonnet-5-5|claude-haiku-5-5|claude-fable-5-2|route-llm-code)$")
satirlar = [{"model": m["id"], "label": m.get("display_name") or m["id"], "description": "Abacus RouteLLM"}
            for m in liste if sohbet.match(m["id"]) and not disla.search(m["id"]) and not hazir.match(m["id"])]
ayar = {}
if os.path.exists(dosya):
    shutil.copy(dosya, dosya + ".abacus-yedek-" + time.strftime("%Y%m%d%H%M%S"))
    try: ayar = json.load(open(dosya))
    except Exception: ayar = {}
ayar["modelPicker"] = {"options": satirlar}
json.dump(ayar, open(dosya, "w"), indent=2, ensure_ascii=False)
print(len(satirlar))
PY
then tamam "/model menusune model eklendi"; else bilgi "Model listesi eklenemedi; komut yine de calisir."; fi

# 6. PATH (tek satirlik blok)
RC="$HOME/.bashrc"; [ -n "${ZSH_VERSION:-}" ] || [ "${SHELL##*/}" = "zsh" ] && RC="$HOME/.zshrc"
if ! grep -qF "$BLOK_BAS" "$RC" 2>/dev/null; then
  printf '\n%s\nexport PATH="$HOME/.config/abacus/bin:$PATH"\n%s\n' "$BLOK_BAS" "$BLOK_SON" >> "$RC"
  tamam "PATH eklendi: $RC"
else tamam "PATH zaten ekli"; fi

# 7. Deneme
bilgi "Deneme cagrisi atiliyor (kucuk bir kredi harcar)..."
CIKTI="$("$BIN/claude-abacus" -p 'Sadece tek kelime yaz: tamam' 2>&1 || true)"
[ -n "$CIKTI" ] && tamam "claude-abacus cevap verdi: $CIKTI" || hata "claude-abacus bos cevap verdi."
printf '\n  Bitti. Yeni bir terminal ac ve su komutu yaz: claude-abacus\n'
