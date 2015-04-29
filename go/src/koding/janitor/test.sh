# Builds and runs Janitor tests
#!/bin/bash

go test -c
./janitor.test -c ../../socialapi/config/test.toml -test.v=true
rm janitor.test
