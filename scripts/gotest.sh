#!/usr/bin/env bash

set -o errexit

#  make relative paths work.
cd $(dirname $0)/..

action="sh -c"
# action="echo"

go list -f '{{if len .TestGoFiles}}"go test -v -cover -o={{.Dir}}/{{.Name}}.test -c {{.ImportPath}} "{{end}}' $1 | grep -v vendor | xargs -L 1 -I{} $action {}$COMPILE_FLAGS
# pushd is required for test folders/paths
go list -f '{{if len .TestGoFiles}}"pushd {{.Dir}} && ./{{.Name}}.test -test.coverprofile={{.Dir}}/coverage.txt "{{end}}' $1 | xargs -L 1 -I{} $action {}$RUN_FLAGS
go list -f '{{if len .TestGoFiles}}"rm {{.Dir}}/{{.Name}}.test "{{end}}' $1 | xargs -L 1 $action
