#!/usr/bin/env python3
"""
Post-process a built LunarisOS/Android 16 vendor.img for Infinix X6525 (VNDK v33):
1. Removes Android 16 VNDK libraries from /vendor/lib{,64}/ that shadow
   /apex/com.android.vndk.v33/lib{,64}/ (fixing libapexsupport.so and libbase ABI breaks).
2. Restores stock VNDK v33 binaries and libraries from vendor/infinix/X6525/proprietary/vendor/.
3. Installs missing stock protobuf-3.9.1, wifi keystore, and wifi@1.0..1.6 HIDL libraries.
4. Replaces Android 16 wifi/supplicant manifests & rc with stock VNDK v33 wifi@1.0 + supplicant v1.
5. Syncs init.X6525.rc (${ro.bootmode:-normal}, watchdogd disabled, bootlog_meta clean) and
   bundles ufs-sprd_qogirl6.ko in init.insmod.sh (preserving full stock module load order).
6. Merges platform /vendor file_contexts + vendor_file_contexts so every inode gets proper SELinux xattrs.
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile


def main():
    if len(sys.argv) < 3:
        sys.exit(f"Usage: {sys.argv[0]} <in_vendor.img> <out_vendor.img> [android_top]")
    in_img = os.path.abspath(sys.argv[1])
    out_img = os.path.abspath(sys.argv[2])
    top = os.path.abspath(sys.argv[3]) if len(sys.argv) > 3 else "/workspaces/lunaris-16.2"

    prop = os.path.join(top, "vendor/infinix/X6525/proprietary/vendor")
    vndk_root = os.path.join(top, "prebuilts/vndk/v33/arm64")
    ufs_ko = os.path.join(top, "device/infinix/X6525/prebuilts/modules/ufs-sprd_qogirl6.ko")
    plat_fc = os.path.join(top, "system/sepolicy/private/file_contexts")

    vndk64, vndk32 = set(), set()
    for sub in ("vndk-core", "vndk-sp"):
        p64 = os.path.join(vndk_root, "arch-arm64-armv8-a/shared", sub)
        p32 = os.path.join(vndk_root, "arch-arm-armv8-a/shared", sub)
        if os.path.isdir(p64):
            vndk64.update(os.listdir(p64))
        if os.path.isdir(p32):
            vndk32.update(os.listdir(p32))

    with tempfile.TemporaryDirectory(prefix="x6525_vndk33_") as tmp:
        root = os.path.join(tmp, "v")
        subprocess.run(["fsck.erofs", f"--extract={root}", in_img], check=True)
        os.chmod(root, 0o755)

        removed = 0
        for arch, vndk in (("lib64", vndk64), ("lib", vndk32)):
            for fn in list(os.listdir(os.path.join(root, arch))):
                if fn in vndk and not os.path.exists(os.path.join(prop, arch, fn)):
                    os.unlink(os.path.join(root, arch, fn))
                    removed += 1

        restored_bin, restored_lib = 0, 0
        for sub in ("bin", "bin/hw"):
            pdir = os.path.join(prop, sub)
            if not os.path.isdir(pdir):
                continue
            for fn in os.listdir(pdir):
                src, dst = os.path.join(pdir, fn), os.path.join(root, sub, fn)
                if os.path.isfile(src) and not os.path.islink(src) and os.path.isfile(dst) and not os.path.islink(dst):
                    if os.path.getsize(src) != os.path.getsize(dst):
                        shutil.copy2(src, dst)
                        os.chmod(dst, 0o755)
                        restored_bin += 1

        for arch in ("lib64", "lib", "lib64/hw", "lib/hw"):
            pdir = os.path.join(prop, arch)
            if not os.path.isdir(pdir):
                continue
            for fn in os.listdir(pdir):
                src, dst = os.path.join(pdir, fn), os.path.join(root, arch, fn)
                if os.path.isfile(src) and not os.path.islink(src) and os.path.isfile(dst) and not os.path.islink(dst):
                    if os.path.getsize(src) != os.path.getsize(dst):
                        shutil.copy2(src, dst)
                        os.chmod(dst, 0o644)
                        restored_lib += 1

        extra = [
            ("lib", "libprotobuf-cpp-lite-3.9.1.so"),
            ("lib", "libprotobuf-cpp-full-3.9.1.so"),
            ("lib64", "libprotobuf-cpp-lite-3.9.1.so"),
            ("lib64", "libprotobuf-cpp-full-3.9.1.so"),
            ("lib64", "libkeystore-wifi-hidl.so"),
            ("lib64", "libkeystore-engine-wifi-hidl.so"),
            ("lib64", "android.hardware.wifi@1.0.so"),
            ("lib64", "android.hardware.wifi@1.1.so"),
            ("lib64", "android.hardware.wifi@1.2.so"),
            ("lib64", "android.hardware.wifi@1.3.so"),
            ("lib64", "android.hardware.wifi@1.4.so"),
            ("lib64", "android.hardware.wifi@1.5.so"),
            ("lib64", "android.hardware.wifi@1.6.so"),
        ]
        for arch, fn in extra:
            src, dst = os.path.join(prop, arch, fn), os.path.join(root, arch, fn)
            if os.path.isfile(src) and not os.path.exists(dst):
                shutil.copy2(src, dst)
                os.chmod(dst, 0o644)

        # Replace Android 16 AIDL wifi HAL + v4 supplicant manifest with stock VNDK v33 HIDL 1.6 wifi + v1 supplicant
        for stale in (
            "bin/hw/android.hardware.wifi-service-lazy",
            "etc/init/android.hardware.wifi-service-lazy.rc",
            "etc/vintf/manifest/android.hardware.wifi-service.xml",
            "etc/vintf/manifest/android.hardware.wifi.xml",
        ):
            p = os.path.join(root, stale)
            if os.path.exists(p):
                os.unlink(p)
        for rel, mode in (
            ("bin/hw/android.hardware.wifi@1.0-service-lazy", 0o755),
            ("etc/init/android.hardware.wifi@1.0-service-lazy.rc", 0o644),
            ("etc/vintf/manifest/android.hardware.wifi@1.0-service.xml", 0o644),
            ("etc/init/android.hardware.wifi.supplicant-service.rc", 0o644),
            ("etc/vintf/manifest/android.hardware.wifi.supplicant.xml", 0o644),
        ):
            src, dst = os.path.join(prop, rel), os.path.join(root, rel)
            if os.path.isfile(src):
                shutil.copy2(src, dst)
                os.chmod(dst, mode)

        # Sync init.X6525.rc (${ro.bootmode:-normal}, watchdogd disabled, bootlog_meta clean)
        rc_src = os.path.join(prop, "etc/init/hw/init.X6525.rc")
        if os.path.isfile(rc_src):
            shutil.copy2(rc_src, os.path.join(root, "etc/init/hw/init.X6525.rc"))
            os.chmod(os.path.join(root, "etc/init/hw/init.X6525.rc"), 0o644)

        # Bundle ufs-sprd_qogirl6.ko in exact stock load order (proven in 30324dac), drop verbose -s flag
        if os.path.isfile(ufs_ko):
            shutil.copy2(ufs_ko, os.path.join(root, "lib/ufs-sprd_qogirl6.ko"))
            os.chmod(os.path.join(root, "lib/ufs-sprd_qogirl6.ko"), 0o644)
            insmod_sh = os.path.join(root, "bin/init.insmod.sh")
            if os.path.isfile(insmod_sh):
                txt = open(insmod_sh).read()
                hook = "insmod /vendor/lib/ufs-sprd_qogirl6.ko 2>/dev/null || true\n"
                if hook not in txt:
                    txt = txt.replace("if [ -f $cfg_file ]; then\n", hook + "if [ -f $cfg_file ]; then\n", 1)
                txt = txt.replace("modprobe -s -a -d", "modprobe -a -d")
                open(insmod_sh, "w").write(txt)
                os.chmod(insmod_sh, 0o755)

        for sub in ("bin", "bin/hw"):
            for fn in os.listdir(os.path.join(root, sub)):
                p = os.path.join(root, sub, fn)
                if os.path.isfile(p) and not os.path.islink(p):
                    os.chmod(p, 0o755)

        # Build merged file_contexts (platform /vendor base rules + vendor_file_contexts)
        v_fc = os.path.join(root, "etc/selinux/vendor_file_contexts")
        merged_fc = os.path.join(tmp, "merged_file_contexts")
        with open(merged_fc, "w") as out_f:
            if os.path.isfile(plat_fc):
                for line in open(plat_fc):
                    if re.match(r"^/(vendor|\(vendor\|system/vendor\))", line):
                        out_f.write(line)
            out_f.write("\n")
            out_f.write(open(v_fc).read())

        if os.path.exists(out_img):
            os.unlink(out_img)
        subprocess.run(
            ["mkfs.erofs", "-zlz4", "--all-root", "--mount-point=/vendor", f"--file-contexts={merged_fc}", out_img, root],
            check=True,
        )
        subprocess.run(["fsck.erofs", out_img], check=True)
        print(f"Done: removed {removed} shadowed VNDK libs, restored {restored_bin} bins + {restored_lib} libs -> {out_img}")


if __name__ == "__main__":
    main()
