#!/bin/sh

if [ ! -d build_arm ]
then
  mkdir build_arm
  cp build/Makefile build_arm/Makefile
fi

cd build_arm

CXX=arm-linux-gnu-g++ make \
PG_INC_FLAGS=-I/usr/arm-linux-gnu/include/postgresql/ \
DISABLE_RECODE=1 DISABLE_IMAGEMAGICK=1
