#!/bin/bash

../../../../../node_modules/mocha/bin/mocha --compilers coffee:coffee-script/register --require coffee-script *.test.coffee
