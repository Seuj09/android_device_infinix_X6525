#!/system/bin/sh
# Run in recovery (adb shell sh /tmp/collect_bootlog.sh) after a hung boot
# with the vendor-bootlog.img debug vendor. Writes /tmp/bootlog_report.txt
# NOTE: in this recovery /cache and /metadata alias each other, so mount the
# raw partitions on private dirs instead.
OUT=/tmp/bootlog_report.txt
M=/tmp/m; C=/tmp/c
mkdir -p $M $C
mount -t f2fs /dev/block/by-name/metadata $M 2>/dev/null || mount -t ext4 /dev/block/by-name/metadata $M
mount -t f2fs /dev/block/by-name/cache $C 2>/dev/null || mount -t ext4 /dev/block/by-name/cache $C
D=$M/boot_dmesg.txt
{
echo "===== mounts"; mount | grep -E " /(cache|metadata|tmp/m|tmp/c) "; ls -la / | grep -E "cache|metadata"
echo "===== boot_tick"; cat $M/boot_tick.txt
echo "===== ls metadata / cache"; ls -la $M $C
echo "===== filtered dmesg"
grep -nE "init: |vold|apexd|linker|CANNOT LINK|SELinux|avc: .*denied|reboot|fs_mgr|vdc|watchdog" "$D" \
  | grep -viE "sprd-seth|sipx|probe of|initcall|calling " | tail -n 400
echo "===== dmesg tail"; tail -n 80 "$D"
echo "===== boot_ps (non-kthread)"; grep -vE "^ *[0-9]+ +2 " $M/boot_ps.txt
echo "===== props"; grep -E "init.svc|boottime|vold|apexd|modules.ready|bootmode|reboot" $M/boot_props.txt
echo "===== ylog ap"; cat $C/ylog/ap/*.ylog 2>&1 | head -n 50
} > "$OUT" 2>&1
umount $M $C 2>/dev/null
echo "Report written to $OUT ($(wc -c < $OUT) bytes)"
