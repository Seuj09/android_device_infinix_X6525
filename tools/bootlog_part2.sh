#!/system/bin/sh
M=/tmp/m; mkdir -p $M
mount -t f2fs /dev/block/by-name/metadata $M 2>/dev/null
D=$M/boot_dmesg.txt; L=$M/boot_logcat.txt; R=$M/boot_props.txt
strip() { sed -E 's/^[0-9-]+ [0-9:.]+ +[0-9]+ +[0-9]+ //'; }

echo "## RESTARTING SVCS"
grep -E "^\[init\.svc\..*\]: \[restarting\]" $R 2>/dev/null
echo "## SF/HWC IN DMESG"
grep -E "surfaceflinger|hwcomposer|gralloc|composer" $D | tail -n 30
echo "## SF / HWC / EGL / GRAPHICS IN LOGCAT"
grep -iE "SurfaceFlinger|hwcomposer|HWC|RenderEngine|gralloc|mali|libEGL|Vulkan|ComposerHal|HWComposer|GraphicBuffer" $L | grep -E " (W|E|F) " | strip | sort -u | head -n 45
echo "## CRASHES / BACKTRACE"
grep -E "F DEBUG +: (pid:|Cmdline:|signal |Abort message|#00 |#01 |#02 )" $L | strip | head -n 30
umount $M 2>/dev/null
