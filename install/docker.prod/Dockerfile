
FROM koding/base
MAINTAINER Devrim Yasar <devrim@koding.com>

USER root
ENV HOME /root
ENV DOCKER yes
ENV KODING_PROJECT_ROOT "/opt/koding"
ENV KODING_BUILD_DATA_PATH "/root/BUILD_DATA"
ENV BLD "/root/BUILD_DATA"

RUN echo "UTC" > /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata

WORKDIR /opt

ADD .ssh /root/.ssh
RUN chmod 600 /root/.ssh/id_rsa

RUN git clone git@git.sj.koding.com:koding/koding.git
ADD BUILD_DATA /root/BUILD_DATA

WORKDIR /opt/koding

RUN git checkout `cat $BLD/BUILD_BRANCH`
RUN git pull origin `cat $BLD/BUILD_BRANCH`
RUN git submodule init
RUN git submodule update

RUN npm i gulp stylus coffee-script -g --silent
RUN npm i --unsafe-perm --silent

RUN /opt/koding/configure -c `cat $BLD/BUILD_CONFIG` -r `cat $BLD/BUILD_REGION` -h `cat $BLD/BUILD_HOSTNAME` -b `cat $BLD/BUILD_BRANCH` -p /opt/koding
RUN /opt/koding/build

RUN go run /opt/koding/go/src/github.com/koding/kite/kontrol/kontrol/main.go -init -public-key /opt/koding/certs/test_kontrol_rsa_public.pem -private-key /opt/koding/certs/test_kontrol_rsa_private.pem -username koding  -kontrol-url "http://`cat $BLD/BUILD_HOSTNAME`:4000/kite" 
# RUN go run /opt/koding/go/src/github.com/koding/kite/kontrol/kontrol/main.go -init -public-key /opt/koding/certs/test_kontrol_rsa_public.pem -private-key /opt/koding/certs/test_kontrol_rsa_private.pem -username koding  -kontrol-url "http://0.0.0.0:4000" 
WORKDIR /opt/koding/go/src/socialapi
RUN make install
WORKDIR /opt/koding