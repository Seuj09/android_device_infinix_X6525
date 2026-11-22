#!/system/bin/sh
M=/tmp/m; mkdir -p $M
mount -t f2fs /dev/block/by-name/metadata $M 2>/dev/null
D=$M/boot_dmesg.txt; L=$M/boot_logcat.txt; P=$M/boot_ps.txt; R=$M/boot_props.txt
strip() { sed -E 's/^[0-9-]+ [0-9:.]+ +[0-9]+ +[0-9]+ //'; }

echo "## TICK"; cat $M/boot_tick.txt 2>/dev/null
echo "## STAGES"
grep -E "init: processing action \((early-init|init|late-init|early-fs|fs|post-fs|late-fs|post-fs-data|zygote-start|early-boot|boot)\)" $D \
 | sed -E 's/^\[ *([0-9.]+)\].*action \(([^)]*)\).*/\1 \2/' | sort -u -k2,2 | sort -n
echo "## KEY PROPS"
grep -E "^\[(ro\.crypto|vold\.|apexd\.status|sys\.boot_completed|init\.svc\.(vold|vndservicemanager|surfaceflinger|zygote|bootanim|vendor\.hwcomposer|vendor\.gralloc|vendor\.health)|vendor\.all\.modules\.ready)\]" $R 2>/dev/null | head -n 30
echo "## KEY PS"
grep -E "vold|vndserviceman|surfaceflinger|zygote|system_server|bootanim|composer|gralloc|allocator|keystore|keymint|gatekeeper|watchdogd" $P 2>/dev/null
echo "## LINK ERRORS"
grep -E "CANNOT LINK|library .* not found" $L | strip | sort -u | head -n 20
echo "## ABORTS / FATAL"
grep -E "Abort message|F libc +: Fatal|F DEBUG +: (Abort|signal|backtrace|#00)|FATAL EXCEPTION|E AndroidRuntime:" $L | strip | sort -u | head -n 25
echo "## HWC / SF / ZYGOTE ERRORS"
grep -E " (E|F) (SurfaceFlinger|HWC|hwcomposer|gralloc|mali|Zygote|SystemServer|vold|keystore2|KeyMint)" $L | strip | sort -u | head -n 25
umount $M 2>/dev/null
