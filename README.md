# xiaomi_be6500pro

小米 BE6500 Pro 路由器优化脚本（中文化修正版）

> 基于 [oaooi/xiaomi_be6500pro](https://github.com/oaooi/xiaomi_be6500pro) 整理：
> 修正了软件源脚本的死链问题，全部脚本注释已中文化，并保留原有功能。

## ⚠️ 重要声明：本仓库不再提供 auto_overlay.sh / auto_ssh.sh

原仓库的 **Overlay 扩容（auto_overlay.sh）在 BE6500Pro 原厂固件上存在严重缺陷**，已从本仓库移除：

- 原厂固件不是标准 OpenWrt 布局（无 squashfs + upper/work 合并根），脚本向 `/data/other_vol/overlay` pivot 一个**空的** upper，会把出厂后所有配置（米家绑定、SSH 通道标记、opkg 源、管理后台版本标记）**整体遮蔽**，表现为：管理页出现"开发者版 / only for test"水印、米家设备离线、`/etc` 配置回出厂状态
- 名义"扩容 200+ MB"实际无效——`/data/other_vol` 本来就是独立的 215MB 卷，pivot 并未增加任何空间
- **恢复方法**：`uci delete firewall.auto_overlay && uci commit firewall && reboot`，配置即全部还原

`auto_ssh.sh`（nvram 改 SSH 开关 + CHANNEL 标记）也随之移除：本机实测固件 CHANNEL 已是 `stable`，SSH 可直连，无需该脚本。

现在本仓库只保留**在原厂系统上安全可用**的两个脚本：软件源修正、CPU 温度命令。两者均不碰挂载、不碰根文件系统。

## 关于下载源

所有安装命令默认走 **jsDelivr CDN**（国内直连、路由器可访问）。GitHub raw 直连仅在可翻墙环境使用。

| 文件 | jsDelivr（推荐） | GitHub raw（需代理） |
|---|---|---|
| change_opkg_sources.sh | `https://cdn.jsdelivr.net/gh/fan2656226514fan/xiaomi_be6500pro@main/change_opkg_sources.sh` | `https://raw.githubusercontent.com/fan2656226514fan/xiaomi_be6500pro/main/change_opkg_sources.sh` |
| ctemp.sh | `https://cdn.jsdelivr.net/gh/fan2656226514fan/xiaomi_be6500pro@main/ctemp.sh` | `https://raw.githubusercontent.com/fan2656226514fan/xiaomi_be6500pro/main/ctemp.sh` |

> jsDelivr 说明：`@main` 跟随主分支最新提交（约 12 小时缓存延迟）；GitHub raw 永远是最新。刚推的新提交若 CDN 没刷新，把 `@main` 换成具体 commit 前缀（如 `@e6a2a27`）可立即获取。

## 1. 更换软件源（阿里云镜像·修正版）

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
| 启动顺序 | 可能早于 Overlay 扩容，写入丢失 | 等 `/` 挂载完成再写配置 |

## 2. ctemp 显示 CPU 温度

装到持久分区 `/data/bin` 并自动加入 PATH，**原厂系统直接可用，重启不丢**（`/usr/bin` 在原厂固件上只读，旧版装法会报 `Read-only file system`）：

```
mkdir -p /data/scripts
cd /data/scripts
curl -k -o ctemp.sh https://cdn.jsdelivr.net/gh/fan2656226514fan/xiaomi_be6500pro@main/ctemp.sh
chmod +x ctemp.sh
sh ctemp.sh install

# 当前会话立即生效（新会话自动生效）：
export PATH="/data/bin:$PATH"
ctemp
```

（卸载）

```
sh /data/scripts/ctemp.sh uninstall
```

> 旧版 `ctemp_overlaybase.sh`（写 `/usr/bin` 的那版）已废弃——它依赖 Overlay pivot 后的可写根，存在与 auto_overlay 相同的隐患，本仓库已移除。

## 建议安装顺序

软件源修正 → ctemp。两步均即装即用，无需重启。

## 磁盘空间不足的正确处理

`opkg` 报 `Only have 0kb available on /overlay` 时，**不要**做 Overlay pivot（见顶部声明）。用零风险方式把索引和临时目录挪到 `/data`：

```
mkdir -p /data/opkg/lists /data/opkg/tmp
grep -q '/data/opkg' /etc/opkg.conf || cat >> /etc/opkg.conf <<'EOF'
lists_dir ext /data/opkg/lists
option tmp_dir /data/opkg/tmp
EOF
opkg update
```

## 致谢

- [oaooi/xiaomi_be6500pro](https://github.com/oaooi/xiaomi_be6500pro) — 原版脚本
