#!/bin/bash

# git clone https://github.com/bjornborg/bbb


systemctl enable ssh
systemctl start ssh

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
gcc-6 \
g++-6 \
python-pip \
docker-compose \
libusb-dev \
isc-dhcp-server \
iptables-persistent \
nmap \
libncurses5-dev
"
# npm \


# apt-get update
apt-get dist-upgrade -y
apt-get upgrade -y
apt-get install -y ${software}
apt-get autoremove -y
apt-get autoclean

# enable pi cam
raspi-config nonint do_camera 0

# Installing docker
curl -sSL https://get.docker.com | sh
usermod -aG docker pi

#enable wireless
echo -e 'network={\n    ssid="TME290_2"\n    psk="beaglebone"\n}' >> /etc/wpa_supplicant/wpa_supplicant.conf
wpa_cli -i wlan0 reconfigure

#dhcp
echo -e 'authoritative;\nsubnet 10.42.42.0 netmask 255.255.255.0 {\n    range 10.42.42.10 10.42.42.50;\n    option broadcast-address 10.42.42.255;\n    option routers 10.42.42.1;\n    default-lease-time 600;\n    max-lease-time 7200;\n    option domain-name "local";\n    option domain-name-servers 8.8.8.8, 8.8.4.4;\n}' >> /etc/dhcp/dhcpd.conf
sed -i  -e 's/option domain-name "example.org";/#option domain-name "example.org";/g' /etc/dhcp/dhcpd.conf
sed -i  -e 's/option domain-name-servers ns1.example.org, ns2.example.org;/#option domain-name-servers ns1.example.org, ns2.example.org;/g' /etc/dhcp/dhcpd.conf
echo -e 'interface eth1\nstatic ip_address=10.42.42.1/24' >> /etc/dhcpcd.conf
echo -e 'auto lo\niface lo inet loopback\nallow-hotplug eth1\nup iptables-restore < /etc/iptables.save' >> /etc/network/interfaces
sed -i -e 's/INTERFACESv4=""/INTERFACESv4="eth1"/g' /etc/default/isc-dhcp-server

cp /run/systemd/generator.late/isc-dhcp-server.service /etc/systemd/system
sed -i -e 's/Restart=no/Restart=on-failure\nRestartSec=5/g' /etc/systemd/system/isc-dhcp-server.service
echo -e '\n[Install]\nWantedBy=multi-user.target' >> /etc/systemd/system/isc-dhcp-server.service

# iptables
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo 1 > /proc/sys/net/ipv4/ip_forward

iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
iptables -A FORWARD -i wlan0 -o eth1 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth1 -o wlan0 -j ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o eth1 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
iptables-save > /etc/iptables/rules.v4

# mutlicast

# sed -i -e '/exit 0/isleep 30\nip route add 225.0.0.0\/24 dev eth2\nmodprobe bcm2835-v4l2\n' /etc/rc.local
sed -i '$isleep 30\nip route add 225.0.0.0\/24 dev eth2\nmodprobe bcm2835-v4l2' /etc/rc.local
systemctl daemon-reload
systemctl restart dhcpcd
systemctl restart isc-dhcp-server

# if the interface are swapped
# sed -i -e 's/eth1/eth2/g' /etc/dhcpcd.conf
# sed -i -e 's/eth1/eth2/g' /etc/network/interfaces
# sed -i -e 's/eth1/eth2/g' /etc/default/isc-dhcp-server
# sed -i -e 's/eth1/eth2/g' /etc/iptables/rules.v4
# sed -i -e 's/eth2/eth1/g' /etc/rc.local

# sed -i -e 's/eth2/eth1/g' /etc/dhcpcd.conf
# sed -i -e 's/eth2/eth1/g' /etc/network/interfaces
# sed -i -e 's/eth2/eth1/g' /etc/default/isc-dhcp-server
# sed -i -e 's/eth2/eth1/g' /etc/iptables/rules.v4
# sed -i -e 's/eth1/eth2/g' /etc/rc.local