#!/system/bin/sh
M=/tmp/m; mkdir -p $M
mount -t f2fs /dev/block/by-name/metadata $M 2>/dev/null
echo "## insmod/modprobe in ps"
grep -E "insmod|modprobe|kworker| D " $M/boot_ps.txt 2>/dev/null | head -n 25
echo "## dmesg tail (last 40)"
tail -n 40 $M/boot_dmesg.txt 2>/dev/null
umount $M 2>/dev/null
