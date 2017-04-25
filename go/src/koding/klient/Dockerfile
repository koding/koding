FROM ubuntu:14.04

MAINTAINER Rafal Jeczalik <rafal@koding.com>

# This Docker image is a minimalist image that will be the official
# klient Docker image for DockerHub. It relies on a build container
# to provide the klient binary that is injected into this image.

RUN apt-get -qq update \
 && apt-get -qq install -y \
    ca-certificates \
 && apt-get clean

WORKDIR /opt/kite/klient

COPY klient /usr/local/bin/

COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

EXPOSE 56789
