#!/usr/bin/env bash

run_test ()
{
	echo "$1 => "$(LD_LIBRARY_PATH=lib DYLD_LIBRARY_PATH=lib bin/file --magic-file share/magic.mgc --mime-type --brief $1)
}

echo "--[DEBUG]--"
echo
echo "Version information:"
echo
# print the version info for debug purposes
LD_LIBRARY_PATH=lib DYLD_LIBRARY_PATH=lib bin/file --magic-file share/magic.mgc -v
echo
echo
# execute simple lookups to test the installation
echo "Testing the installation:"
echo
run_test tests/data/foo
run_test tests/data/foo.pdf
run_test tests/data/foo.txt
run_test tests/data/foo.txt.bz2
run_test tests/data/foo.txt.gz
run_test tests/data/foo.txt.tar
run_test tests/data/foo.txt.zip
echo
echo "--[/DEBUG]--"
