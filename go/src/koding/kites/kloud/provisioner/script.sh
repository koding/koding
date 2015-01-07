#!/bin/bash
sudo apt-get update
sudo apt-get install -y ubuntu-standard ubuntu-minimal htop git net-tools aptitude apache2 php5 libapache2-mod-php5 php5-cgi ruby screen fish sudo mc iotop iftop software-properties-common python-fcgi ruby-fcgi
wget -O - http://nodejs.org/dist/v0.10.26/node-v0.10.26-linux-x64.tar.gz | sudo tar -C /usr/local/ --strip-components=1 -zxv

sudo apt-get install -y ruby-dev ri rake python mercurial subversion cvs bzr default-jdk golang-go
sudo apt-get install --only-upgrade bash


# docker
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
sudo mkdir -p /etc/apt/sources.list.d
sudo sh -c "echo deb https://get.docker.com/ubuntu docker main > /etc/apt/sources.list.d/docker.list"
sudo apt-get update
sudo apt-get install -y lxc-docker

# remove installed packages to free up space
sudo apt-get clean

# website template
sudo a2enmod cgi
sudo a2enmod rewrite
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod proxy_wstunnel
sudo a2enmod proxy_fcgi

mkdir -p /tmp/userdata/Web
mkdir -p /tmp/userdata/bash
mkdir -p /tmp/userdata/kodingart

sudo mkdir -p /opt/koding/userdata/
sudo mkdir -p /opt/koding/userdata/Web
sudo mkdir -p /opt/koding/userdata/Applications
sudo mkdir -p /opt/koding/userdata/Backup
sudo mkdir -p /opt/koding/userdata/Documents
sudo mkdir -p /etc/koding
