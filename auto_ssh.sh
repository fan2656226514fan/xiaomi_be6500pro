#!/bin/sh
# auto_ssh.sh — 小米 BE6500Pro SSH 解锁（中文化版）
# 功能：开启 SSH/telnet/uart/boot_wait，备份主机密钥，重启 dropbear
#
# 用法：
#   安装(解锁+注册开机钩子):  sh /data/scripts/auto_ssh.sh install
#   仅解锁一次:              sh /data/scripts/auto_ssh.sh
#   卸载(删开机钩子):         sh /data/scripts/auto_ssh.sh uninstall

auto_ssh_dir="/data/scripts"
host_key="/etc/dropbear/dropbear_rsa_host_key"
host_key_bk="${auto_ssh_dir}/dropbear_rsa_host_key"

unlock() {
  # 恢复已备份的主机密钥
  [ -f $host_key_bk ] && ln -sf $host_key_bk $host_key

  # 开启 telnet / ssh / uart / boot_wait
  [ "$(nvram get telnet_en)" = 0 ] && nvram set telnet_en=1 && nvram commit
  [ "$(nvram get ssh_en)" = 0 ] && nvram set ssh_en=1 && nvram commit
  [ "$(nvram get uart_en)" = 0 ] && nvram set uart_en=1 && nvram commit
  [ "$(nvram get boot_wait)" = "off" ] && nvram set boot_wait=on && nvram commit

  # 固件升级会重置 CHANNEL，改回 stable 防止升级后锁死
  [ "`uci -c /usr/share/xiaoqiang get xiaoqiang_version.version.CHANNEL`" != 'stable' ] && {
    uci -c /usr/share/xiaoqiang set xiaoqiang_version.version.CHANNEL='stable'
    uci -c /usr/share/xiaoqiang commit xiaoqiang_version.version 2>/dev/null
  }

  channel=`/sbin/uci get /usr/share/xiaoqiang/xiaoqiang_version.version.CHANNEL`
  if [ "$channel" = "release" ]; then
    sed -i 's/channel=.*/channel="debug"/g' /etc/init.d/dropbear
  fi

  # dropbear 未运行或 22 端口未监听时，重启并设为自启
  if [ -z "$(pidof dropbear)" -o -z "$(netstat -ntul | grep :22)" ]; then
    /etc/init.d/dropbear restart 2>/dev/null
    /etc/init.d/dropbear enable
  fi
}

install() {
  # 解锁 SSH
  unlock

  # 主机密钥为空时，重启 dropbear 生成
  [ -s $host_key ] || /etc/init.d/dropbear restart 2>/dev/null

  # 备份主机密钥（防固件升级后密钥变化导致客户端告警）
  if [ ! -s $host_key_bk ]; then
    i=0
    while [ $i -le 30 ]
    do
      if [ -s $host_key ]; then
        cp -f $host_key $host_key_bk 2>/dev/null
        break
      fi
      let i++
      sleep 1s
    done
  fi

  # 注册防火墙开机钩子（每次开机自动解锁）
  uci set firewall.auto_ssh=include
  uci set firewall.auto_ssh.type='script'
  uci set firewall.auto_ssh.path="${auto_ssh_dir}/auto_ssh.sh"
  uci set firewall.auto_ssh.enabled='1'
  uci commit firewall

  echo -e "\033[32m SSH 解锁完成。 \033[0m"
}

uninstall() {
  # 删除开机自启钩子（不影响当前 SSH 状态）
  uci delete firewall.auto_ssh
  uci commit firewall
  echo -e "\033[33m SSH 解锁自启已移除。 \033[0m"
}

main() {
  [ -z "$1" ] && unlock && return
  case "$1" in
    install) install ;;
    uninstall) uninstall ;;
    *)
      echo -e "\033[31m 未知参数: $1 \033[0m"
      return 1
      ;;
  esac
}

main "$@"
