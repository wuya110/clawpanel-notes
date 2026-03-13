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
ExecStart=/usr/bin/node scripts/serve.js --port 1420
```

## SSH 下一次稳妥升级口令（最终版）
```bash
curl -fsSL https://raw.githubusercontent.com/qingchencloud/clawpanel/main/scripts/linux-deploy.sh | bash && \
systemctl daemon-reload && \
systemctl restart clawpanel && \
echo '--- clawpanel status ---' && \
systemctl status clawpanel --no-pager -l | sed -n '1,20p' && \
echo '--- clawpanel pid/time ---' && \
systemctl show clawpanel -p MainPID -p ExecMainStartTimestamp -p ActiveEnterTimestamp && \
echo '--- port 1420 ---' && \
ss -lntp | grep 1420
```

## 一键回滚到最近备份
```bash
LAST_BAK=$(find /opt/clawpanel-backups -maxdepth 2 -type d -name 'clawpanel.old' | sort | tail -n 1) && \
[ -n "$LAST_BAK" ] && \
cp -a /etc/systemd/system/clawpanel.service "/etc/systemd/system/clawpanel.service.rollback_$(date -u +%Y%m%dT%H%M%SZ)" && \
rm -rf /opt/clawpanel && \
cp -a "$LAST_BAK" /opt/clawpanel && \
if [ -f /opt/clawpanel-backups/$(basename "$(dirname "$LAST_BAK")")/clawpanel.service ]; then cp -f /opt/clawpanel-backups/$(basename "$(dirname "$LAST_BAK")")/clawpanel.service /etc/systemd/system/clawpanel.service; fi && \
systemctl daemon-reload && \
systemctl restart clawpanel && \
echo '--- rollback source ---' && \
echo "$LAST_BAK" && \
echo '--- clawpanel status ---' && \
systemctl status clawpanel --no-pager -l | sed -n '1,20p' && \
echo '--- clawpanel pid/time ---' && \
systemctl show clawpanel -p MainPID -p ExecMainStartTimestamp -p ActiveEnterTimestamp && \
echo '--- port 1420 ---' && \
ss -lntp | grep 1420
```

## 分步版升级流程
```bash
curl -fsSL https://raw.githubusercontent.com/qingchencloud/clawpanel/main/scripts/linux-deploy.sh | bash
systemctl daemon-reload
systemctl restart clawpanel
systemctl status clawpanel --no-pager -l | sed -n '1,20p'
systemctl show clawpanel -p MainPID -p ExecMainStartTimestamp -p ActiveEnterTimestamp
ss -lntp | grep 1420
journalctl -u clawpanel -n 80 --no-pager
```

## 常用排查命令
```bash
systemctl status clawpanel --no-pager -l
journalctl -u clawpanel -n 200 --no-pager
ss -lntp | grep 1420
curl -I http://127.0.0.1:1420
```

## 备注
- 当前本机安装目录是 `/opt/clawpanel`
- 本机此前出现过“文件已更新，但服务未切到新进程”的情况
- 因此以后升级命令必须追加：
  - `systemctl daemon-reload`
  - `systemctl restart clawpanel`
- 不要只跑官方脚本后就结束
- 回滚口令会优先回滚到 `/opt/clawpanel-backups` 里最近一份 `clawpanel.old`
