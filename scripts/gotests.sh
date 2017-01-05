#!/bin/bash

#  make relative paths work.
cd $(dirname $0)/..

action="sh -c"
# action="echo"

function compile () {
    go list -f '{{if len .TestGoFiles}}"go test -v -cover -c {{.ImportPath}} -o={{.Dir}}/{{.Name}}.test "{{end}}' $1 | grep -v vendor | xargs -L 1 -I{} $action "{}$COMPILE_FLAGS"
}

function run () {
    go list -f '{{if len .TestGoFiles}}"{{.Dir}}/{{.Name}}.test -test.coverprofile={{.Dir}}/coverage.txt "{{end}}' $1 | grep -v vendor | xargs -L 1 -I{} $action "{}$RUN_FLAGS"
}

function runWithCD () {
    go list -f '{{if len .TestGoFiles}}"cd {{.Dir}} && ./{{.Name}}.test -test.coverprofile={{.Dir}}/coverage.txt "{{end}}' $1 | grep -v vendor | xargs -L 1 -I{} $action "{}$RUN_FLAGS"
}

function clean () {
    go list -f '{{if len .TestGoFiles}}"rm {{.Dir}}/{{.Name}}.test "{{end}}' $1 | xargs -L 1 $action
}

function runAll () {
    compile $@
    run $@
    clean $@
}

if [ "$1" == "socialapi" ]; then
  shift
  export RUN_FLAGS=${RUN_FLAGS:-"-c=./go/src/socialapi/config/dev.toml"}
  
  runAll $@

elif  [ "$1" == "kites" ]; then
    shift
    export COMPILE_FLAGS=${COMPILE_FLAGS:-"-race"}

    compile  $@
    runWithCD $@
    clean $@
else
  runAll $@
fi
