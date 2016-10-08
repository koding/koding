FROM koding/base
MAINTAINER Sonmez Kartal <sonmez@koding.com>

RUN git clone https://github.com/koding/koding.git /opt/koding
WORKDIR /opt/koding

RUN npm install --unsafe-perm && \
    ./configure && \
    go/build.sh && \
    make -C client dist && \
    rm -rfv generated

ENTRYPOINT ["scripts/bootstrap-container"]
