#!/bin/bash

YUM="yum --assumeyes"

$YUM update

# System-wide configuration

ln -fs /usr/share/zoneinfo/UTC /etc/localtime


## Kernel parameters

### Network

cat - > /etc/sysctl.d/network.conf <<EOF
# Recycle network sockets in TIME_WAIT state
net.ipv4.tcp_tw_recycle = 1

# Reuse network sockets in TIME_WAIT state
net.ipv4.tcp_tw_reuse = 1

# Increase TIME_WAIT socket bucket count
net.ipv4.tcp_max_tw_buckets = 180000
EOF

sysctl -p /etc/sysctl.d/network.conf

## ulimit

echo '* - nofile 65535' > /etc/security/limits.d/nofile


# Common packages

$YUM install htop sysstat dstat
$YUM install telnet


# Version controlling packages

$YUM install git patch


# nginx

$YUM install nginx


# node.js

$YUM --enablerepo=epel install nodejs-0.10.36

## npm

$YUM --enablerepo=epel install npm

npm install --global npm@2.*

## CoffeeScript

npm install --global coffee-script@1.8.0

## gulp

npm install --global gulp@3.9.0


# golang

GO_VERSION="1.4.2"
GO_TARBALL="go$GO_VERSION.linux-amd64.tar.gz"
GO_SRC_URL="https://storage.googleapis.com/golang/$GO_TARBALL"
curl --silent $GO_SRC_URL | tar --extract --gzip --directory=/usr/local

echo "export PATH=$PATH:/usr/local/go/bin" > /etc/profile.d/golang.sh
chmod +x /etc/profile.d/golang.sh

source /etc/profile

go version


# supervisor

pip install supervisor


# Miscellaneous

$YUM install graphviz

pip install psutil superlance


# Logs

mkdir -p /var/log/supervisord
mkdir -p /var/log/koding

## Papertrail

REMOTE_SYSLOG_VERSION="v0.16"
REMOTE_SYSLOG_GITHUB_URL="https://github.com/papertrail/remote_syslog2"
REMOTE_SYSLOG_FILENAME="remote_syslog_linux_amd64.tar.gz"
REMOTE_SYSLOG_TARBALL_URL="$REMOTE_SYSLOG_GITHUB_URL/releases/download/$REMOTE_SYSLOG_VERSION/$REMOTE_SYSLOG_FILENAME"

curl --silent --location $REMOTE_SYSLOG_TARBALL_URL | tar --verbose --extract --gzip --directory=/usr/local

chkconfig remote_syslog on


# File variables

## Local variables:
## eval: (outline-minor-mode)
## outline-regexp: "#+ "
## End:
