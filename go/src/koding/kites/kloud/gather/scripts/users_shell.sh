#!/bin/bash

IFS=:
bash ./users.sh | while read user pass x x x x shell line
do
  echo $user $shell
done
