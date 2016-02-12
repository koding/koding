#!/bin/bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

sudo -E apt-get update -q
sudo -E apt-get install -y -q ubuntu-standard ubuntu-minimal htop git net-tools \
	aptitude apache2 php5 libapache2-mod-php5 php5-cgi ruby screen fish sudo \
	mc iotop iftop software-properties-common python-fcgi ruby-fcgi \
	silversearcher-ag ruby-dev ri rake python mercurial subversion cvs bzr \
	default-jdk golang-go

sudo -E apt-get install --only-upgrade bash

wget -q -O - http://nodejs.org/dist/v0.10.26/node-v0.10.26-linux-x64.tar.gz | sudo tar -C /usr/local/ --strip-components=1 -zxv

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

# update and rebuild index for locate command
sudo updatedb

# install kpm
cd /usr/local/bin
sudo wget -q https://github.com/koding/kpm-scripts/releases/download/v0.2.2/kpm
sudo chmod +x /usr/local/bin/kpm

# website template
sudo a2enmod cgi
sudo a2enmod rewrite
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod proxy_wstunnel
sudo a2enmod proxy_fcgi

mkdir -p /tmp/userdata/Web
mkdir -p /tmp/userdata/bash
mkdir -p /tmp/userdata/screen
mkdir -p /tmp/userdata/kodingart

sudo mkdir -p /opt/koding/userdata/
sudo mkdir -p /opt/koding/userdata/Web
sudo mkdir -p /opt/koding/userdata/Applications
sudo mkdir -p /opt/koding/userdata/Backup
sudo mkdir -p /opt/koding/userdata/Documents
sudo mkdir -p /opt/koding/etc/
sudo mkdir -p /etc/koding
