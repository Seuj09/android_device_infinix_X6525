#!/system/bin/sh
# Run in recovery (adb shell sh /tmp/collect_bootlog.sh) after a hung boot
# with the vendor-bootlog.img debug vendor. Writes /tmp/bootlog_report.txt
OUT=/tmp/bootlog_report.txt
mount /metadata 2>/dev/null; mount /cache 2>/dev/null
D=/metadata/boot_dmesg.txt
{
echo "===== boot_tick"; cat /metadata/boot_tick.txt
echo "===== ls /metadata /cache"; ls -la /metadata /cache
echo "===== filtered dmesg"
grep -nE "init: |vold|apexd|linker|CANNOT LINK|SELinux|avc: .*denied|reboot|fs_mgr|vdc" "$D" \
  | grep -viE "sprd-seth|sipx|probe of|initcall|calling " | tail -n 400
echo "===== dmesg tail"; tail -n 80 "$D"
echo "===== boot_ps (non-kthread)"; grep -vE " 2 [SIDR]" /metadata/boot_ps.txt
echo "===== ylog"; ls -laR /cache/ylog 2>&1 | head -n 80
echo "===== ylog journal"; tail -n 60 /cache/ylog/journal.log 2>&1
} > "$OUT" 2>&1
echo "Report written to $OUT ($(wc -c < $OUT) bytes)"
