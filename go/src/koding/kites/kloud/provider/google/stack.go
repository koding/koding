package google

import (
	"bytes"
	"text/template"

	"koding/kites/kloud/stack"
)

//go:generate $GOPATH/bin/go-bindata -mode 420 -modtime 1475345133 -pkg google -o bootstrap.json.tmpl.go bootstrap.json.tmpl
//go:generate go fmt bootstrap.json.tmpl.go

var bootstrap = template.Must(template.New("").Parse(mustAsset("bootstrap.json.tmpl")))

type bootstrapConfig struct {
	PublicKey       string
	EnvironmentName string
}

func mustAsset(s string) string {
	p, err := Asset(s)
	if err != nil {
		panic(err)
	}
	return string(p)
}

func newBootstrapTemplate(cfg *bootstrapConfig) (*stack.Template, error) {
	var buf bytes.Buffer

	if err := bootstrap.Execute(&buf, cfg); err != nil {
		return nil, err
	}

	return &stack.Template{
		Content: buf.String(),
	}, nil
}
