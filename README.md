# domainSSL — 一键申请 Let's Encrypt 证书，支持自动续期

Linux Only | NGINX

## 使用方式

申请证书前请提前将域名解析到服务器。

### 交互式菜单

```
bash <(curl -s -L https://raw.githubusercontent.com/tealiving/domainSSL/master/domainSSL.sh)
```

运行后显示菜单：

- `1` 申请新证书（输入域名即可）
- `2` 查看证书到期情况
- `3` 安装自动续期定时任务（每日凌晨 3 点）
- `4` 取消自动续期定时任务
- `5` 手动执行续期

### 直接命令（供脚本/cron 调用）

| 命令 | 说明 |
|------|------|
| `domainSSL.sh example.com` | 直接签发（不经过菜单） |
| `domainSSL.sh --renew` | 续期所有域名（用于 cron） |
| `domainSSL.sh --cron` | 安装续期定时任务 |
| `domainSSL.sh --cron off` | 取消续期定时任务 |
| `domainSSL.sh --status` | 查看证书到期情况 |

## 证书路径

- 证书: `/home/ssl/<domain>/1.pem`
- 密钥: `/home/ssl/<domain>/1.key`
- Lego 状态: `/var/lib/domainssl/lego/`（持久化，重启不丢）

## 说明

- 使用 [lego](https://github.com/go-acme/lego) v3.8.0 HTTP-01 挑战
- 旧版 `/tmp/.lego/` 状态首次运行时自动迁移至持久化路径，无需重新签发
