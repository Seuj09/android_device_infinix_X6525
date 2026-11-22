#!/system/bin/sh
M=/tmp/m; V=/tmp/v; VD=/tmp/vd; mkdir -p $M $V $VD
mount -t f2fs /dev/block/by-name/metadata $M 2>/dev/null
mount -t erofs -o ro /dev/block/mapper/vendor_b $V 2>/dev/null
mount -t erofs -o ro /dev/block/mapper/vendor_dlkm_b $VD 2>/dev/null
echo "## mapper"; ls -la /dev/block/mapper/vendor* 2>&1
echo "## vendor/lib/modules"; ls -la $V/lib/modules 2>&1
echo "## vendor_dlkm/lib/modules"; ls -la $VD/lib/modules/sprd-drm.ko $VD/lib/modules/mali_kbase.ko $VD/lib/modules/init.insmod.cfg 2>&1
echo "## modprobe/insmod in logcat"
grep -iE "modprobe|insmod|sprd-drm|sprd_drm|mali" $M/boot_logcat.txt 2>/dev/null | head -n 30
umount $M $V $VD 2>/dev/null
