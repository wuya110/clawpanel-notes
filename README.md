# ClawPanel 本机记录

## 当前环境
- 用户: `root`
- 当前版本: `0.8.3`
- 项目主页: `https://github.com/qingchencloud/clawpanel`
- 官方 Linux 一键部署/升级脚本链接:
  - `https://raw.githubusercontent.com/qingchencloud/clawpanel/main/scripts/linux-deploy.sh`

## 本机安装路径
- 程序目录: `/opt/clawpanel`
- systemd 服务文件: `/etc/systemd/system/clawpanel.service`
- systemd 启用链接: `/etc/systemd/system/multi-user.target.wants/clawpanel.service`
- OpenClaw 相关数据目录: `/root/.openclaw/clawpanel`
- OpenClaw 配置文件: `/root/.openclaw/clawpanel.json`
- 设备密钥文件: `/root/.openclaw/clawpanel-device-key.json`
- 历史备份目录: `/opt/clawpanel-backups`

## 当前服务启动方式
```ini
WorkingDirectory=/opt/clawpanel
ExecStart=/usr/bin/node /opt/clawpanel/scripts/serve.js --port 1420
```

## SSH 下一次一键升级
### 方案 1：官方一键升级（推荐）
```bash
curl -fsSL https://raw.githubusercontent.com/qingchencloud/clawpanel/main/scripts/linux-deploy.sh | bash
```
说明：
- 脚本会检测已有 `/opt/clawpanel`
- 已存在时会进入目录执行依赖安装与构建
- 会保持 `clawpanel.service` 方式运行

### 方案 2：手动升级
```bash
cd /opt/clawpanel && npm install --registry https://registry.npmmirror.com && npm run build && systemctl restart clawpanel
```

## 常用排查命令
```bash
systemctl status clawpanel --no-pager -l
journalctl -u clawpanel -n 200 --no-pager
ss -lntp | grep 1420
curl -I http://127.0.0.1:1420
```

## 备注
当前本机安装不是标准 git 工作区，程序目录下未检测到可直接 `git pull` 的远端配置。
因此后续升级优先使用官方 `linux-deploy.sh` 一键脚本。
