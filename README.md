# clawpanel-notes

这仓库是给这台机器（OpenClaw + ClawPanel Web/headless）用的备忘录 + 兜底脚本。

## 1) 官方升级 ClawPanel（推荐日常用）

```bash
curl -fsSL https://raw.githubusercontent.com/qingchencloud/clawpanel/main/scripts/linux-deploy.sh | bash
systemctl daemon-reload
systemctl restart clawpanel
systemctl status clawpanel --no-pager -l | sed -n "1,20p"
```

如果升级后发现「记忆文件」页出现：
- 有的能看但打不开
- 有的能打开但保存/新建不生效
- 切换 agent 后空白

就用下面的“恢复记忆页”命令。

## 2) 恢复记忆文件页（两种方式，任选其一）

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

## 这个补丁做了什么

- 修复 ClawPanel Web/headless 记忆文件读写路径不一致的问题（能列出但读不了/写不了/不显示）
- 按 `openclaw.json -> agents.list[].workspace` 解析每个 agent 的真实 workspace（支持多 agent）
- 让 list/read/write/delete 的路径一致
- 支持 `memory / memory/archive / core` 的常用映射（并对 memory/archive 递归列出 md）

脚本会自动备份目标文件（`.bak-时间戳`），并重启 `clawpanel` 服务。

## 备注

- ClawPanel 更新会覆盖本地对 `/opt/clawpanel/scripts/dev-api.js` 的修改，所以升级后如果回归，补丁再跑一次即可。
