#!/bin/bash -e

install -m 644 files/sources.list "${ROOTFS_DIR}/etc/apt/"
install -m 644 files/raspi.list "${ROOTFS_DIR}/etc/apt/sources.list.d/"
sed -i "s/RELEASE/${RELEASE}/g" "${ROOTFS_DIR}/etc/apt/sources.list"
sed -i "s/RELEASE/${RELEASE}/g" "${ROOTFS_DIR}/etc/apt/sources.list.d/raspi.list"

if [ -n "$APT_PROXY" ]; then
	echo "support for APT_PROXY was removed. Update your build"
	exit 1
fi

if [ -n "$APT_SOURCES" ]; then
	# cleaned up in stageomada
	mv "${ROOTFS_DIR}/etc/apt/sources.list" "${ROOTFS_DIR}/etc/apt/sources.list.final"
	echo "$APT_SOURCES" > "${ROOTFS_DIR}/etc/apt/sources.list"
	echo "using APT_SOURCES"
	cat "${ROOTFS_DIR}/etc/apt/sources.list"
fi

echo "apt sources.list for this build:"
cat "${ROOTFS_DIR}/etc/apt/sources.list"

cat files/raspberrypi.gpg.key | gpg --dearmor > "${STAGE_WORK_DIR}/raspberrypi-archive-stable.gpg"
install -m 644 "${STAGE_WORK_DIR}/raspberrypi-archive-stable.gpg" "${ROOTFS_DIR}/etc/apt/trusted.gpg.d/"
on_chroot <<- \EOF
	ARCH="$(dpkg --print-architecture)"
	if [ "$ARCH" = "armhf" ]; then
		dpkg --add-architecture arm64
	elif [ "$ARCH" = "arm64" ]; then
		dpkg --add-architecture armhf
	fi
	apt-get update
	apt-get dist-upgrade -y
EOF
