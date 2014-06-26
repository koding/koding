FROM koding/codebase
MAINTAINER Devrim Yasar <devrim@koding.com>


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