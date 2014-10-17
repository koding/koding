#!/bin/bash
for i in {1..5}
do
   printf "\n\n Running $1 test: Pass $i  \n\n\n"
   ./test $1
done
