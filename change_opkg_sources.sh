#!/bin/sh
# change_opkg_sources.sh — 小米 BE6500Pro 软件源更换（修正版）
# 相对原版 (oaooi/xiaomi_be6500pro) 的修正：
#   1. 原版 snapshots 源已停发 Packages.gz（404）→ 改用阿里云镜像 releases/packages-23.05（opkg 格式）
#   2. 幂等：重复运行/每次开机不会往 /etc/opkg.conf 堆叠重复的 arch 行
#   3. 去掉 mv/.bak 备份纠缠 → 直接覆盖写入 /etc/opkg/distfeeds.conf
#   4. 开机等待 auto_overlay.sh 扩容完成后再写 /etc（防启动顺序问题导致配置丢失）
#
# 用法：
#   安装(写源+注册开机钩子):  sh /data/scripts/change_opkg_sources.sh install
#   仅重写一次源配置:         sh /data/scripts/change_opkg_sources.sh
#   卸载(删开机钩子):         sh /data/scripts/change_opkg_sources.sh uninstall
#
# 卸载说明：
#   uninstall 只删除 firewall 开机钩子，不动 /etc/opkg/distfeeds.conf 和 /etc/opkg.conf，
#   已生效的源配置保持不变；如需恢复原厂源，手动执行:
#     cp /etc/opkg/distfeeds.conf.bak /etc/opkg/distfeeds.conf   # 若存在原厂备份
#   或直接删除本脚本: rm /data/scripts/change_opkg_sources.sh

script_dir="/data/scripts"

change_sources() {
  # 等待 auto_overlay 完成根分区扩容（/ 大于 100MB 才算挂好，最多等 60 秒）
  i=0
  while [ $i -lt 60 ]; do
    root_kb=$(df -k / | tail -1 | awk '{print $2}')
    [ "$root_kb" -gt 100000 ] && break
    sleep 1
    i=$((i+1))
  done

  # opkg.conf：仅在缺失时追加 arch 声明行（幂等）
  grep -q 'aarch64_cortex-a53 300' /etc/opkg.conf 2>/dev/null || cat >> /etc/opkg.conf <<'CONF'
arch all 100
arch aarch64_cortex-a53_neon-vfpv4 200
arch aarch64_cortex-a53 300
CONF

  # distfeeds.conf：直接覆盖写入（幂等，无 .bak 残留）
  cat > /etc/opkg/distfeeds.conf <<'FEEDS'
src/gz openwrt_base http://mirrors.aliyun.com/openwrt/releases/packages-23.05/aarch64_cortex-a53/base
src/gz openwrt_luci http://mirrors.aliyun.com/openwrt/releases/packages-23.05/aarch64_cortex-a53/luci
src/gz openwrt_packages http://mirrors.aliyun.com/openwrt/releases/packages-23.05/aarch64_cortex-a53/packages
src/gz openwrt_routing http://mirrors.aliyun.com/openwrt/releases/packages-23.05/aarch64_cortex-a53/routing
src/gz openwrt_telephony http://mirrors.aliyun.com/openwrt/releases/packages-23.05/aarch64_cortex-a53/telephony
FEEDS
}

install() {
  # 写入源配置
  change_sources

  # 注册防火墙开机钩子（每次开机自动重写源）
  uci set firewall.change_opkg_sources=include
  uci set firewall.change_opkg_sources.type='script'
  uci set firewall.change_opkg_sources.path="${script_dir}/change_opkg_sources.sh"
  uci set firewall.change_opkg_sources.enabled='1'
  uci commit firewall

  echo -e "\033[32m 软件源自启已安装（阿里云镜像源）。 \033[0m"
}

uninstall() {
  # 删除开机自启钩子（已生效的源配置保持不变）
  uci delete firewall.change_opkg_sources
  uci commit firewall
  echo -e "\033[33m 软件源自启已卸载。 \033[0m"
}

main() {
  # 无参数时仅重写一次源配置
  [ -z "$1" ] && change_sources && return
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
