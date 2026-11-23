#!/system/bin/sh
echo "## slot"; getprop ro.boot.slot_suffix
echo "## mount /vendor"; mount /vendor 2>&1
echo "## vendor check"; grep -n "sprd-drm\|ufs-sprd\|bootlog_meta" /vendor/bin/init.insmod.sh /vendor/etc/init/hw/init.X6525.rc 2>&1
echo "## metadata"; M=/tmp/m; mkdir -p $M; mount -t f2fs /dev/block/by-name/metadata $M 2>&1; ls -la $M; umount $M 2>/dev/null
echo "## pstore"; ls -la /sys/fs/pstore 2>&1
