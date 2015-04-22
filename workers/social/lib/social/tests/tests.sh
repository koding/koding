#!/bin/bash

mocha --compilers coffee:coffee-script/register --require coffee-script *.test.coffee
