# clawpanel-notes

这仓库是给这台机器（OpenClaw + ClawPanel Web/headless）用的备忘录 + 兜底脚本。

## 1) 官方升级 ClawPanel（推荐日常用）

```bash
curl -fsSL https://raw.githubusercontent.com/qingchencloud/clawpanel/main/scripts/linux-deploy.sh | bash
systemctl daemon-reload
systemctl restart clawpanel
systemctl status clawpanel --no-pager -l | sed -n "1,20p"
```

升级后如果页面出现回归，就用下面对应的补丁脚本。

---

## 2) 恢复「记忆文件」页（路径/读写不对、切 agent 空白）

症状：
- 有的能看但打不开
- 有的能打开但保存/新建不生效
- 切换 agent 后空白

### 方式 A：用仓库脚本（最清晰，可 `git pull` 更新）

第一次（还没 clone 过）：
```bash
cd ~ && \
git clone https://github.com/wuya110/clawpanel-notes.git && \
cd clawpanel-notes && \
sudo bash scripts/patch-clawpanel-memory.sh
```

以后每次（已经有 `~/clawpanel-notes` 目录）：
```bash
cd ~/clawpanel-notes && \
git pull && \
sudo bash scripts/patch-clawpanel-memory.sh
```

### 方式 B：一键（官方同款 curl|bash，不依赖仓库目录）

```bash
curl -fsSL https://raw.githubusercontent.com/wuya110/clawpanel-notes/main/scripts/patch-clawpanel-memory.sh | sudo bash
```

这个补丁会：
- 兼容前端传参 `agentId` / 后端旧参数 `agent_id`
- 按 `openclaw.json -> agents.list[].workspace` 解析每个 agent 的真实 workspace（支持多 agent）
- 让 list/read/write/delete 的路径一致
- 支持 `memory / memory/archive / core` 的常用映射（并对 memory/archive 递归列出 md）

脚本会自动备份目标文件（`.bak-时间戳`），并重启 `clawpanel` 服务。

---

## 3) 修复「Skills」页只显示 2 个技能，并提示 “CLI 不可用”

症状：
- 顶部提示：`CLI 不可用，仅显示本地扫描结果`
- Skills 只剩 2 个（github/weather）

原因：ClawPanel 调用 `openclaw skills list --json --verbose` 时，某些版本会在 JSON 后面夹日志，导致 JSON.parse 失败，于是退回 mock。

### 方式 A：用仓库脚本

```bash
cd ~/clawpanel-notes && \
git pull && \
sudo bash scripts/patch-clawpanel-skills.sh
```

### 方式 B：一键（官方同款 curl|bash）

```bash
curl -fsSL https://raw.githubusercontent.com/wuya110/clawpanel-notes/main/scripts/patch-clawpanel-skills.sh | sudo bash
```

这个补丁会：
- 把 skills list 命令改成不带 `--verbose`（保证输出纯 JSON）
- 顺便把 execSync 的 maxBuffer 调大，避免大 JSON 被截断

---

## 备注

- ClawPanel 更新会覆盖本地对 `/opt/clawpanel/scripts/dev-api.js` 的修改，所以升级后如果回归，补丁再跑一次即可。
