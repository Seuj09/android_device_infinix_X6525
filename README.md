# Android device tree for Infinix Smart 8 (X6525)

## Debug Command (Recovery)

```bash
curl -sL https://raw.githubusercontent.com/Seuj09/android_device_infinix_X6525/77238da/tools/bootlog_part2.sh | adb shell sh
```

LunarisOS 3.13 (Android 16 QPR2 / `lunaris-16.2`) device tree for the Infinix Smart 8 X6525
(Unisoc T606 / UMS9230 / qogirl6).

Build target:

```
lineage_X6525-userdebug
```

## Setup & Building

Clone both the device and vendor trees on the `lunaris-16.2` branch:

```bash
git clone https://github.com/Seuj09/android_device_infinix_X6525 -b lunaris-16.2 device/infinix/X6525
git clone https://github.com/Seuj09/android_vendor_infinix_X6525 -b lunaris-16.2 vendor/infinix/X6525
```

Extract proprietary blobs from your stock dump into `vendor/infinix/X6525/proprietary/`, then build:

```bash
source build/envsetup.sh
breakfast X6525
mka bacon
```

## Release (`v3.13-20261121`)

Built from `lunaris-16.2` with Android 16 QPR2 VINTF/Soong fixes, SurfaceFlinger `auto_latch_unsignaled` bootanimation smoothness fix, `watchdogd` respawn/ordering fix, eMMC `sysfs_path` & `/tranfs` fstab fixes, LCD Doze/AOD overlay overrides, and `group_unisoc` dynamic partition parity.

### Assets (from [`v3.13-20261121`](https://github.com/Seuj09/android_device_infinix_X6525/releases/tag/v3.13-20261121))
- `Lunaris-AOSP-X6525-Community-3.13-GMS-2026112101.zip` (`.sha256sum`) — Full LunarisOS 3.13 (Android 16) OTA package
- `boot.img`, `dtbo.img`, `vendor_boot.img` — Boot/recovery/DTBO images (`vbmeta*` omitted; assumes verification is already disabled)

### Installing / Updating

From Recovery (`Apply Update` -> `Apply from ADB`):

```bash
adb sideload Lunaris-AOSP-X6525-Community-3.13-GMS-2026112101.zip
```

> **Note for A/B slot `_a` stock backup**: `adb sideload` writes the OTA payload to the **inactive** slot (so if you are currently on slot `_b`, sideloading writes to slot `_a`). If you want to keep slot `_a` untouched as a stock backup, install only `vendor_boot_b`, `boot_b`, `dtbo_b`, and the extracted partition images onto `*_b` via `fastbootd` instead.

If you are switching from another ROM or stock, wipe data in Recovery (`Factory reset` -> `Format data/factory reset`) after/before sideloading.
