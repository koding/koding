FROM ubuntu:14.04

MAINTAINER Rafal Jeczalik <rafal@koding.com>

# This Docker images serves a a development image for Koding's Go codebase.
# Use this image to make builds and minified images for deployments. For
# example: if you are doing klient development, use this image to work on
# the codebase, but export the built klient binary and inject that in to
# a minified Docker image, like the go/src/koding/klient/Dockerfile does.

# Packages installed here are common packages throughout this image's Go tree.
RUN apt-get update \
 && apt-get install -y \
    build-essential \
    curl \
    dh-make \
    git \
    ubuntu-dev-tools \
 && apt-get clean

# Install Go
ARG goversion=1.7.4
ARG goplatform=linux
ARG goarch=amd64
RUN base=https://storage.googleapis.com \
 && url=${base}/golang/go${goversion}.${goplatform}-${goarch}.tar.gz \
 && curl -sSL ${url} | tar -C /usr/local/ -zxf - \
 && ln -s /usr/local/go/bin/go /usr/local/bin/go

WORKDIR /opt/koding

ENV GOPATH /opt/koding/go
