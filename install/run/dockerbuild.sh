#!/bin/bash

# ARGUMENTS MUST BE PASSED IN THIS ORDER: #{hostname} #{region} #{config} #{branch}

mkdir /root/BUILD_DATA

echo $1 >/root/BUILD_DATA/BUILD_HOSTNAME
echo $2 >/root/BUILD_DATA/BUILD_REGION
echo $3 >/root/BUILD_DATA/BUILD_CONFIG
echo $4 >/root/BUILD_DATA/BUILD_BRANCH

echo '{"https://index.docker.io/v1/":{"auth":"ZGV2cmltOm45czQvV2UuTWRqZWNq","email":"devrim@koding.com"}}' > /root/.dockercfg

echo '#!/bin/sh -e' >/etc/rc.local
echo "iptables -F" >>/etc/rc.local
echo "iptables -A INPUT -i lo -j ACCEPT" >>/etc/rc.local
echo "iptables -A INPUT -s 208.72.139.54 -j ACCEPT" >>/etc/rc.local
echo "iptables -A INPUT -s 70.197.5.50 -j ACCEPT" >>/etc/rc.local
echo "iptables -A INPUT -s 208.87.56.148 -j ACCEPT" >>/etc/rc.local
echo "iptables -A INPUT -s 208.87.59.205 -j ACCEPT" >>/etc/rc.local
echo "iptables -A INPUT -s 94.54.193.66 -j ACCEPT" >>/etc/rc.local
echo "iptables -A INPUT -s 78.184.209.65 -j ACCEPT" >>/etc/rc.local
echo "iptables -A INPUT -s 68.68.97.155 -j ACCEPT" >>/etc/rc.local
echo "iptables -A INPUT -s 85.107.151.5 -j ACCEPT" >>/etc/rc.local
echo "iptables -A INPUT -p tcp --dport 4000 -j ACCEPT" >>/etc/rc.local
echo "iptables -A INPUT -p tcp --dport 3999 -j ACCEPT" >>/etc/rc.local
echo "iptables -A INPUT -p tcp --dport 3000 -j ACCEPT" >>/etc/rc.local
echo "iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT" >>/etc/rc.local
echo "iptables -A INPUT -j DROP" >>/etc/rc.local
/etc/rc.local


# REGISTER THESE PUBLIC KEYS
mkdir /root/.ssh
# DEVRIM
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGy37UYYQjRUyBZ1gYERhmOcyRyF0pFvlc+d91VT6iiIituaR+SpGruyj3NSmTZQ8Px8/ebaIJQaV+8v/YyIJXAQoCo2voo/OO2WhVIzv2HUfyzXcomzV40sd8mqZJnNCQYdxkFbUZv26kOzikie0DlCoVstM9P8XAURSszO0llD4f0CKS7Galwql0plccBxJEK9oNWCMp3F6v3EIX6qdL8eUJko7tJDPiyPIuuaixxd4EBE/l2UBGvqG0REoDrBNJ8maKV3CKhw60LYis8EfKFhQg5055doDNxKSDiCMopXrfoiAQKEJ92MBTjs7YwuUDp5s39THbX9bHoyanbVIL devrim@koding.com" >>/root/.ssh/authorized_keys

apt-get update
apt-get install -y curl
curl -s https://get.docker.io/ubuntu/ | sudo sh

echo "UTC" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

cd /root
docker build -t koding/codebase .

