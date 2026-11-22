#!/system/bin/sh
# Prints a compact, de-duplicated summary of the debug boot logs.
M=/tmp/m; mkdir -p $M
mount -t f2fs /dev/block/by-name/metadata $M 2>/dev/null
D=$M/boot_dmesg.txt; L=$M/boot_logcat.txt; P=$M/boot_props.txt
strip() { sed -E 's/^[0-9-]+ [0-9:.]+ +[0-9]+ +[0-9]+ //'; }

echo "## TICK"; cat $M/boot_tick.txt
echo "## STAGES"
grep -E "init: processing action \((early-init|init|late-init|early-fs|fs|post-fs|late-fs|post-fs-data|zygote-start|early-boot|boot|nonencrypted)\)" $D \
 | sed -E 's/^\[ *([0-9.]+)\].*action \(([^)]*)\).*/\1 \2/'
echo "## PROPS"
grep -E "^\[(init\.svc\.(zygote|surfaceflinger|vold|keystore2|vendor\.hwcomposer|vendor\.gralloc|vndservicemanager|bootanim)|ro\.boottime\.init|apexd\.status|vold\.|sys\.boot_completed|vendor\.all\.modules\.ready)" $P
echo "## SLOW/FAILED"
grep -E "init: (Command '.*'(failed|took [0-9]{4,}ms)|.*waiting took [0-9]{2,}|Service '[^']+' .* (exited with status [1-9]|received SIG))" $D \
 | sed -E 's/^\[ *([0-9.]+)\] init: /\1 /' | tail -n 30
echo "## LINK ERRORS"
grep -E "CANNOT LINK|library .* not found" $L | strip | sort -u | head -n 20
echo "## ABORTS/FATAL"
grep -E "Abort message|F libc +: Fatal|F (DEBUG|SurfaceFlinger|keystore2|vold|Zygote|AndroidRuntime)|E AndroidRuntime: (FATAL|Caused by)" $L | strip | sort -u | head -n 25
umount $M 2>/dev/null
