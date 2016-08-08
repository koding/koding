FROM golang:1.6.2-alpine
MAINTAINER Can Yucel "can.yucel@gmail.com"

RUN apk --update upgrade && \
  apk add curl ca-certificates && \
  update-ca-certificates && \
  rm -rf /var/cache/apk/*

ENV WATCHER_VERSION 0.2.1

ADD https://github.com/canthefason/go-watcher/releases/download/v${WATCHER_VERSION}/watcher-${WATCHER_VERSION}-linux-amd64 /go/bin/watcher

RUN chmod +x /go/bin/watcher

CMD ["watcher"]
