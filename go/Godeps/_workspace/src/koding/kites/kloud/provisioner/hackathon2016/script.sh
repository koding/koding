#!/bin/bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

sudo -E apt-get update -q
sudo -E apt-get install -y -q ubuntu-standard ubuntu-minimal htop git net-tools \
	aptitude apache2 screen fish sudo mc iotop iftop software-properties-common \
	silversearcher-ag mercurial subversion cvs bzr

sudo -E apt-get install --only-upgrade bash

# add this for backwards compability with our cloud-init script. Cloud
# init tries to add the user to the docker group, but if it doesn't
# exists it fails. Remove this once we enable docker again (by
# uncommenting the text below)
sudo groupadd docker

# docker
#sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
#sudo mkdir -p /etc/apt/sources.list.d
#sudo sh -c "echo deb https://get.docker.com/ubuntu docker main > /etc/apt/sources.list.d/docker.list"
#sudo apt-get update
#sudo apt-get install -y lxc-docker

# configure locale
sudo locale-gen "en_US.UTF-8"

# remove installed packages to free up space
sudo apt-get clean

# ensure we have the apt-get index already downloaded so sudo apt-get install
# is going to work for the first time command on the vm
sudo apt-get update -q

# update and rebuild index for locate command
sudo updatedb

# website template
sudo a2enmod cgi
sudo a2enmod rewrite
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod proxy_wstunnel
sudo a2enmod proxy_fcgi

mkdir -p /tmp/userdata/{Web,bash,screen,kodingart,etc/apt}

sudo mkdir -p /opt/koding/userdata/{Web,Applications,Backup,Documents} \
	/opt/koding/etc/ \
	/etc/koding \
