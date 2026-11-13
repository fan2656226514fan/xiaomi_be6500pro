# xiaomi_be6500pro

Fixed opkg sources script for **Xiaomi BE6500 Pro** router (original firmware).

## What was fixed vs `oaooi/xiaomi_be6500pro`

| Issue | Original | This version |
|---|---|---|
| Feeds URL | `downloads.openwrt.org/snapshots/...` — snapshots migrated to APK, `Packages.gz` returns **404** | Aliyun mirror `releases/packages-23.05` (opkg format, verified working in CN) |
| Repeat runs | appends duplicate `arch` lines to `/etc/opkg.conf` every boot | idempotent — appends only if missing |
| Backup handling | `mv` + restore from `.bak` breaks on repeated runs | direct overwrite, no `.bak` juggling |
| Boot order | may run before `auto_overlay.sh` expands rootfs → writes lost | waits up to 60s for rootfs > 100MB before writing `/etc` |

## Install

```sh
mkdir -p /data/scripts
cd /data/scripts
curl -k -O https://raw.githubusercontent.com/fan2656226514fan/xiaomi_be6500pro/main/change_opkg_sources.sh
chmod +x change_opkg_sources.sh
sh change_opkg_sources.sh install
opkg update
```

## Uninstall

```sh
sh change_opkg_sources.sh uninstall
```

## Notes

- Requires `auto_overlay.sh` (rootfs expansion) for persistent `/etc` writes; this script waits for it automatically.
- `opkg.conf` arch priority: `aarch64_cortex-a53_neon-vfpv4 (200)` > `aarch64_cortex-a53 (300)`, so native-arch packages win when both exist.
