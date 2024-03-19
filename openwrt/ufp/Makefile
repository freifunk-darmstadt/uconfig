#
# Copyright (C) 2024 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=ufp
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL=$(PROJECT_GIT)/project/ufp.git
PKG_MIRROR_HASH:=42a7774cb1aeda9aaf16bdcb4ace8d79542e22c9e91144596d0ad29523c0fcba
PKG_SOURCE_DATE:=2024-01-17
PKG_SOURCE_VERSION:=238acb305b2d702753de5386e129bdd35fec1321

PKG_LICENSE:=GPL-2.0
PKG_MAINTAINER:=Felix Fietkau <nbd@nbd.name>

HOST_BUILD_DEPENDS:=ucode/host libubox/host
PKG_BUILD_DEPENDS:=bpf-headers ufp/host

CMAKE_SOURCE_SUBDIR:=src

include $(INCLUDE_DIR)/host-build.mk
include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/ufp
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Device fingerprinting daemon
  DEPENDS:=+ucode +ucode-mod-fs +ucode-mod-nl80211 +ucode-mod-rtnl +ucode-mod-uloop +ucode-mod-struct +libubox
endef

define Package/ufp/conffiles
/etc/config/ufp
endef

define Package/ufp/install
	$(INSTALL_DIR) $(1)/usr/lib/ucode $(1)/usr/share/ufp
	$(INSTALL_DATA) $(PKG_INSTALL_DIR)/usr/lib/ucode/uht.so $(1)/usr/lib/ucode/
	ucode $(PKG_BUILD_DIR)/scripts/convert-devices.uc $(1)/usr/share/ufp/devices.bin $(PKG_BUILD_DIR)/data/*.json
	$(CP) $(PKG_BUILD_DIR)/files/* $(1)/
endef

$(eval $(call BuildPackage,ufp))
$(eval $(call HostBuild))
