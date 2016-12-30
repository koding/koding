#!/bin/bash

#  make relative paths work.
cd $(dirname $0)/..

echo $1
CONFIG=${2:-'-c=./go/src/socialapi/config/dev.toml'}
action="sh -c"

# echo "echo bok" |  xargs -L 1 -I {} $action {}"bok"
go list -f '{{if len .TestGoFiles}}"go test -v -cover -o={{.Dir}}/{{.Name}}.test -c {{.ImportPath}}"{{end}}' $1 | grep -v vendor | xargs -L 1 $action
# go list -f '{{if len .TestGoFiles}}"{{.Dir}}/{{.Name}}.test -test.coverprofile={{.Dir}}/{{.Name}}.coverprofile "{{end}}' $1 | xargs -L 1 -I{} $action {}$CONFIG
go list -f '{{if len .TestGoFiles}}"{{.Dir}}/{{.Name}}.test -test.coverprofile={{.Dir}}/coverage.txt "{{end}}' $1 | xargs -L 1 -I{} $action {}$CONFIG
go list -f '{{if len .TestGoFiles}}"rm {{.Dir}}/{{.Name}}.test "{{end}}' $1 | xargs -L 1 $action
# echo "mode: set" > coverage.txt
# go list -f '{{if len .TestGoFiles}}"{{.Dir}}/{{.Name}}.coverprofile"{{end}}' $1 | xargs -L 1 -I{} tail -n +2 {} >> coverage.txt

bash <(curl -s https://codecov.io/bash) -t $CODECOV_TOKEN -X gcov -X fix
