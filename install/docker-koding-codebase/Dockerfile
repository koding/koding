FROM ubuntu:14.04
MAINTAINER Devrim Yasar <devrim@koding.com>

# Update and upgrade repo
RUN apt-get update -y -q && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -q 

# Let's include those for future usage, like building from source if needed
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y -q curl build-essential ca-certificates git 

# Needed for add-apt-repository
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -q software-properties-common


# Install Go and set paths, pre-compiled
RUN curl -s https://storage.googleapis.com/golang/go1.3.linux-amd64.tar.gz| tar -v -C /usr/local -xz
ENV PATH $PATH:/usr/local/go/bin 
ENV GOPATH /opt/koding/go 
ENV GOBIN /opt/koding/go/bin

# Install latest Node.js 
RUN add-apt-repository -y ppa:chris-lea/node.js
RUN DEBIAN_FRONTEND=noninteractive apt-get update -yq
RUN DEBIAN_FRONTEND=noninteractive apt-get install -yq nodejs

# Extra dependencies for node module installs and kontrol-init
RUN apt-get install -y graphicsmagick openssh-client python openssl
RUN npm i gulp stylus coffee-script -g --silent

# Setup our working environment
WORKDIR /opt/koding/

# Set our KITE_HOME
ENV KITE_HOME /opt/koding/kite_home/koding

# Set up a volume points, which is shareable amongst all other docker containers
VOLUME ["/koding_data"]
VOLUME ["/var/log/koding"]

USER root
ENV HOME /root
ENV DOCKER yes
ENV KODING_PROJECT_ROOT /opt/koding
ENV KODING_BUILD_DATA_PATH /root/BUILD_DATA
ENV BLD /root/BUILD_DATA


RUN echo "UTC" > /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata

WORKDIR /opt

ADD .ssh /root/.ssh
RUN chmod 600 /root/.ssh/id_rsa

RUN git clone git@github.com:koding/koding.git

WORKDIR /opt/koding
