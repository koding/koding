FROM koding/koding
MAINTAINER Devrim Yasar <devrim@koding.com>


ADD BUILD_DATA /root/BUILD_DATA
RUN git checkout `cat $BLD/BUILD_BRANCH` 
RUN git pull origin `cat $BLD/BUILD_BRANCH`
RUN git submodule init
RUN git submodule update
RUN npm i gulp stylus coffee-script -g --silent
RUN npm i --unsafe-perm --silent
RUN chmod +x ./build
RUN echo "building client (stdout is supressed, stderr is visible)"
RUN ./build > /dev/null
RUN ./go/build.sh
RUN go run /opt/koding/go/src/github.com/koding/kite/kontrol/kontrol/main.go -init -public-key /opt/koding/certs/test_kontrol_rsa_public.pem -private-key /opt/koding/certs/test_kontrol_rsa_private.pem -username koding  -kontrol-url "http://`cat $BLD/BUILD_HOSTNAME`:4000/kite" 

WORKDIR /opt/koding/go/src/socialapi
RUN make install 
WORKDIR /opt/koding