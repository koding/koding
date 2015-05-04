#!/bin/bash

go test -c
./janitor.test -c ../../socialapi/config/test.toml
rm janitor.test
