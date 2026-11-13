#!/bin/sh
# change_opkg_sources.sh — fixed version for Xiaomi BE6500Pro
# Fixes vs original (oaooi/xiaomi_be6500pro):
#   1. Dead snapshots feeds -> live Aliyun mirror (releases/packages-23.05, opkg format)
#   2. Idempotent: no duplicate arch lines in /etc/opkg.conf on repeated runs
#   3. No mv/.bak juggling -> direct overwrite of /etc/opkg/distfeeds.conf
#   4. Waits for auto_overlay.sh to finish expanding / before writing /etc (boot order safety)
#
# 用法 Usage:
#   安装(写源+注册开机钩子):  sh /data/scripts/change_opkg_sources.sh install
#   仅重写一次源配置:         sh /data/scripts/change_opkg_sources.sh
#   卸载(删开机钩子):         sh /data/scripts/change_opkg_sources.sh uninstall
#
# 卸载说明 Uninstall notes:
#   uninstall 只删除 firewall 开机钩子，不动 /etc/opkg/distfeeds.conf 和 /etc/opkg.conf，
#   已生效的源配置保持不变；如需恢复原厂源，手动执行:
#     cp /etc/opkg/distfeeds.conf.bak /etc/opkg/distfeeds.conf   # 若存在原厂备份
#   或直接删除本脚本: rm /data/scripts/change_opkg_sources.sh

script_dir="/data/scripts"

change_sources() {
  # Wait for auto_overlay to expand rootfs (up to 60s)
  i=0
  while [ $i -lt 60 ]; do
    root_kb=$(df -k / | tail -1 | awk '{print $2}')
    [ "$root_kb" -gt 100000 ] && break
    sleep 1
    i=$((i+1))
  done

  # opkg.conf: append arch lines only if missing
  grep -q 'aarch64_cortex-a53 300' /etc/opkg.conf 2>/dev/null || cat >> /etc/opkg.conf <<'CONF'
arch all 100
arch aarch64_cortex-a53_neon-vfpv4 200
arch aarch64_cortex-a53 300
CONF

  # distfeeds.conf: overwrite (idempotent, no .bak leftovers)
  cat > /etc/opkg/distfeeds.conf <<'FEEDS'
src/gz openwrt_base http://mirrors.aliyun.com/openwrt/releases/packages-23.05/aarch64_cortex-a53/base
src/gz openwrt_luci http://mirrors.aliyun.com/openwrt/releases/packages-23.05/aarch64_cortex-a53/luci
src/gz openwrt_packages http://mirrors.aliyun.com/openwrt/releases/packages-23.05/aarch64_cortex-a53/packages
src/gz openwrt_routing http://mirrors.aliyun.com/openwrt/releases/packages-23.05/aarch64_cortex-a53/routing
src/gz openwrt_telephony http://mirrors.aliyun.com/openwrt/releases/packages-23.05/aarch64_cortex-a53/telephony
FEEDS
}

install() {
  change_sources
  uci set firewall.change_opkg_sources=include
  uci set firewall.change_opkg_sources.type='script'
  uci set firewall.change_opkg_sources.path="${script_dir}/change_opkg_sources.sh"
  uci set firewall.change_opkg_sources.enabled='1'
  uci commit firewall
  echo -e "\033[32m Auto Opkg Source Change (fixed) installed. \033[0m"
}

uninstall() {
  uci delete firewall.change_opkg_sources
  uci commit firewall
  echo -e "\033[33m Auto Opkg Source Change uninstalled. \033[0m"
}

main() {
  [ -z "$1" ] && change_sources && return
  case "$1" in
    install) install ;;
    uninstall) uninstall ;;
    *)
      echo -e "\033[31m Unknown parameter: $1 \033[0m"
      return 1
      ;;
  esac
}

main "$@"
