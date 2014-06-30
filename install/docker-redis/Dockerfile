FROM ubuntu:14.04
MAINTAINER Cihangir Savas <cihangir@koding.com>


RUN apt-get update
RUN apt-get install -y software-properties-common
RUN apt-add-repository -y ppa:chris-lea/redis-server
RUN apt-get install -y redis-server
EXPOSE 6379:6379
