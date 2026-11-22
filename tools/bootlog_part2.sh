#!/system/bin/sh
M=/tmp/m; mkdir -p $M
mount -t f2fs /dev/block/by-name/metadata $M 2>/dev/null
D=$M/boot_dmesg.txt
echo "## INSMOD / MODPROBE / DRM / MALI / SPRD-DRM IN DMESG"
grep -iE "insmod|modprobe|sprd-drm|sprd_drm|mali|\[drm\]|dpu|dsi|Unknown symbol|Invalid module|vendor_dlkm|vendor\.all\.modules" $D | grep -viE "initcall|calling |seth|sipx" | head -n 60
umount $M 2>/dev/null
