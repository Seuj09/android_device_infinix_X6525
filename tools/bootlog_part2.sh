#!/system/bin/sh
# Second-pass, focused extraction. Writes /tmp/bootlog_part2.txt
OUT=/tmp/bootlog_part2.txt
M=/tmp/m; mkdir -p $M
mount -t f2fs /dev/block/by-name/metadata $M 2>/dev/null
D=$M/boot_dmesg.txt; L=$M/boot_logcat.txt
{
echo "===== init actions / exec / slow or failed commands"
grep -nE "init: (processing action|SVC_EXEC|Command .*(failed|took [0-9]{4,}ms)|.*waiting took|Wait|wait_for|.*first stage|Setup|Init|init second stage|.*Switching root|.*Reboot|.*reboot)" $D | head -n 150
echo "===== vold / apexd / mount_all"
grep -nE "vold|apexd|mount_all|fs_mgr|Cannot start an updatable" $D | head -n 60
echo "===== logcat: why services exit (first 120 errors)"
grep -E "CANNOT LINK|linker|F libc|F DEBUG|Abort message| E vold| F vold|vndservicemanager|hwcomposer|android.hardware.health" $L | grep -vE "avc:" | head -n 120
echo "===== logcat: vold"
grep -iE " vold|vdc" $L | head -n 40
} > "$OUT" 2>&1
umount $M 2>/dev/null
echo "Report written to $OUT ($(wc -c < $OUT) bytes)"
