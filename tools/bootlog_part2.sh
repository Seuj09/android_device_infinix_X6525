#!/system/bin/sh
M=/tmp/m; mkdir -p $M
mount -t f2fs /dev/block/by-name/metadata $M 2>/dev/null
D=$M/boot_dmesg.txt; L=$M/boot_logcat.txt; R=$M/boot_props.txt
strip() { sed -E 's/^[0-9-]+ [0-9:.]+ +[0-9]+ +[0-9]+ //'; }

echo "## TICK"; cat $M/boot_tick.txt 2>/dev/null
echo "## STAGES"
grep -E "init: processing action \((early-init|init|late-init|early-fs|fs|post-fs|late-fs|post-fs-data|zygote-start|early-boot|boot)\)" $D 2>/dev/null \
 | sed -E 's/^\[ *([0-9.]+)\].*action \(([^)]*)\).*/\1 \2/' | sort -u -k2,2 | sort -n
echo "## KEY PROPS"
grep -E "^\[(apexd\.status|vendor\.all\.modules\.ready|sys\.boot_completed|init\.svc\.(vold|vndservicemanager|surfaceflinger|zygote|bootanim|vendor\.hwcomposer-2-4|insmod-sh))\]:" $R 2>/dev/null
echo "## RESTARTING"
grep -E "^\[init\.svc\..*\]: \[restarting\]" $R 2>/dev/null
echo "## LINK / INIT ERRORS"
grep -E "CANNOT LINK|library .* not found|Failed to parse|init\.X6525\.rc" $D $L 2>/dev/null | strip | sort -u | head -n 20
echo "## TOP LOGCAT ERRORS"
tail -n 1000 $L 2>/dev/null | grep -E " (E|F) " | grep -vE "keystore2|KernelMemoryBandwidth" | strip | sort | uniq -c | sort -nr | head -n 15
umount $M 2>/dev/null
