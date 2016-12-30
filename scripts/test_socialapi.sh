#!/usr/bin/env bash

echo $1
CONFIG=${2:-"-c ./config/dev.toml"}
# go list -f '{{if len .TestGoFiles}}"go test -v -cover -o={{.Dir}}/{{.Name}}.test -c {{.ImportPath}}"{{end}}' $1 | grep -v vendor | xargs -L 1 sh -c
# go list -f '{{if len .TestGoFiles}}"{{.Dir}}/{{.Name}}.test -test.coverprofile={{.Dir}}/{{.Name}}.coverprofile "{{end}}' $1 | xargs -L 1 -I{} sh -c {} $CONFIG
# go list -f '{{if len .TestGoFiles}}"rm {{.Dir}}/{{.Name}}.test "{{end}}' $1 | xargs -L 1 sh -c
echo "mode: set" > coverage.txt
go list -f '{{if len .TestGoFiles}}"{{.Dir}}/{{.Name}}.coverprofile"{{end}}' $1 | xargs -L 1 -I{} tail -n +2 {} >> coverage.txt
bash <(curl -s https://codecov.io/bash)
