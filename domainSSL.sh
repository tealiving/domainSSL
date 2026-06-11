#!/bin/sh

LEGO_URL="https://cdn.jsdelivr.net/gh/moeik/domainSSL@master/lego/lego_v3.8.0_linux_amd64.tar.gz"
LEGO_DIR="/var/lib/domainssl/lego"
SCRIPT_URL="https://raw.githubusercontent.com/tealiving/domainSSL/master/domainSSL.sh"

# ---------- helper ----------

ensure_lego() {
  cd /tmp || exit 1
  if [ ! -f "./lego" ]; then
    wget -q "$LEGO_URL" && tar zxf lego_v3.8.0_linux_amd64.tar.gz && chmod 755 ./* ./lego
  fi
}

migrate_old_state() {
  if [ -d "/tmp/.lego" ] && [ ! -d "$LEGO_DIR/accounts" ]; then
    mkdir -p "$LEGO_DIR"
    cp -r /tmp/.lego/* "$LEGO_DIR/"
  fi
}

cron_installed() {
  crontab -l 2>/dev/null | grep -q "domainSSL.sh.*--renew"
}

# ---------- 申请 ----------

issue() {
  domain="$1"
  ensure_lego
  migrate_old_state
  mkdir -p "$LEGO_DIR"
  service nginx stop
  ./lego --path="$LEGO_DIR" --email="admin@$domain" --domains="$domain" --http -a run
  service nginx start
  if ls "$LEGO_DIR/certificates" 2>/dev/null | grep -q "$domain"; then
    mkdir -p "/home/ssl/$domain"
    cp "$LEGO_DIR/certificates/$domain.crt" "/home/ssl/$domain/1.pem"
    cp "$LEGO_DIR/certificates/$domain.key" "/home/ssl/$domain/1.key"
    echo "证书签发成功，保存在 /home/ssl/$domain/"
    return 0
  else
    echo "证书签发失败，请检查 80 端口是否被占用，域名解析或输入是否正确。"
    return 1
  fi
}

# ---------- 续期 ----------

renew_all() {
  ensure_lego
  migrate_old_state
  service nginx stop 2>/dev/null || true
  for domain_dir in /home/ssl/*/; do
    [ -d "$domain_dir" ] || continue
    domain=$(basename "$domain_dir")
    [ -z "$domain" ] && continue
    if [ -f "$LEGO_DIR/certificates/$domain.crt" ]; then
      ./lego --path="$LEGO_DIR" --email="admin@$domain" --domains="$domain" --http -a renew --days 30 2>/dev/null || true
      if ls "$LEGO_DIR/certificates" 2>/dev/null | grep -q "$domain"; then
        cp "$LEGO_DIR/certificates/$domain.crt" "/home/ssl/$domain/1.pem"
        cp "$LEGO_DIR/certificates/$domain.key" "/home/ssl/$domain/1.key"
        echo "续期完成: $domain"
      fi
    else
      echo "跳过 $domain（非 domainSSL 签发，无 lego 状态）"
    fi
  done
  service nginx start 2>/dev/null || true
  echo "续期检查完成。"
}

# ---------- 证书状态 ----------

show_status() {
  has_domains=0
  for domain_dir in /home/ssl/*/; do
    [ -d "$domain_dir" ] || continue
    domain=$(basename "$domain_dir")
    cert="/home/ssl/$domain/1.pem"
    [ -f "$cert" ] || continue
    has_domains=1
    expired=$(openssl x509 -enddate -noout -in "$cert" 2>/dev/null | cut -d= -f2)
    if [ -n "$expired" ]; then
      expires_epoch=$(date -d "$expired" +%s 2>/dev/null)
      now=$(date +%s)
      remaining=$(( (expires_epoch - now) / 86400 ))
      if [ "$remaining" -gt 0 ]; then
        echo "$domain   还有 ${remaining} 天到期   有效期至 $expired"
      else
        echo "$domain   已过期 $(( -remaining )) 天   有效期至 $expired"
      fi
    fi
  done
  [ "$has_domains" -eq 0 ] && echo "没有找到证书（/home/ssl/ 下无证书文件）"
}

# ---------- 定时任务 ----------

install_cron() {
  CRON_JOB="0 3 * * * bash <(curl -s -L $SCRIPT_URL) --renew >/dev/null 2>&1"
  if cron_installed; then
    echo "自动续期定时任务已存在，无需重复安装。"
  else
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "自动续期定时任务已安装（每日凌晨 3 点执行）。"
  fi
}

remove_cron() {
  if cron_installed; then
    crontab -l 2>/dev/null | grep -v "domainSSL.sh.*--renew" | crontab -
    echo "自动续期定时任务已取消。"
  else
    echo "当前没有自动续期定时任务。"
  fi
}

# ---------- 菜单 ----------

menu() {
  while :; do
    echo ""
    echo "==================== domainSSL ===================="
    echo " 1) 申请新证书"
    echo " 2) 查看证书到期情况"
    echo " 3) 安装自动续期定时任务"
    echo " 4) 取消自动续期定时任务"
    echo " 5) 手动执行续期"
    echo " 0) 退出"
    echo "==================================================="
    printf "请选择: "
    read -r choice
    case "$choice" in
      1)
        printf "请输入域名: "
        read -r domain
        [ -z "$domain" ] && echo "域名不能为空" && continue
        issue "$domain"
        if [ $? -eq 0 ]; then
          echo ""
          printf "是否安装自动续期定时任务? [Y/n]: "
          read -r yn
          case "$yn" in n|N|no|NO) ;; *) install_cron ;; esac
        fi
        ;;
      2) show_status ;;
      3) install_cron ;;
      4) remove_cron ;;
      5) renew_all ;;
      0) echo "退出。"; break ;;
      *) echo "无效选择，请重新输入。" ;;
    esac
  done
}

# ---------- 入口 ----------

case "${1:-}" in
  --renew|renew) renew_all ;;
  --cron|cron)
    case "$2" in off|remove|delete|stop) remove_cron ;; *) install_cron ;; esac
    ;;
  --status|status) show_status ;;
  *)
    if [ -n "$1" ]; then
      issue "$1"
    else
      menu
    fi
    ;;
esac
