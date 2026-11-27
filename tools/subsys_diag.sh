#!/bin/sh
adb wait-for-device
if [ "$(adb shell id -u </dev/null 2>/dev/null | tr -d '\r')" != "0" ]; then
    adb root 2>/dev/null
    sleep 2
    adb wait-for-device
fi

shrun() {
    adb shell "$1" </dev/null 2>&1
}

shroot() {
    if [ "$(adb shell id -u </dev/null 2>/dev/null | tr -d '\r')" = "0" ]; then
        adb shell "$1" </dev/null 2>&1
    elif adb shell "su 0 id" </dev/null >/dev/null 2>&1; then
        adb shell "su 0 sh -c '$1'" </dev/null 2>&1
    else
        echo "[needs root - enable Settings -> System -> Developer options -> Rooted debugging]"
    fi
}

echo "=== 1. STATUS, SELINUX & INTERFACES ==="
shrun 'echo "uid=$(id -u) slot=$(getprop ro.boot.slot_suffix) enforce=$(getenforce) sysfs=$(cat /sys/fs/selinux/enforce 2>/dev/null)"; uptime'
shrun 'ip -br link 2>/dev/null; echo "--- wlan0 addr/neigh/stats ---"; ip -4 addr show dev wlan0; ip -6 addr show dev wlan0; ip neigh show dev wlan0; grep . /sys/class/net/wlan0/statistics/rx_packets /sys/class/net/wlan0/statistics/tx_packets /sys/class/net/wlan0/statistics/rx_dropped /sys/class/net/wlan0/statistics/tx_dropped /sys/class/net/wlan0/statistics/rx_errors /sys/class/net/wlan0/statistics/tx_errors 2>/dev/null'
shrun 'echo "--- routes/rules ---"; ip route show table all | grep -E "wlan0|seth_lte|default" | head -n 25; ip rule show | head -n 20'

echo "=== 2. BPF & KERNEL CONFIG CHECK ==="
shroot 'ls -la /sys/fs/bpf /sys/fs/bpf/net_shared /sys/fs/bpf/netd_shared 2>&1 | head -n 30; getprop | grep -iE "bpf|netd|init\.svc\.(bpfloader|netd|network_stack|tethering)" | sort'
shroot '(zcat /proc/config.gz 2>/dev/null || cat /proc/config 2>/dev/null) | grep -E "CONFIG_(BPF|CGROUP_BPF|NET_CLS_BPF|NET_ACT_BPF|NETFILTER_XT_MATCH_BPF|INET_DIAG|NET_L3_MASTER_DEV|IPV6_ROUTER_PREF)" | head -n 40'

echo "=== 3. WIFI, NETWORKSTACK & CONNECTIVITY LOGS ==="
shrun 'timeout 5 cmd wifi status 2>&1'
shrun 'timeout 5 dumpsys network_stack 2>&1 | grep -iE "IpClient\.wlan0|DhcpClient|IpReachability|NUD_|provisioning|Apf|filter|Capabilities|state:|FAIL|ERROR|192\.168" | tail -n 50'
shrun 'timeout 5 dumpsys connectivity 2>&1 | grep -iE "NetworkAgent|WIFI|wlan0|seth_lte|VALIDATED|LOST|PARTIAL|SUSPENDED|CaptivePortal" | head -n 30'
shrun 'timeout 5 logcat -d -b main,system,events -v brief | grep -iE "Wifi|wpa_supplicant|halutil|WifiChip|WifiIface|WifiLegacyHal|SetUpState|SetMacAddress|IpClient|DhcpClient|IpReachability|NetworkMonitor|ConnectivityService|Netd|Bpf|Apf|sprd" | tail -n 120'

echo "=== 4. TELEPHONY, CALLS & SMS ==="
shrun 'timeout 5 dumpsys telephony.registry 2>&1 | grep -iE "mServiceState|mDataConnectionState|mCallState|mSignalStrength|PhoneId|subId|RegState|ims" | head -n 30'
shrun 'timeout 5 dumpsys isub 2>&1 | grep -iE "Subscription|SubId|SimSlot|CarrierName|Number|Mcc|Mnc" | head -n 20'
shrun 'timeout 5 dumpsys phone 2>&1 | grep -iE "mDataEnabled|isUserDataEnabled|isVolte|isWifiCalling|mSimState|ActiveSubId" | head -n 20'
shrun 'timeout 5 logcat -d -b radio -v brief | tail -n 70'

echo "=== 5. AUDIO, CAMERA, SENSORS & FINGERPRINT ==="
shrun 'echo "--- audio ---"; timeout 5 dumpsys media.audio_flinger 2>&1 | grep -iE "Hardware status|Standby|thread|whale|a2dp|AudioFlinger|Sample rate|error" | head -n 20; timeout 5 dumpsys media.audio_policy 2>&1 | grep -iE "whale|primary|a2dp|Device|error" | head -n 15'
shrun 'echo "--- camera ---"; timeout 5 dumpsys media.camera 2>&1 | grep -iE "Number of camera|Camera [0-9]|Status:|Provider|legacy|error" | head -n 25'
shrun 'echo "--- sensors ---"; timeout 5 dumpsys sensorservice 2>&1 | head -n 30'
shrun 'echo "--- fingerprint/biometric ---"; timeout 5 dumpsys fingerprint 2>&1 | head -n 20; timeout 5 dumpsys biometric 2>&1 | head -n 20'

echo "=== 6. DMESG & LOGCAT ERRORS ==="
shroot 'dmesg | grep -iE "wcn|marlin|wlan|sprdwl|sprd_wlan|ttyBT|sprdbt|rfkill|bpf|sipc|seth|ims_bridge|modem|insmod|avc:|firmware|sensorhub|goodix|silead|whale|aw87|cam|isp" | tail -n 110'
shrun 'echo "--- logcat crash ---"; timeout 5 logcat -d -b crash -v brief | tail -n 40'
shrun 'echo "--- logcat errors ---"; timeout 5 logcat -d -b main,system -v brief | grep -iE "^[EFW]/" | grep -iE "wifi|supplicant|network|dhcp|ipclient|netd|bpf|bluetooth|bt_|ril|telephony|ims|audio|whale|camera|sensor|fingerprint|biometric|avc:|linker|dlopen" | tail -n 100'
shroot 'ls -lt /data/tombstones 2>&1 | head -n 10'
