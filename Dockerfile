FROM koding/base
MAINTAINER Sonmez Kartal <sonmez@koding.com>

ADD . /opt/koding
WORKDIR /opt/koding

RUN npm install --unsafe-perm && \
    KODINGENV="default" ./configure && \
    go/build.sh && \
    make -C client dist

ENTRYPOINT ["scripts/bootstrap-container"]
