#!/bin/bash

mkdir -p ${ROOTFS_DIR}/packages

# create swapfile to prevent crash on OOM (4GB)
sed -i 's/^CONF_SWAPSIZE=100/CONF_SWAPSIZE=4096/' ${ROOTFS_DIR}/etc/dphys-swapfile
sed -i 's/^#CONF_MAXSWAP=2048/CONF_MAXSWAP=16384/' ${ROOTFS_DIR}/etc/dphys-swapfile


# check for updates here! https://www.tp-link.com/en/support/download/omada-software-controller/
# Upstream sometimes change the filename supplied to wget after clicking the link so force saving
# with a consistent output file to prevent apt error: unsupported file ... given on commandline
OMADA_VERSION="6.1.0.19"
wget -O ${ROOTFS_DIR}/packages/Omada_SDN_Controller_v${OMADA_VERSION}_linux_x64.deb \
    https://static.tp-link.com/upload/software/2026/202601/20260121/Omada_Network_Application_v6.1.0.19_linux_x64_20260117100106.deb

# own debian package for jsvc
JSVC_VERSION=1.3.4
wget --directory-prefix=${ROOTFS_DIR}/packages \
    https://github.com/GeoffWilliams/jsvc-arm/releases/download/v${JSVC_VERSION}/jsvc-${JSVC_VERSION}_arm64.deb


on_chroot << EOF
# wonder why this is needed...?
# https://superuser.com/questions/1469602/tp-link-omada-controller-cannot-find-any-vm-in-java-home-usr-lib-jvm-default
mkdir /usr/lib/jvm/java-17-openjdk-arm64/lib/arm64
ln -s /usr/lib/jvm/java-17-openjdk-arm64/lib/server /usr/lib/jvm/java-17-openjdk-arm64/lib/arm64/

# nasty hack to prevent trying to run omada in quemu
mv /usr/bin/jsvc /usr/bin/jsvc.nouse
echo "exit 0" >> /usr/bin/jsvc
apt install -y /packages/Omada_SDN_Controller_v${OMADA_VERSION}_linux_x64.deb
mv /usr/bin/jsvc.nouse /usr/bin/jsvc
apt install -y /packages/jsvc-${JSVC_VERSION}_arm64.deb

EOF

install -m 644 files/motd "${ROOTFS_DIR}/etc/motd"

# Restore system defaults from stage0/00-configure-apt/00-run.sh
if [ -n "$APT_SOURCES" ]; then
	mv "${ROOTFS_DIR}/etc/apt/sources.list.final" "${ROOTFS_DIR}/etc/apt/sources.list"
fi

# omada self enables on boot so were done