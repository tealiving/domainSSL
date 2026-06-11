#!/bin/sh

LEGO_URL="https://cdn.jsdelivr.net/gh/moeik/domainSSL@master/lego/lego_v3.8.0_linux_amd64.tar.gz"
LEGO_DIR="/var/lib/domainssl/lego"

case "${1:-}" in
  --renew|renew)
    cd /tmp || exit 1
    if [ ! -f "./lego" ]; then
      wget -q "$LEGO_URL" && tar zxf lego_v3.8.0_linux_amd64.tar.gz && chmod 755 ./* ./lego
    fi
    # 迁移旧 /tmp/.lego/ 状态到持久化路径（仅一次）
    if [ -d "/tmp/.lego" ] && [ ! -d "$LEGO_DIR/accounts" ]; then
      mkdir -p "$LEGO_DIR"
      cp -r /tmp/.lego/* "$LEGO_DIR/"
    fi
    service nginx stop 2>/dev/null || true
    for domain_dir in /home/ssl/*/; do
      [ -d "$domain_dir" ] || continue
      domain=$(basename "$domain_dir")
      [ -z "$domain" ] && continue
      ./lego --path="$LEGO_DIR" --email="admin@$domain" --domains="$domain" --http -a renew --days 30 2>/dev/null || true
      if ls "$LEGO_DIR/certificates" 2>/dev/null | grep -q "$domain"; then
        cp "$LEGO_DIR/certificates/$domain.crt" "/home/ssl/$domain/1.pem"
        cp "$LEGO_DIR/certificates/$domain.key" "/home/ssl/$domain/1.key"
      fi
    done
    service nginx start 2>/dev/null || true
    echo "续期检查完成。"
    ;;

  *)
    read -p "请输入域名:" domain && cd /tmp
    if [ ! -f "lego_v3.8.0_linux_amd64.tar.gz" ]; then
      wget "$LEGO_URL"
    fi
    tar zxvf lego_v3.8.0_linux_amd64.tar.gz
    chmod 755 *
    # 迁移旧 /tmp/.lego/ 状态到持久化路径（仅一次）
    if [ -d "/tmp/.lego" ] && [ ! -d "$LEGO_DIR/accounts" ]; then
      mkdir -p "$LEGO_DIR"
      cp -r /tmp/.lego/* "$LEGO_DIR/"
    fi
    service nginx stop
    ./lego --path="$LEGO_DIR" --email="admin@$domain" --domains="$domain" --http -a run
    service nginx start
    if ls "$LEGO_DIR/certificates" | grep "$domain"
        then
        mkdir -p /home/ssl/$domain
        cp "$LEGO_DIR/certificates/$domain.crt" /home/ssl/$domain/1.pem
        cp "$LEGO_DIR/certificates/$domain.key" /home/ssl/$domain/1.key
        path="/home/ssl/$domain/"
        echo '证书签发成功，证书文件保存在'$path'。'
        echo ""
        printf "是否安装自动续期定时任务? (证书有效期90天，建议安装) [Y/n]: "
        read -r yn
        case "$yn" in
          n|N|no|NO)
            echo "已跳过。需要时可手动执行: bash <(curl -s -L git.io/dmSSL) --renew"
            ;;
          *)
            SCRIPT_URL="https://raw.githubusercontent.com/moeik/domainSSL/master/domainSSL.sh"
            CRON_JOB="0 3 * * * bash <(curl -s -L $SCRIPT_URL) --renew >/dev/null 2>&1"
            (crontab -l 2>/dev/null | grep -v "domainSSL.sh.*--renew" ; echo "$CRON_JOB") | crontab -
            echo "自动续期定时任务已安装 (每日凌晨3点执行)。"
            ;;
        esac
    else
        echo '证书签发失败，请检查80端口是否被占用，域名解析或者输入域名是否正确。'
    fi
    ;;
esac
