# 一键申请Let's Encrypt域名证书

## Linux Only | NGINX

### 首次申请:

申请证书前请提前解析域名到服务器

```
bash <(curl -s -L git.io/dmSSL)
```

按照提示输入域名即可，证书文件保存在 `/home/ssl/<domain>/`。  
首次签发后脚本会提示是否安装自动续期定时任务（每日凌晨 3 点执行），建议安装。

### 手动续期:

```
bash <(curl -s -L git.io/dmSSL) --renew
```

会遍历 `/home/ssl/` 下所有域名，对 30 天内过期的证书自动续期。
