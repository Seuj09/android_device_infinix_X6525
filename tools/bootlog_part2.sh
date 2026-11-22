#!/system/bin/sh
mount /vendor_dlkm 2>/dev/null
echo "## /vendor_dlkm & /dev/dri"
ls -la /vendor_dlkm/lib/modules/sprd-drm.ko /dev/dri 2>&1
echo "## lsmod (drm/gsp/mali/iommu/apsys/hwinfo)"
lsmod | grep -iE "drm|gsp|mali|iommu|apsys|hwinfo"
echo "## modprobe sprd-drm.ko"
modprobe -v -d /vendor_dlkm/lib/modules sprd-drm.ko 2>&1
echo "## ls /dev/dri after"
ls -la /dev/dri 2>&1
echo "## dmesg tail"
dmesg | tail -n 25
