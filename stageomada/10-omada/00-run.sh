#!/bin/bash

mkdir -p ${ROOTFS_DIR}/packages

# create swapfile to prevent crash on OOM (4GB)
sed -i 's/^CONF_SWAPSIZE=100/CONF_SWAPSIZE=4096/' ${ROOTFS_DIR}/etc/dphys-swapfile
sed -i 's/^#CONF_MAXSWAP=2048/CONF_MAXSWAP=16384/' ${ROOTFS_DIR}/etc/dphys-swapfile


# check for updates here! https://www.tp-link.com/en/support/download/omada-software-controller/
# Upstream sometimes change the filename supplied to wget after clicking the link so force saving
# with a consistent output file to prevent apt error: unsupported file ... given on commandline
OMADA_VERSION="5.13.23"
wget -O ${ROOTFS_DIR}/packages/Omada_SDN_Controller_v${OMADA_VERSION}_linux_x64.deb \
    https://static.tp-link.com/upload/software/2024/202401/20240112/Omada_SDN_Controller_v${OMADA_VERSION}_linux_x64.deb

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

# omada does something strange with the mongod binary
if [ -e /mongod ] ; then
    rm /mongod
fi
ln -s /usr/local/bin/mongod /opt/tplink/EAPController/bin/mongod

apt install -y /packages/jsvc-${JSVC_VERSION}_arm64.deb

EOF

mv ${ROOTFS_DIR}/opt/tplink/EAPController/bin/control.sh ${ROOTFS_DIR}/opt/tplink/EAPController/bin/control.sh.orig

install -m 644 files/motd "${ROOTFS_DIR}/etc/motd"
install -m 755 files/control.sh "${ROOTFS_DIR}/opt/tplink/EAPController/bin/control.sh"

# omada self enables on boot so were done