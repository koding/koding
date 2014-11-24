#!/bin/bash

IFS=:
bash ./users.sh | while read name pass x x x x shell line
do
  echo $shell
done
