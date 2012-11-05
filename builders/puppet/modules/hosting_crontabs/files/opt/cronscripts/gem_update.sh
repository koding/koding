#!/bin/bash

/usr/bin/gem update  -u --no-ri --no-rdoc | grep 'Successfully installed' &
/opt/ruby19/bin/gem1.9 update  -u --no-ri --no-rdoc --format-executable  | grep 'Successfully installed' &


rc=0
for job in $(jobs -p) 
do
    echo $job
    wait $job || rc=$(($rc+$?))
done

if [[ $rc -lt 2 ]]; then
    echo "updating gems"
    cagefsctl --update
else
    echo "no updates available"
fi
