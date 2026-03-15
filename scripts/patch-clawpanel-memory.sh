#!/usr/bin/env bash
set -euo pipefail

# Fix ClawPanel Web(headless) memory file operations path mismatch after upgrades.
# Usage:
#   sudo bash scripts/patch-clawpanel-memory.sh
#   sudo bash scripts/patch-clawpanel-memory.sh /opt/clawpanel/scripts/dev-api.js

TARGET="${1:-/opt/clawpanel/scripts/dev-api.js}"

if [ ! -f "$TARGET" ]; then
  echo "[ERR] target not found: $TARGET" >&2
  exit 1
fi

TS=$(date -u +%Y%m%dT%H%M%SZ)
BACKUP="$TARGET.bak-$TS"
cp -a "$TARGET" "$BACKUP"
echo "[OK] backup: $BACKUP"

BLOCK_FILE=$(mktemp)
PATCHER_FILE=$(mktemp)

cat > "$BLOCK_FILE" <<'BLOCK'
  // 记忆文件
  _resolve_agent_workspace(agent_id) {
    try {
      if (!fs.existsSync(CONFIG_PATH)) return path.join(OPENCLAW_DIR, 'workspace')
      const cfg = JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'))
      const list = cfg?.agents?.list || []
      const id = agent_id || 'main'
      const a = list.find(x => x && x.id === id)
      return (a && a.workspace) ? a.workspace : path.join(OPENCLAW_DIR, 'workspace')
    } catch {
      return path.join(OPENCLAW_DIR, 'workspace')
    }
  },

  _list_md_recursive(baseDir, relPrefix, maxFiles = 800) {
    const out = []
    const skipDir = new Set(['node_modules', '.git', '.trash', 'tmp', 'test-results'])
    function walk(dir, rel, depth) {
      if (out.length >= maxFiles) return
      if (depth > 10) return
      let entries = []
      try { entries = fs.readdirSync(dir, { withFileTypes: true }) } catch { return }
      for (const ent of entries) {
        if (out.length >= maxFiles) return
        const name = ent.name
        if (name.startsWith('.')) continue
        const full = path.join(dir, name)
        if (ent.isDirectory()) {
          if (skipDir.has(name)) continue
          walk(full, path.join(rel, name), depth + 1)
        } else if (ent.isFile() && name.endsWith('.md')) {
          const relPath = rel ? path.join(rel, name) : name
          out.push(relPrefix ? path.join(relPrefix, relPath) : relPath)
        }
      }
    }
    walk(baseDir, '', 0)
    return out.sort()
  },

  _memory_prefix_for_category(category) {
    const cat = category || 'memory'
    if (cat === 'memory') return 'memory'
    if (cat === 'archive') return path.join('memory', 'archive')
    if (cat === 'core') return ''
    return cat
  },

  list_memory_files({ category, agent_id, agentId }) {
    agent_id = agent_id || agentId
    const ws = handlers._resolve_agent_workspace(agent_id)
    const cat = category || 'memory'

    if (cat === 'core') {
      if (!fs.existsSync(ws)) return []
      try {
        // 只列出 workspace 根目录下的 md 核心文件
        return fs.readdirSync(ws).filter(f => f.endsWith('.md')).sort()
      } catch {
        return []
      }
    }

    const prefix = handlers._memory_prefix_for_category(cat)
    const dir = prefix ? path.join(ws, prefix) : ws
    if (!fs.existsSync(dir)) return []

    // memory/archive：递归列出，覆盖 daily/projects 等
    if (cat === 'memory' || cat === 'archive') {
      return handlers._list_md_recursive(dir, prefix)
    }

    // 其他分类：仅列出当前目录下的 md
    try {
      return fs.readdirSync(dir)
        .filter(f => f.endsWith('.md'))
        .sort()
        .map(f => path.join(prefix, f))
    } catch {
      return []
    }
  },

  read_memory_file({ path: filePath, agent_id, agentId }) {
    agent_id = agent_id || agentId
    if (isUnsafePath(filePath)) throw new Error('非法路径')
    const ws = handlers._resolve_agent_workspace(agent_id)
    const full = path.join(ws, filePath)
    if (!fs.existsSync(full)) return ''
    return fs.readFileSync(full, 'utf8')
  },

  write_memory_file({ path: filePath, content, category, agent_id, agentId }) {
    agent_id = agent_id || agentId
    if (isUnsafePath(filePath)) throw new Error('非法路径')
    const ws = handlers._resolve_agent_workspace(agent_id)
    let rel = filePath

    // 新建文件：filePath 通常是 notes.md；此时用 category 决定落点
    if (!filePath.includes('/') && !filePath.includes('\\')) {
      const prefix = handlers._memory_prefix_for_category(category || 'memory')
      rel = prefix ? path.join(prefix, filePath) : filePath
    }

    const full = path.join(ws, rel)
    const dir = path.dirname(full)
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true })
    fs.writeFileSync(full, content)
    return true
  },

  delete_memory_file({ path: filePath, agent_id, agentId }) {
    agent_id = agent_id || agentId
    if (isUnsafePath(filePath)) throw new Error('非法路径')
    const ws = handlers._resolve_agent_workspace(agent_id)
    const full = path.join(ws, filePath)
    if (fs.existsSync(full)) fs.unlinkSync(full)
    return true
  },

  export_memory_zip({ category, agent_id, agentId }) {
    agent_id = agent_id || agentId
    throw new Error('ZIP 导出仅在 Tauri 桌面应用中可用')
  },

BLOCK

cat > "$PATCHER_FILE" <<'JS'
const fs = require('fs')

const target = process.argv[2]
const blockPath = process.argv[3]

let s = fs.readFileSync(target, 'utf8')
const start = '  // 记忆文件'
const end = '  // 备份管理'
const i = s.indexOf(start)
const j = s.indexOf(end)
if (i === -1 || j === -1 || j <= i) {
  console.error('Cannot locate memory block markers', { i, j })
  process.exit(1)
}

const block = fs.readFileSync(blockPath, 'utf8')
s = s.slice(0, i) + block + s.slice(j)
fs.writeFileSync(target, s)
console.log('Patched memory block OK')
JS

node "$PATCHER_FILE" "$TARGET" "$BLOCK_FILE"

rm -f "$BLOCK_FILE" "$PATCHER_FILE" || true

if command -v systemctl >/dev/null 2>&1; then
  echo "[OK] restarting clawpanel..."
  systemctl restart clawpanel
  sleep 1
  systemctl --no-pager -l status clawpanel | sed -n '1,18p'
else
  echo "[WARN] systemctl not found, restart clawpanel manually"
fi

echo "[OK] done"
