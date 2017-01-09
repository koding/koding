#!/bin/bash

#  make relative paths work.
cd $(dirname $0)/..

action="sh -c"
# action="echo"

# compile gets the directory as an argument and gets COMPILE_FLAGS env variable
# if needed COMPILE_FLAGS might be '-race' etc..
# this function creates a binary file for tests with tests coverage and specific
# test file with package name
function compile () {
    go list -f '{{if len .TestGoFiles}}"go test -v -cover -c {{.ImportPath}} -o={{.Dir}}/{{.Name}}.test "{{end}}' $1 | grep -v vendor | xargs -L 1 -I{} $action "{}$COMPILE_FLAGS"
}


# compileWithCoverPkg uses -coverpkg flag to test with coverage
# this satisfies to cover the subpackages of tests
function compileWithCoverPkg () {
    # list the packages
    export PKGS=$(go list $1 | /usr/bin/grep -v /vendor/)

    # make comma-separated
    export PKGS_DELIM=$(echo "$PKGS" | paste -sd "," -)

    go list -f '{{if len .TestGoFiles}}"go test -v -cover -c {{.ImportPath}} -o={{.Dir}}/{{.Name}}.test -coverpkg='$PKGS_DELIM' "{{end}}' $PKGS | grep -v vendor | xargs -L 1 -I{} $action "{}$COMPILE_FLAGS"
}

# run runs the binary file that created before (with compile function)
# this function runs the binary with given RUN_FLAGS
# RUN_FLAGS values might be config file or any value if required like
# ...('-kite-init' required for collaboration tests)
function run () {
    go list -f '{{if len .TestGoFiles}}"{{.Dir}}/{{.Name}}.test -test.coverprofile={{.Dir}}/coverage.txt "{{end}}' $1 | grep -v vendor | xargs -L 1 -I{} $action "{}$RUN_FLAGS"
}

# runWithCD runs like run function.
# But this function changes the directory while running.
function runWithCD () {
    go list -f '{{if len .TestGoFiles}}"cd {{.Dir}} && ./{{.Name}}.test -test.coverprofile={{.Dir}}/coverage.txt "{{end}}' $1 | grep -v vendor | xargs -L 1 -I{} $action "{}$RUN_FLAGS"
}

# clean removes the .tests files after creation
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

elif  [ "$1" == "cover" ]; then
    shift
    export RUN_FLAGS=${RUN_FLAGS:-"-c=./go/src/socialapi/config/dev.toml"}
    export COMPILE_FLAGS=${COMPILE_FLAGS:-"-race"}

    compileWithCoverPkg $@
    run $@
    clean $@

else
  runAll $@
fi
