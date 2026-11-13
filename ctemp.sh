#!/bin/sh
# ctemp.sh — 小米 BE6500Pro CPU 温度命令（原厂系统直装版）
# 修正：原版写 /usr/bin（只读，需先跑 auto_overlay pivot 才可写，有遮蔽配置风险）；
#       本版装到持久分区 /data/bin 并加入 PATH，原厂系统直接可用，重启不丢，不碰挂载。
#
# 用法：
#   安装:   sh /data/scripts/ctemp.sh install
#   卸载:   sh /data/scripts/ctemp.sh uninstall
#   手动跑: /data/bin/ctemp 或 ctemp（安装后新会话生效）

script_dir="/data/scripts"
bin_dir="/data/bin"
bin_file="${bin_dir}/ctemp"
profile_file="/etc/profile"
path_line='export PATH="/data/bin:$PATH"'

write_cmd() {
  mkdir -p "$bin_dir"
  cat << 'EOF' > "$bin_file"
#!/bin/sh
# 读取 CPU 温度
temp=$(cat /sys/class/thermal/thermal_zone0/temp)
echo "CPU Temp: $(echo "$temp" | awk '{printf "%.1f", $1/1000}')°C"
EOF
  chmod +x "$bin_file"

  # PATH 幂等写入 /etc/profile（新登录会话生效）
  grep -q '/data/bin' "$profile_file" 2>/dev/null || echo "$path_line" >> "$profile_file"
}

install() {
  write_cmd
  # 兼容清理：若旧版装过 /usr/bin/ctemp 或 firewall.ctemp 钩子，一并移除
  rm -f /usr/bin/ctemp 2>/dev/null
  uci -q delete firewall.ctemp && uci commit firewall
  echo -e "\033[32m ctemp 已安装：$(command -v ctemp || echo "$bin_file")（当前会话用 $bin_file，新会话直接 ctemp） \033[0m"
}

uninstall() {
  rm -f "$bin_file"
  rmdir "$bin_dir" 2>/dev/null
  # 从 /etc/profile 移除 PATH 行
  sed -i '\|/data/bin|d' "$profile_file" 2>/dev/null
  uci -q delete firewall.ctemp && uci commit firewall
  rm -f /usr/bin/ctemp 2>/dev/null
  echo -e "\033[33m ctemp 已卸载。 \033[0m"
}

main() {
  [ -z "$1" ] && write_cmd && "$bin_file" && return
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
