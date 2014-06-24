FROM koding/base
MAINTAINER Devrim Yasar <devrim@koding.com>

USER root
ENV HOME /root
ENV KODING_PROJECT_ROOT "/opt/koding"

RUN echo "UTC" > /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata

ADD .ssh /root/.ssh
RUN chmod 600 /root/.ssh/id_rsa

# INSTALL AND BUILD CODE
RUN echo installing now.
WORKDIR /opt

RUN git clone git@git.sj.koding.com:koding/koding.git
WORKDIR /opt/koding

ADD BUILD_DATA /BUILD_DATA
RUN git checkout `cat /BUILD_DATA/BUILD_BRANCH`
RUN git submodule init
RUN git submodule update
RUN npm i gulp stylus coffee-script -g --silent
RUN npm i --unsafe-perm --silent

RUN ./build -c `cat /BUILD_DATA/BUILD_CONFIG` -r `cat /BUILD_DATA/BUILD_REGION` -h `cat /BUILD_DATA/BUILD_HOSTNAME` -b `cat /BUILD_DATA/BUILD_BRANCH` -p /opt/koding

RUN go run /opt/koding/go/src/github.com/koding/kite/kontrol/kontrol/main.go -init -public-key /opt/koding/certs/test_kontrol_rsa_public.pem -private-key /opt/koding/certs/test_kontrol_rsa_private.pem -username koding  -kontrol-url "http://`cat /BUILD_DATA/BUILD_HOSTNAME`:4000" 

ENTRYPOINT ["/opt/koding/run"]
