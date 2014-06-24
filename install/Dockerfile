FROM koding/base
MAINTAINER Devrim Yasar <devrim@koding.com>

USER root
ENV HOME /root
ENV DOCKER yes
ENV KODING_PROJECT_ROOT "/opt/koding"
ENV BLD /opt/koding/install/BUILD_DATA

RUN echo "UTC" > /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata

# INSTALL AND BUILD CODE
RUN echo installing now.
WORKDIR /opt

ADD BUILD_DATA/.ssh /root/.ssh
RUN chmod 600 /root/.ssh/id_rsa

RUN git clone git@git.sj.koding.com:koding/koding.git
ADD BUILD_DATA /opt/koding/install/BUILD_DATA

RUN `cat $BLD/BUILD_HOSTNAME` >/etc/hostname
RUN hostname `cat $BLD/BUILD_HOSTNAME`


WORKDIR /opt/koding
RUN ls -lha /opt/koding

RUN git checkout `cat $BLD/BUILD_BRANCH`

RUN git submodule init
RUN git submodule update

RUN npm i gulp stylus coffee-script -g --silent
RUN npm i --unsafe-perm --silent

RUN /opt/koding/configure -c `cat $BLD/BUILD_CONFIG` -r `cat $BLD/BUILD_REGION` -h `cat $BLD/BUILD_HOSTNAME` -b `cat $BLD/BUILD_BRANCH` -p /opt/koding
RUN /opt/koding/build

RUN go run /opt/koding/go/src/github.com/koding/kite/kontrol/kontrol/main.go -init -public-key /opt/koding/certs/test_kontrol_rsa_public.pem -private-key /opt/koding/certs/test_kontrol_rsa_private.pem -username koding  -kontrol-url "http://`cat $BLD/BUILD_HOSTNAME`:4000" 

RUN ls -lha /opt/koding/server

# RUN cat $BLD/BUILD_CONFIG.json
# ENTRYPOINT ["/opt/koding/run"]
