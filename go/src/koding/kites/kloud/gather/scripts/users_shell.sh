#!/bin/bash

MYDIR="$(dirname "$(which "$0")")"

IFS=:
bash ./$MYDIR/users.sh | while read user pass x x x x shell line
do
  echo $user $shell
done
