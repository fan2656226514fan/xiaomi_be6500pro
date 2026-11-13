#!/bin/sh
# ctemp_overlaybase.sh — 小米 BE6500Pro CPU 温度命令（中文化版，已挂载 Overlay 时用）
# 用法：curl -k <本脚本地址> | sh
# 卸载：rm /usr/bin/ctemp
# 说明：写入 /usr/bin（Overlay 持久层），重启不丢

cat << 'EOF' > /usr/bin/ctemp
#!/bin/sh
# 读取 CPU 温度
temp=$(cat /sys/class/thermal/thermal_zone0/temp)
# 换算为摄氏度并保留一位小数
echo "CPU Temp: $(echo "$temp" | awk '{printf "%.1f", $1/1000}')°C"
EOF

# 设置执行权限
chmod +x /usr/bin/ctemp
