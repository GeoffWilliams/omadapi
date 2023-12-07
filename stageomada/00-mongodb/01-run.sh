#!/bin/bash
#
# https://github.com/themattman/mongodb-raspberrypi-binaries provides arm64 binaries but not for 4.4:
# * https://github.com/themattman/mongodb-raspberrypi-binaries/issues/6
#
# So i create my own package (USE AT OWN RISK!)
# * https://github.com/GeoffWilliams/mongodb-raspberrypi-binaries/releases/tag/v4.4.26

on_chroot << EOF
mkdir -p /packages
cd /packages
curl -LO https://github.com/GeoffWilliams/mongodb-raspberrypi-binaries/releases/download/v4.4.26/mongodb-org-server-raspberrypi_4.4.26_arm64.deb
apt install -y /packages/mongodb-org-server-raspberrypi_4.4.26_arm64.deb
EOF

