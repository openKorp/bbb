#!/bin/bash

# git clone https://github.com/bjornborg/bbb


user=( debian )


apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y
apt-get autoremove -y
apt-get autoclean


software=" \
bash-completion \
ccache \
cmake \
netcat \
git \
i2c-tools \
nano \
screen \
vim \
wget \
python-pip \
libusb-dev \
nmap \
iptables-persistent \
libncurses5-dev
"
# npm \
# docker-compose \
# apt-get update
# apt-get upgrade
# apt-get dist-upgrade -y

apt-get install -y ${software}
# Add unstable branch
# echo "deb http://ftp.us.debian.org/debian unstable main contrib non-free" > /etc/apt/sources.list.d/unstable.list
# echo "Package: * Pin: release a=testing Pin-Priority: 100" > /etc/apt/preferences.d/unstable
# apt-get update
# apt-get install gcc-8 g++-8 

# Create swapfile
fallocate -l 512M /var/swapfile
chmod 600 /var/swapfile
mkswap /var/swapfile
swapon /var/swapfile
echo -e "/var/swapfile\tnone\tswap\tdefaults\t0 0" >> /etc/fstab

# Format sdcard
(echo d; echo n; echo p; echo ""; echo ""; echo ""; echo w) | fdisk /dev/mmcblk0
(echo y) | mkfs.ext4 /dev/mmcblk0p1
mkdir /mnt/sdcard
mount /dev/mmcblk0p1 /mnt/sdcard
echo "/dev/mmcblk0p1  /mnt/sdcard  ext4  defaults  0 2" >> /etc/fstab

mkdir /mnt/sdcard/users
for (( i = 0; i < ${#user[@]}; i++ )); do
  mkdir /mnt/sdcard/users/${user[$i]}
  chown -R ${user[$i]}:users /mnt/sdcard/users/${user[$i]}
  su -c "ln -s /mnt/sdcard/users/${user[$i]} /home/${user[$i]}/sdcard" -s /bin/bash ${user[$i]}
done


# Installing docker
curl -sSL https://get.docker.com | sh
usermod -aG docker debian
# pip install docker-compose
systemctl stop docker.service
#/lib/systemd/system/docker.service
sed -i -e 's/\/usr\/bin\/dockerd -H fd:\/\//\/usr\/bin\/dockerd -g \/mnt\/sdcard\/docker\/ -H fd:\/\//g' /lib/systemd/system/docker.service
systemctl daemon-reload
systemctl start docker.service
pip install docker-compose

# Update scripts
cd /opt/scripts/boot/
git pull
cd 
sed -i -e 's/\/sbin\/ifconfig usb1 192.168.6.2 netmask 255.255.255.252 || true/#\/sbin\/ifconfig usb1 192.168.6.2 netmask 255.255.255.252 || true/g' /opt/scripts/boot/autoconfigure_usb1.sh
echo 'dhclient usb1' >> /opt/scripts/boot/autoconfigure_usb1.sh

sed -i -e 's/#timeout 60;/timeout 300;/g' /etc/dhcp/dhclient.conf 
sed -i -e 's/#retry 60;/retry 10;/g' /etc/dhcp/dhclient.conf 

# Networking
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -o usb1 -j MASQUERADE
iptables -A FORWARD -i usb1 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i wlan0 -o usb1 -j ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT
iptables-save > /etc/iptables/rules.v4
echo 'ip route add 225.0.0.0/24 dev wlan0' >> /opt/scripts/boot/autoconfigure_usb0.sh

#
# git clone https://github.com/bjornborg/bbb.git
