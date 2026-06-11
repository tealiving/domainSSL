# 一键申请 Let's Encrypt 域名证书（支持自动续期）

## Linux Only | NGINX

### 首次申请

申请证书前请提前解析域名到服务器

```
bash <(curl -s -L https://raw.githubusercontent.com/tealiving/domainSSL/master/domainSSL.sh)
```

按照提示输入域名即可，证书文件保存在 `/home/ssl/<domain>/`。  
首次签发后脚本会提示是否安装自动续期定时任务（每日凌晨 3 点执行），建议安装。

### 手动续期

```
bash <(curl -s -L https://raw.githubusercontent.com/tealiving/domainSSL/master/domainSSL.sh) --renew
```

遍历 `/home/ssl/` 下所有域名，对 30 天内过期的证书自动续期。

### 证书路径

| 文件 | 路径 |
|------|------|
| 证书 | `/home/ssl/<domain>/1.pem` |
| 密钥 | `/home/ssl/<domain>/1.key` |
| Lego 状态 | `/var/lib/domainssl/lego/`（持久化，重启不丢） |

### 说明

- 使用 [lego](https://github.com/go-acme/lego) v3.8.0 通过 HTTP-01 挑战签发
- 旧版 `/tmp/.lego/` 状态会在首次运行时自动迁移到持久化路径，无需重新签发
- 定时任务通过 `crontab` 安装，每天凌晨 3 点检查续期
