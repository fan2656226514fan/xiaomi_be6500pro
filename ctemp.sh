#!/bin/sh
# ctemp.sh — 小米 BE6500Pro CPU 温度命令（中文化版，未挂载 Overlay 时用）
# 功能：创建 /usr/bin/ctemp 命令，运行显示 CPU 温度
#
# 用法：
#   安装(创建命令+注册开机钩子):  sh /data/scripts/ctemp.sh install
#   仅创建命令:                   sh /data/scripts/ctemp.sh
#   卸载(删命令+删开机钩子):      sh /data/scripts/ctemp.sh uninstall
#
# 说明：已挂载 Overlay 的机器可直接用 ctemp_overlaybase.sh（重启不丢）

script_dir="/data/scripts"

ctemp(){
  # 命令文件不存在时创建
  if [ ! -f /usr/bin/ctemp ]; then
    cat << 'EOF' > /usr/bin/ctemp
#!/bin/sh
# 读取 CPU 温度
temp=$(cat /sys/class/thermal/thermal_zone0/temp)
# 换算为摄氏度并保留一位小数
echo "CPU Temp: $(echo "$temp" | awk '{printf "%.1f", $1/1000}')°C"
EOF
    # 设置执行权限
    chmod +x /usr/bin/ctemp
  else
    echo "ctemp 已存在，跳过创建。"
  fi
}

install() {
  # 创建 ctemp 命令
  ctemp

  # 注册防火墙开机钩子（重启后自动重建）
  uci set firewall.ctemp=include
  uci set firewall.ctemp.type='script'
  uci set firewall.ctemp.path="${script_dir}/ctemp.sh"
  uci set firewall.ctemp.enabled='1'
  uci commit firewall

  echo -e "\033[32m ctemp 已安装。 \033[0m"
}

uninstall() {
  # 删除命令文件和开机钩子
  rm /usr/bin/ctemp
  uci delete firewall.ctemp
  uci commit firewall
  echo -e "\033[33m ctemp 已卸载。 \033[0m"
}

main() {
  # 无参数时仅创建命令
  [ -z "$1" ] && ctemp && return
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
