#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# GSI AVB keys: the stock vendor_boot ramdisk carries
# /avb/{q,r,s}-gsi.avbpubkey, so as long as you keep the stock vendor_boot
# (bring-up path A in docs/BRINGUP.md) nothing needs to be installed here.
# There is no gsi_keys.mk in lineage-20.0; the closest thing is
# $(SRC_TARGET_DIR)/product/developer_gsi_keys.mk, which installs the
# *developer* GSI keys under different file names. Only inherit it if you
# actually intend to boot a developer GSI with verified boot.

# Inherit from the Infinix X6525 device tree.
$(call inherit-product, device/infinix/X6525/device.mk)

# Lunaris-AOSP configuration
WITH_GMS ?= true
WITH_PIXEL_LAUNCHER := false
WITH_BCR := true
TARGET_BOOT_ANIMATION_RES := 720
TARGET_FACE_UNLOCK_SUPPORTED := true
TARGET_ENABLE_BLUR := true
TARGET_SUPPORTED_REFRESH_RATES := 60,90
USE_REALITY_ENGINE := true
USE_ADVANCED_DISPLAY_COLOR := true
SURFACE_FLINGER_BOOST := true
TARGET_OPTIMIZED_DEXOPT := true
# Enabled: Helix kernel >= 7a2dd7657 builds CONFIG_USB_CONFIGFS_F_UVC=y
TARGET_BUILD_DEVICE_AS_WEBCAM := true

# Inherit some common Lineage/Lunaris stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

PRODUCT_DEVICE := X6525
PRODUCT_NAME := lineage_X6525
PRODUCT_BRAND := Infinix
PRODUCT_MODEL := Infinix X6525
PRODUCT_MANUFACTURER := Infinix

PRODUCT_GMS_CLIENTID_BASE := android-transsion
