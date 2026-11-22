#!/system/bin/sh
# Prints a compact, de-duplicated summary of the debug boot logs.
M=/tmp/m; mkdir -p $M
mount -t f2fs /dev/block/by-name/metadata $M 2>/dev/null
D=$M/boot_dmesg.txt; L=$M/boot_logcat.txt
# strip logcat "date time pid tid" prefix so identical messages dedupe
strip() { sed -E 's/^[0-9-]+ [0-9:.]+ +[0-9]+ +[0-9]+ //'; }

echo "## STAGES"
grep -E "init: processing action \((early-init|init|late-init|early-fs|fs|post-fs|late-fs|post-fs-data|zygote-start|early-boot|boot)\)" $D \
 | sed -E 's/^\[ *([0-9.]+)\].*action \(([^)]*)\).*/\1 \2/'
echo "## SLOW/FAILED"
grep -E "init: Command '(mount_all|exec|wait|start vold|exec_start)[^']*'.*(failed|took [0-9]{4,}ms)|waiting took [0-9]{2,}" $D | sed -E 's/^\[ *([0-9.]+)\] init: /\1 /' | head -n 15
echo "## VOLD"
grep -E "service 'vold'|Service 'vold'|vold-failed" $D | sed -E 's/^\[ *([0-9.]+)\] init: /\1 /' | head -n 8
echo "## LINK ERRORS"
grep -E "CANNOT LINK|library .* not found" $L | strip | sort -u | head -n 25
echo "## ABORTS"
grep -E "Abort message|F libc +: Fatal" $L | strip | sort -u | head -n 15
echo "## VOLD LOGCAT"
grep -E " (E|F) vold" $L | strip | sort -u | head -n 10
umount $M 2>/dev/null
