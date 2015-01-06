#!/bin/bash
sudo apt-get update
sudo apt-get install -y ubuntu-standard ubuntu-minimal htop git net-tools aptitude apache2 php5 libapache2-mod-php5 php5-cgi ruby screen fish sudo mc iotop iftop software-properties-common python-fcgi ruby-fcgi
wget -O - http://nodejs.org/dist/v0.10.26/node-v0.10.26-linux-x64.tar.gz | sudo tar -C /usr/local/ --strip-components=1 -zxv

sudo apt-get install -y ruby-dev ri rake python mercurial subversion cvs bzr default-jdk golang-go
sudo apt-get install --only-upgrade bash
sudo apt-get clean

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
