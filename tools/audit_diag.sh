#!/bin/sh
# Runtime audit script for X6525 (Audio, Bluetooth crash/tombstone, Hotspot/BPF,
# full Sensor list incl. Proximity, Camera, GNSS, Calls/SMS/IMS, and HALs).
# Runs on host (via adb) or directly in a device shell.

if command -v adb >/dev/null 2>&1 && [ ! -e /system/bin/getprop ]; then
    adb wait-for-device </dev/null
    if [ "$(adb shell id -u </dev/null 2>/dev/null | tr -d '\r')" != "0" ]; then
        adb root </dev/null 2>/dev/null
        sleep 2
        adb wait-for-device </dev/null
    fi

    shrun() {
        printf '%s\n' "$1" | adb shell sh -s 2>&1
    }

    shroot() {
        if [ "$(adb shell id -u </dev/null 2>/dev/null | tr -d '\r')" = "0" ]; then
            printf '%s\n' "$1" | adb shell sh -s 2>&1
        elif adb shell "su 0 id" </dev/null >/dev/null 2>&1; then
            printf '%s\n' "$1" | adb shell su 0 sh -s 2>&1
        else
            echo "[needs root - enable Settings -> System -> Developer options -> Rooted debugging]"
        fi
    }
else
    shrun() {
        if [ "$(id -u)" = "0" ]; then
            printf '%s\n' "$1" | sh -s 2>&1
        elif su 0 id </dev/null >/dev/null 2>&1; then
            printf '%s\n' "$1" | su 0 sh -s 2>&1
        else
            printf '%s\n' "$1" | sh -s 2>&1
        fi
    }

    shroot() {
        if [ "$(id -u)" = "0" ]; then
            printf '%s\n' "$1" | sh -s 2>&1
        elif su 0 id </dev/null >/dev/null 2>&1; then
            printf '%s\n' "$1" | su 0 sh -s 2>&1
        else
            echo "[needs root - run as root or enable Rooted debugging]"
        fi
    }
fi

echo "=== 1. BUILD, SLOT & BT/WCN NVRAM ==="
shrun '
echo "uid=$(id -u) slot=$(getprop ro.boot.slot_suffix) enforce=$(getenforce 2>&1)"
uptime
echo "sys=$(getprop ro.build.fingerprint)"
echo "vnd=$(getprop ro.vendor.build.fingerprint)"
'
shroot 'ls -la /data/vendor/bluetooth /mnt/vendor/productinfo/wcn 2>&1'
shrun 'getprop | grep -iE "ro\.bt\.|ro\.vendor\.mmi|persist\.sys\.audio|ro\.camerax|ro\.hardware\.audio|WIFI|wifi" | sort'

echo "=== 2. AUDIO HARDWARE, FLINGER & POLICY ==="
shroot 'cat /proc/asound/cards 2>&1; ls -la /dev/snd 2>&1'
shrun 'timeout 5 dumpsys media.audio_flinger 2>&1 | sed -n "1,120p"'
shrun 'timeout 5 dumpsys media.audio_policy 2>&1 | grep -iE "HW Module|Device|mix|port|whale|primary|a2dp|error" | head -n 50'

echo "=== 3. BLUETOOTH CRASH, TOMBSTONES & AUDIO LOGS ==="
shroot '
ls -lt /data/tombstones 2>&1 | head -n 10
LATEST=$(ls -t /data/tombstones/tombstone_* 2>/dev/null | head -n 1)
echo "latest_tombstone=$LATEST"
[ -n "$LATEST" ] && head -n 75 "$LATEST" 2>&1
'
shrun 'timeout 5 logcat -d -b main,system,crash -v brief | grep -iE "bt_stack|btif|bt_vendor|bluetooth|AudioSystem|listAudioPorts|audiofx" | tail -n 80'

echo "=== 4. HOTSPOT / TETHERING & BPF OFFLOAD ==="
shroot 'ls -la /sys/fs/bpf/net_shared /sys/fs/bpf/netd_shared 2>&1'
shrun 'timeout 5 dumpsys tethering 2>&1 | head -n 65'
shrun 'timeout 5 cmd wifi status 2>&1'
shrun 'timeout 5 logcat -d -b main,system -v brief | grep -iE "SoftAp|Tether|hostapd|BpfNetMaps|OffloadController|wifi_hal" | tail -n 50'

echo "=== 5. SENSORS (UNTRUNCATED LIST) ==="
shrun 'timeout 5 dumpsys sensorservice 2>&1 | grep -E "^0x|Total |Sensor Device:|Sensor List:|Proximity|proximity"'

echo "=== 6. CAMERA, GNSS, IMS, TELEPHONY & REMAINING HALS ==="
shrun 'timeout 5 dumpsys media.camera 2>&1 | grep -iE "Number of camera|Camera HAL|Device status|error traces|legacy" | head -n 30'
shrun 'timeout 5 dumpsys location 2>&1 | head -n 45'
shrun 'timeout 5 dumpsys isms 2>&1 | head -n 30'
shrun 'timeout 5 dumpsys phone 2>&1 | grep -iE "mIms|isVolte|isWifiCalling|isVt|mDataEnabled|isUserDataEnabled|mSimState|ActiveSubId" | head -n 30'
shrun 'timeout 5 logcat -d -b radio -v brief | grep -iE "SMS|CALL|DIAL|IMS|REG|DATA_CALL|ERROR|FAIL|http\.globe|www\.globe" | tail -n 50'
shroot '
echo "--- binder services (filtered) ---"
timeout 5 service list 2>&1 | grep -iE "vibrator|light|power|thermal|drm|media\.c2|gnss|audio|bluetooth|radio|ims|usb|camera|sensors|biometric|fingerprint" | sort
echo "--- lshal (filtered) ---"
timeout 5 lshal --types=h,b 2>&1 | grep -iE "gnss|thermal|vibrator|light|power|drm|media\.c2|omx|broadcastradio|bluetooth|audio|camera|sensors"
'
