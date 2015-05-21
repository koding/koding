#!/usr/bin/env bash
cd check/
go-bindata -o ./checkers.go checkers/
go build
tar -cvf check.tar check
