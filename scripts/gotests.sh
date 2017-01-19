#!/bin/bash

set -o errexit

#  make relative paths work.
cd $(dirname $0)/..
COVMERGE="./go/bin/gocovmerge"

action="sh -c"
# action="echo"

# compile uses -coverpkg flag to test with coverage
# this satisfies to cover the subpackages of tests
function compile () {
    # list the packages
    export PKGS=$(go list $1 | grep -v /vendor/)

    # make comma-separated
    export PKGS_DELIM=$(echo "$PKGS" | paste -sd "," -)

    go list -f '{{if len .TestGoFiles}}"go test -race -v -cover -c {{.ImportPath}} -o={{.Dir}}/{{.Name}}.test -coverpkg='$PKGS_DELIM' "{{end}}' $PKGS | grep -v vendor | xargs -L 1 -I{} $action "{}$COMPILE_FLAGS"
}

# run runs the binary file that created before (with compile function)
# this function runs the binary with given RUN_FLAGS
# RUN_FLAGS values might be config file or any value if required like
# ...('-kite-init' required for collaboration tests)
function run () {
    go list -f '{{if len .TestGoFiles}}"{{.Dir}}/{{.Name}}.test -test.coverprofile={{.Dir}}/coverage.txt "{{end}}' $1 | grep -v vendor | xargs -L 1 -I{} $action "{}$RUN_FLAGS"
}

function merge () {
    echo "TESTING THE MERGING HERE"

    go list -f '{{if len .TestGoFiles}}"{{.Dir}}/coverage.txt "{{end}}' $1 | grep -v vendor | xargs -L 1 -I{} echo "ARRAY="{}

    exit 0
    # IFS=',' read -r -a array <<< "$PKGS_DELIM"
    IFS=' ' read -r -a array <<< $(go list -f '{{if len .TestGoFiles}}"{{.Dir}}/coverage.txt "{{end}}' $1 | grep -v vendor | xargs -L 1 -I{} echo {})

    echo "${array[@]}"

    exit 0

    declare -a arr
    for element in "${array[@]}"
    do
        # echo "element is"
        # echo "$element"
        arr[${#arr[*]}]="$element/coverage.txt"
    done

    echo "pwd"
    echo $(pwd)
    $COVMERGE ${arr[@]}

    # for i in "${PKGS}"
    # do
    #     echo "i is"
    #     echo $i
    # done

    echo "ARRAY HERE"
    echo ${arr[@]}
    echo "ARRAY ENDS"
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
    merge $@
    clean $@
}

if [ "$1" == "socialapi" ]; then
  shift
  export RUN_FLAGS=${RUN_FLAGS:-"-c=./go/src/socialapi/config/dev.toml"}
  runAll $@

elif  [ "$1" == "kites" ]; then
    shift
    compile  $@
    runWithCD $@
    clean $@

else
    runAll $@
fi
