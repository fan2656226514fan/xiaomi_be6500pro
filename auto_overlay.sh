#!/bin/sh
# auto_overlay.sh — 小米 BE6500Pro Overlay 扩容挂载（中文化版）
# 功能：把系统可写层(/overlay)挂到 /data/other_vol/overlay，根分区从几 MB 扩到 200+ MB
#
# 用法：
#   安装(挂载+注册开机钩子):  sh /data/scripts/auto_overlay.sh install
#   仅挂载一次:              sh /data/scripts/auto_overlay.sh
#   卸载(删开机钩子):         sh /data/scripts/auto_overlay.sh uninstall
#
# 注意：安装后需重启一次生效；卸载不会缩小已挂载的分区

script_dir="/data/scripts"
overlay_dir="/data/other_vol/overlay"
overlay_mount_point="/overlay"

mount_overlay() {
  # 检查并创建 overlay 目录及子目录
  [ -e $overlay_dir ] || mkdir -p $overlay_dir
  [ -e $overlay_dir/upper ] || mkdir -p $overlay_dir/upper
  [ -e $overlay_dir/work ] || mkdir -p $overlay_dir/work

  # 把 overlay 目录绑定到挂载点
  mount --bind $overlay_dir $overlay_mount_point

  # 加载 preinit 脚本函数
  . /lib/functions/preinit.sh

  # 用 fopivot 把 upper/work 与 /rom 组合成根文件系统
  fopivot $overlay_mount_point/upper $overlay_mount_point/work /rom 1

  # 把各目录移动挂载到新位置
  /bin/mount -o noatime,move /rom/data /data 2>&-
  /bin/mount -o noatime,move /rom/etc /etc 2>&-
  /bin/mount -o noatime,move /rom/ini /ini 2>&-
  /bin/mount -o noatime,move /rom/userdisk /userdisk 2>&-

  echo -e "\033[32m Overlay 挂载完成。 \033[0m"
}

install() {
  # 执行挂载
  mount_overlay

  # 注册防火墙开机钩子（每次开机自动挂载）
  uci set firewall.auto_overlay=include
  uci set firewall.auto_overlay.type='script'
  uci set firewall.auto_overlay.path="${script_dir}/auto_overlay.sh"
  uci set firewall.auto_overlay.enabled='1'
  uci commit firewall

  echo -e "\033[32m Overlay 自动挂载已安装。 \033[0m"
}

uninstall() {
  # 删除开机自启钩子（当前挂载不受影响）
  uci delete firewall.auto_overlay
  uci commit firewall
  echo -e "\033[33m Overlay 自动挂载已卸载。 \033[0m"
}

main() {
  # 无参数时仅执行挂载
  [ -z "$1" ] && mount_overlay && return
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
