#!/bin/bash

coffee -co lib/client src/client
browserify -e lib/client/main.js -o browser/bundle.js