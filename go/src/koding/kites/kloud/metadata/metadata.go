package metadata

import "text/template"

//go:generate $GOPATH/bin/go-bindata -mode 420 -modtime 1470666525 -pkg metadata -o provision.sh.go provision.sh
//go:generate gofmt -l -w -s provision.sh.go

var provision = mustTemplate("provision.sh")

func mustAsset(file string) []byte {
	p, err := Asset(file)
	if err != nil {
		panic(err)
	}
	return p
}

func mustTemplate(file string) *template.Template {
	return template.Must(template.New(file).Parse(string(mustAsset(file))))
}
