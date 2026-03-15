#!/usr/bin/env bash
set -euo pipefail

# Fix ClawPanel Web(headless) Skills page showing "CLI 不可用，仅显示本地扫描结果" (only 2 mock skills).
# Root cause: `openclaw skills list --json --verbose` may append logs after JSON; panel JSON.parse fails.
# Fix: remove `--verbose` for the skills list command (clean JSON) + bump execSync maxBuffer.
#
# Usage:
#   sudo bash scripts/patch-clawpanel-skills.sh
#   sudo bash scripts/patch-clawpanel-skills.sh /opt/clawpanel/scripts/dev-api.js

TARGET="${1:-/opt/clawpanel/scripts/dev-api.js}"

if [ ! -f "$TARGET" ]; then
  echo "[ERR] target not found: $TARGET" >&2
  exit 1
fi

TS=$(date -u +%Y%m%dT%H%M%SZ)
BACKUP="$TARGET.bak-skills-$TS"
cp -a "$TARGET" "$BACKUP"
echo "[OK] backup: $BACKUP"

# 1) Ensure skills list command does NOT use --verbose
perl -pi -e "s/npx -y openclaw skills list --json --verbose/npx -y openclaw skills list --json/g" "$TARGET"

# 2) Add maxBuffer to the execSync options for that call (safe for big JSON)
# Handle both the --json and --json --verbose variants.
perl -pi -e "s/execSync\(\x27npx -y openclaw skills list --json\x27, \{ encoding: \x27utf8\x27, timeout: 30000 \}\)/execSync('npx -y openclaw skills list --json', { encoding: 'utf8', timeout: 30000, maxBuffer: 10 * 1024 * 1024 })/g" "$TARGET"

# 3) Restart service
if command -v systemctl >/dev/null 2>&1; then
  echo "[OK] restarting clawpanel..."
  systemctl restart clawpanel
  sleep 1
  systemctl --no-pager -l status clawpanel | sed -n '1,18p'
else
  echo "[WARN] systemctl not found, restart clawpanel manually"
fi

echo "[OK] done"
