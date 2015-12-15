#!/bin/bash

# Provision environment

PROVISION_USER=$SUDO_USER

# APT repositories

## Add third party repositories

add-apt-repository -y ppa:chris-lea/node.js

wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
echo 'deb http://dl.google.com/linux/chrome/deb/ stable main' > /etc/apt/sources.list.d/google.list

## Update package repositories

apt-get update

## Update packages

apt-get upgrade -y
apt-get dist-upgrade -y


# Install essential dependencies

## Core

apt-get install -y build-essential git-core
apt-get install -y rlwrap libev-dev libev4 libxml2-dev libssl-dev
apt-get install -y libgif-dev libjpeg-dev libcairo2-dev graphicsmagick
apt-get install -y python-pip

## nginx

apt-get install -y nginx

## mongodb

apt-get install -y mongodb-clients

## postgresql

apt-get install -y postgresql-client

## supervisor

pip install supervisor

## s3cmd

pip install s3cmd


# Install node.js

apt-get install -y nodejs


## Update npm

npm install --global npm@2.9.1


## Install CoffeeScript modules

npm install --global coffee-script@1.8.0
npm install --global gulp gulp-coffee


# Install golang

wget https://godeb.s3.amazonaws.com/godeb-amd64.tar.gz
tar xfz godeb-amd64.tar.gz
./godeb install 1.4.2


# Install docker-engine

wget -qO- https://get.docker.com/ | sh
usermod -aG docker $PROVISION_USER


# Install test stack essentials

apt-get install -y xvfb x11vnc xfonts-75dpi xfonts-100dpi xfonts-scalable xfonts-cyrillic
apt-get install -y openjdk-7-jre-headless
apt-get install -y google-chrome-stable

npm install --global nightwatch


# Configure system environment

## git

## Configure git

git config --global user.email 'sysops@koding.com'
git config --global user.name 'Koding Bot'

## nginx

update-rc.d nginx disable all


# Initialize working environment

REPOSITORY_PATH=/opt/koding

mkdir $REPOSITORY_PATH
chown $PROVISION_USER:$PROVISION_USER $REPOSITORY_PATH


# Cleanup

rm -rf $HOME/.npm


# File variables

## Local variables:
## eval: (outline-minor-mode)
## outline-regexp: "#+ "
## End:
