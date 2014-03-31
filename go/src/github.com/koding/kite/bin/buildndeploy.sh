#!/bin/sh
set -e -x

export GOOS=linux GOARCH=amd64

go build -o kite ../cmd/kite/main.go
go build -o kite-regserv ../regserv/regserv/main.go
go build -o kite-kontrol ../kontrol/kontrol/main.go
go build -o kite-proxy ../proxy/proxy/main.go

scp kite ubuntu@kite-regserv.koding.com:
scp kite ubuntu@kite-kontrol.koding.com:
scp kite ubuntu@kite-proxy.koding.com:
scp kite-regserv ubuntu@kite-regserv.koding.com:
scp kite-kontrol ubuntu@kite-kontrol.koding.com:
scp kite-proxy ubuntu@kite-proxy.koding.com:
