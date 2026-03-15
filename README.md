# clawpanel-notes

这仓库是给这台机器（OpenClaw + ClawPanel Web/headless）用的备忘录 + 兜底脚本。

## 推荐日常升级方式（官方升级）

平时用官方脚本升级 ClawPanel；如果升级后「记忆文件」页出现：
- 有的能看但打不开
- 有的能打开但保存/新建不生效
- 切换 agent 后空白

就跑下面的补丁脚本。

官方升级：
```bash
curl -fsSL https://raw.githubusercontent.com/qingchencloud/clawpanel/main/scripts/linux-deploy.sh | bash
systemctl daemon-reload
systemctl restart clawpanel
systemctl status clawpanel --no-pager -l | sed -n '1,20p'
```

## 记忆文件页修复补丁（可重复运行）

这个补丁会：
- 兼容前端传参 `agentId` / 后端旧参数 `agent_id`
- 按 `openclaw.json -> agents.list[].workspace` 解析每个 agent 的真实 workspace
- 让 list/read/write/delete 的路径一致
- 支持 `memory / memory/archive / core` 的常用映射（并对 memory/archive 递归列出 md）

运行：
```bash
sudo bash scripts/patch-clawpanel-memory.sh
```

它会自动备份目标文件（`.bak-时间戳`），并重启 `clawpanel` 服务。

## 备注

- ClawPanel 更新会覆盖本地对 `/opt/clawpanel/scripts/dev-api.js` 的修改，所以升级后如果回归，补丁再跑一次即可。
