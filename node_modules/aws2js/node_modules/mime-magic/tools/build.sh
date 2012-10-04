#!/bin/sh

## CONFIG
file_version="5.11"
## /CONFIG

build_file=0
if [ ! -f bin/file ]
then
	echo "file(1) is not installed: bin/file not found"
	build_file=1
else
	if [ ! -f lib/libmagic.so -a ! -f lib/libmagic.dylib ]
	then
		echo "file(1) is not installed: lib/libmagic.so or lib/libmagic.dylib not found"
		build_file=1
	fi
fi

if [ $build_file -eq 0 ]
then
	installed_file_version=$(LD_LIBRARY_PATH=lib DYLD_LIBRARY_PATH=lib bin/file -v | grep -Eo "[0-9]\.[0-9]+")
	echo "file(1) $installed_file_version is installed, expecting $file_version"
	if [ "$installed_file_version" != "$file_version" ]
	then
		make purge
		build_file=1
	fi
fi

if [ ! -d src/file-$file_version ]
then
	cd vendor
	tar -xf file-$file_version.tar.gz
	mkdir ../src
	mv file-$file_version ../src
	cd ..
fi

if [ $build_file -eq 1 ]
then
	build_file=0
	cd src/file-$file_version
	./configure
	make
	cd ../../
	cp src/file-$file_version/magic/magic.mgc share
	cp src/file-$file_version/src/.libs/file bin/file
	
	if [ -f src/file-$file_version/src/.libs/libmagic.so ]
	then
		cp src/file-$file_version/src/.libs/libmagic.so lib/libmagic.so
		cd lib
		ln -s libmagic.so libmagic.so.1
		cd ..
	fi
	
	if [ -f src/file-$file_version/src/.libs/libmagic.dylib ]
	then
		cp src/file-$file_version/src/.libs/libmagic.dylib lib/libmagic.dylib
		cd lib
		ln -s libmagic.dylib libmagic.1.dylib
		cd ..
	fi
	
	make debug
fi

exit 0
