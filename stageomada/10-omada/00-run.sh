#!/bin/bash
# https://www.tp-link.com/au/support/download/omada-software-controller/#Controller_Software
on_chroot << EOF
mkdir -p /packages
cd /packages


wget https://static.tp-link.com/upload/software/2023/202309/20230920/Omada_SDN_Controller_v5.12.7_Linux_x64.deb

# wonder why this is needed...?
# https://superuser.com/questions/1469602/tp-link-omada-controller-cannot-find-any-vm-in-java-home-usr-lib-jvm-default
mkdir /usr/lib/jvm/java-17-openjdk-arm64/lib/arm64
ln -s /usr/lib/jvm/java-17-openjdk-arm64/lib/server /usr/lib/jvm/java-17-openjdk-arm64/lib/arm64/

# nasty hack to prevent trying to run omada in quemu
mv /usr/bin/jsvc /usr/bin/jsvc.nouse
echo "exit 0" >> /usr/bin/jsvc
apt install -y ./Omada_SDN_Controller_v5.12.7_Linux_x64.deb
mv /usr/bin/jsvc.nouse /usr/bin/jsvc

# omada does something strange with the mongod binary
if [ -e /mongod ] ; then
    rm /mongod
fi
ln -s /usr/local/bin/mongod /opt/tplink/EAPController/bin/mongod

# omada self enables on boot so were done
EOF