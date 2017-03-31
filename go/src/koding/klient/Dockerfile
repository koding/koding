FROM ubuntu:14.04

MAINTAINER Rafal Jeczalik <rafal@koding.com>

# This Docker image is a minimalist image that will be the official
# klient Docker image for DockerHub. It relies on a build container
# to provide the klient binary that is injected into this image.

WORKDIR /opt/kite/klient

COPY klient .

#ARG KONTROL=https://koding.com/kontrol/kite

#COPY entrypoint.sh .

EXPOSE 56789

RUN apt-get update && apt-get install -y git build-essential ubuntu-dev-tools dh-make && apt-get clean && \
    curl -sSL https://storage.googleapis.com/golang/go1.8.linux-amd64.tar.gz | tar -C /usr/local/ -zxf - && \
    ln -s /usr/local/go/bin/go /usr/local/bin/go

ENTRYPOINT ["/opt/kite/klient/klient"]
# ENTRYPOINT ["/opt/kite/klient/entrypoint.sh"]
CMD ["--help"]
