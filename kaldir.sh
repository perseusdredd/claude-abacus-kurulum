#!/usr/bin/env bash
# kur.sh'in yaptigi her seyi geri alir. Yedek dosyalara dokunmaz.
set -uo pipefail
DIZIN="$HOME/.config/abacus"
AYAR="$HOME/.claude-abacus/settings.json"
tamam() { printf '  \033[32m[OK]\033[0m %s\n' "$1"; }

if [ -f "$AYAR" ] && command -v python3 >/dev/null 2>&1; then
  python3 - "$AYAR" <<'PY' && tamam "settings.json: modelPicker silindi"
import json, sys
d = json.load(open(sys.argv[1])); d.pop("modelPicker", None)
json.dump(d, open(sys.argv[1], "w"), indent=2, ensure_ascii=False)
PY
fi

if [ "$(uname)" = "Darwin" ]; then security delete-generic-password -s claude-abacus -a abacus >/dev/null 2>&1 && tamam "Keychain kaydi silindi"
elif command -v secret-tool >/dev/null 2>&1; then secret-tool clear service claude-abacus 2>/dev/null && tamam "secret-tool kaydi silindi"; fi

for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  if [ -f "$rc" ] && grep -qF '# >>> claude-abacus >>>' "$rc"; then
    python3 - "$rc" <<'PY'
import re, sys
t = open(sys.argv[1]).read()
open(sys.argv[1], "w").write(re.sub(r"\n?# >>> claude-abacus >>>[\s\S]*?# <<< claude-abacus <<<\n?", "\n", t))
PY
    tamam "$rc: blok silindi"
  fi
done

[ -d "$DIZIN" ] && rm -rf "$DIZIN" && tamam "$DIZIN silindi"
echo "       Oturum gecmisi ~/.claude-abacus icinde kalir; istersen elle sil."
echo "       Abacus anahtarini istersen abacus.ai/app/profile/apikey sayfasindan iptal et."
echo "       Yeni bir terminal ac."
