#!/bin/bash

set -o errexit

#  make relative paths work.
cd $(dirname $0)/..
COVERAGE_FOLDER="./go/src"
COVMERGE="./go/bin/gocovmerge"
KD=$(pwd)

action="sh -c"
# action="echo"

# compile uses -coverpkg flag to test with coverage
# this satisfies to cover the subpackages of tests
function compile() {
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
function run() {
	go list -f '{{if len .TestGoFiles}}"{{.Dir}}/{{.Name}}.test -test.coverprofile={{.Dir}}/coverage.txt "{{end}}' $1 | grep -v vendor | xargs -L 1 -I{} $action "{}$RUN_FLAGS"
}

function merge() {
	local folder=$(createFolder $1)

	go list -f '{{if len .TestGoFiles}}"{{.Dir}}/coverage.txt"{{end}}' $1 | grep -v vendor | xargs $COVMERGE >"$folder"
}

# runWithCD runs like run function.
# But this function changes the directory while running.
function runWithCD() {
	go list -f '{{if len .TestGoFiles}}"cd {{.Dir}} && ./{{.Name}}.test -test.coverprofile={{.Dir}}/coverage.txt "{{end}}' $1 | grep -v vendor | xargs -L 1 -I{} $action "{}$RUN_FLAGS"
}

# clean removes the .tests files after creation
function clean() {
	go list -f '{{if len .TestGoFiles}}"rm {{.Dir}}/{{.Name}}.test "{{end}}' $1 | xargs -L 1 $action
}

function runAll() {
	compile $@
	run $@
	merge $@
	removeCoverProfiles $@
	clean $@
}

# removeCoverProfiles deletes the coverage.txt files after merging all
# coverages into 1 coverage.txt(merged coverage file won't be deleted)
function removeCoverProfiles() {
	go list -f '{{if len .TestGoFiles}}"{{.Dir}}/coverage.txt"{{end}}' $1 | grep -v vendor | xargs rm
}

# commandExists checks if the given parameter command is exits or not
function commandExists() {
	command -v $1 >/dev/null 2>&1
}

# generateFolderName generates a random string with given parameter
# according to given parameter & command checking
function generateFolderName() {
	if commandExists md5; then
		echo $1 | md5
	elif commandExists md5sum; then
		echo -n $1 | md5sum | awk '{print $1}'
	else
		date +%s%N
	fi
}

# createFolder creates a '/coverage' folder if doesn't exists
# then appends the generated random string as folder name
# e.g:
# assume random string : $generatedName
# path will be -> koding/go/src/coverage/$generatedName
function createFolder() {
	name=$(generateFolderName $1)
	mkdir -p "$KD/go/src/coverages/$name"
	touch "$KD/go/src/coverages/$name/coverage.txt"

	echo "$KD/go/src/coverages/$name/coverage.txt"
}

if [ "$1" == "kites" ]; then
	shift

	compile $@
	runWithCD $@
	merge $@
	removeCoverProfiles $@
	clean $@

elif [ "$1" == "socialapi" ]; then
	shift
	export RUN_FLAGS=${RUN_FLAGS:-"-c=$KONFIG_SOCIALAPI_CONFIGFILEPATH"}

	runAll $@
# useful after a refactoring, just to see if there is any error
elif [ "$1" == "compile" ]; then
	shift
	compile $@
	clean $@
else
	runAll $@
fi
