# xiaomi_be6500pro

小米 BE6500 Pro 路由器优化脚本（中文化修正版）

> 基于 [oaooi/xiaomi_be6500pro](https://github.com/oaooi/xiaomi_be6500pro) 整理：
> 修正了软件源脚本的死链问题，全部脚本注释已中文化，并保留原有功能。

## 关于下载源

所有安装命令默认走 **jsDelivr CDN**（国内直连、路由器可访问）。GitHub raw 直连仅在可翻墙环境使用。

| 文件 | jsDelivr（推荐） | GitHub raw（需代理） |
|---|---|---|
| auto_ssh.sh | `https://cdn.jsdelivr.net/gh/fan2656226514fan/xiaomi_be6500pro@main/auto_ssh.sh` | `https://raw.githubusercontent.com/fan2656226514fan/xiaomi_be6500pro/main/auto_ssh.sh` |
| auto_overlay.sh | `https://cdn.jsdelivr.net/gh/fan2656226514fan/xiaomi_be6500pro@main/auto_overlay.sh` | `https://raw.githubusercontent.com/fan2656226514fan/xiaomi_be6500pro/main/auto_overlay.sh` |
| change_opkg_sources.sh | `https://cdn.jsdelivr.net/gh/fan2656226514fan/xiaomi_be6500pro@main/change_opkg_sources.sh` | `https://raw.githubusercontent.com/fan2656226514fan/xiaomi_be6500pro/main/change_opkg_sources.sh` |
| ctemp.sh | `https://cdn.jsdelivr.net/gh/fan2656226514fan/xiaomi_be6500pro@main/ctemp.sh` | `https://raw.githubusercontent.com/fan2656226514fan/xiaomi_be6500pro/main/ctemp.sh` |
| ctemp_overlaybase.sh | `https://cdn.jsdelivr.net/gh/fan2656226514fan/xiaomi_be6500pro@main/ctemp_overlaybase.sh` | `https://raw.githubusercontent.com/fan2656226514fan/xiaomi_be6500pro/main/ctemp_overlaybase.sh` |

> jsDelivr 说明：`@main` 跟随主分支最新提交（约 12 小时缓存延迟）；GitHub raw 永远是最新。刚推的新提交若 CDN 没刷新，把 `@main` 换成具体 commit 前缀（如 `@28bcce7`）可立即获取。

## 1. 自动启动 SSH

SSH 终端运行：

```
mkdir -p /data/scripts
cd /data/scripts
curl -k -O https://cdn.jsdelivr.net/gh/fan2656226514fan/xiaomi_be6500pro@main/auto_ssh.sh
chmod +x auto_ssh.sh
sh auto_ssh.sh install
```

（卸载）

```
sh /data/scripts/auto_ssh.sh uninstall
```

## 2. 挂载 Overlay（扩容根分区）

根分区可写层只有几 MB，挂载到 `/data` 大分区后可获得 200+ MB 空间，装软件不再提示空间不足。

SSH 终端运行：

```
mkdir -p /data/scripts
cd /data/scripts
curl -k -O https://cdn.jsdelivr.net/gh/fan2656226514fan/xiaomi_be6500pro@main/auto_overlay.sh
chmod +x auto_overlay.sh
sh auto_overlay.sh install
reboot
```

（卸载）

```
sh /data/scripts/auto_overlay.sh uninstall
```

## 3. 更换软件源（阿里云镜像·修正版）

原版脚本指向的 `snapshots` 源已停发 `Packages.gz`（404），本版改用阿里云镜像 `releases/packages-23.05`，实测可用。

SSH 终端运行：

```
mkdir -p /data/scripts
cd /data/scripts
curl -k -O https://cdn.jsdelivr.net/gh/fan2656226514fan/xiaomi_be6500pro@main/change_opkg_sources.sh
chmod +x change_opkg_sources.sh
sh change_opkg_sources.sh install
```

刷新软件包列表：

```
opkg update
```

（卸载）

```
sh /data/scripts/change_opkg_sources.sh uninstall
```

相对原版的修正：

| 问题 | 原版 | 本版 |
|---|---|---|
| 源地址 | snapshots（404 死链） | 阿里云镜像 releases/packages-23.05 |
| 重复运行 | 每次开机往 opkg.conf 堆叠重复 arch 行 | 幂等，缺失才写 |
| 备份处理 | mv/.bak 纠缠，重复运行出错 | 直接覆盖，无残留 |
| 启动顺序 | 可能早于 Overlay 扩容，写入丢失 | 等 `/` 扩容完成再写配置 |

## 4. ctemp 显示 CPU 温度

### 4.1 已挂载 Overlay

```
curl -k https://cdn.jsdelivr.net/gh/fan2656226514fan/xiaomi_be6500pro@main/ctemp_overlaybase.sh | sh
```

（卸载）

```
rm /usr/bin/ctemp
```

### 4.2 未挂载 Overlay

使用防火墙开机钩子加载：

```
mkdir -p /data/scripts
cd /data/scripts
curl -k -O https://cdn.jsdelivr.net/gh/fan2656226514fan/xiaomi_be6500pro@main/ctemp.sh
chmod +x ctemp.sh
sh ctemp.sh install
```

（卸载）

```
sh /data/scripts/ctemp.sh uninstall
```

## 建议安装顺序

SSH 解锁 → Overlay 扩容（重启）→ 软件源修正 → ctemp

> Overlay 扩容是软件源持久生效的前提；软件源脚本已内置等待逻辑，启动顺序不稳也能自动补救。

## 致谢

- [oaooi/xiaomi_be6500pro](https://github.com/oaooi/xiaomi_be6500pro) — 原版脚本
