#!/bin/sh
adb wait-for-device
if [ "$(adb shell id -u 2>/dev/null | tr -d '\r')" != "0" ]; then
    adb root 2>/dev/null
    sleep 2
    adb wait-for-device
fi

adb shell <<'LIVE_EOF'
echo "=== 1. UPTIME & PROPS ==="
uptime
getprop | grep -E "sys\.boot_completed|vold\.|ro\.crypto|ro\.adb\.secure|sys\.usb\.|dev\.bootcomplete" | sort
echo "--- non-running services ---"
getprop | grep "^\[init\.svc\." | grep -v "\[running\]" | sort

echo "=== 2. MOUNTS & STORAGE ==="
grep -E " (/data|/metadata|/cache|/mnt/vendor|/tranfs|/blackbox) " /proc/mounts 2>/dev/null || cat /proc/mounts | tail -n 25
df -h /data /metadata /cache /mnt/vendor 2>&1

echo "=== 3. KEY PROCESSES ==="
ps -A -o PID,USER,STAT,NAME | grep -E "zygote|system_server|surfaceflinger|bootanimation|servicemanager|hwservicemanager|vndservicemanager|vold|keystore|keymint|gatekeeper|composer|hwc|allocator|audio|netd|installd|storaged|adbd"

echo "=== 4. DMESG STAGES & ERRORS ==="
dmesg | grep -iE "X6525_|init: |avc: |selinux|error|fail|fatal|segfault|binder|f2fs|ext4|fs_mgr|vold|dpu|dispc|mali" | tail -n 80

echo "=== 5. LOGCAT BOOT EVENTS & CRASHES ==="
timeout 5 logcat -b events -d 2>&1 | grep -E "boot_progress|sf_|am_" | tail -n 30
echo "--- logcat crash ---"
timeout 5 logcat -b crash -d -v time 2>&1 | tail -n 80
echo "--- logcat *:E (main,system) ---"
timeout 5 logcat -b main,system -d -v brief "*:E" 2>&1 | tail -n 100

echo "=== 6. TOMBSTONES ==="
ls -lt /data/tombstones 2>&1 | head -n 15
LIVE_EOF