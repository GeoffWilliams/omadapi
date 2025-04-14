#!/bin/bash
#
# Good news! Raspberry Pi 5 and Omada 20.15.20+ can use official mongo 8 arm64 binaries
# There are some gotchas for PI4 discussed at: 
# https://github.com/themattman/mongodb-raspberrypi-binaries provides arm64 binaries but not for 4.4:
#
# So from now on just support Pi 5 - since there's only one person I know with a Pi4 running this
# I'll gift him a pi5 and save my headaches!!!
#
# Official mongo releases are here: https://www.mongodb.com/try/download/community-edition/releases
# we can just use the Ubuntu 20.04 ARM64 image on Raspberry Pi OS/Debian 12 - it seems to work :)
on_chroot << EOF
mkdir -p /packages
cd /packages
curl -LO https://repo.mongodb.org/apt/ubuntu/dists/focal/mongodb-org/8.0/multiverse/binary-arm64/mongodb-org-server_8.0.6_arm64.deb
apt install -y /packages/mongodb-org-server_8.0.6_arm64.deb
EOF
