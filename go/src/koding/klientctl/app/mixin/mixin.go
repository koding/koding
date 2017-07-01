package mixin

import (
	"koding/kites/kloud/metadata"
	"koding/kites/kloud/utils/object"

	yaml "gopkg.in/yaml.v2"
)

//go:generate $GOPATH/bin/go-bindata -mode 420 -modtime 1475345133 -pkg mixin -o app.yaml.go app.yaml

// App is a mixin, that builds user app and serves it on a remote machine.
var App = New(MustAsset("app.yaml"))

// Mixin represents a raw mixin object.
type Mixin struct {
	Machine  map[string]interface{} `json:"machine" yaml:"machine"`
	Variable []struct {
		Name    string      `json:"name" yaml:"name"`
		Default interface{} `json:"default" yaml:"default"`
	} `json:"variable" yaml:"variable"`
	CloudInit metadata.CloudInit `json:"cloudinit" yaml:"cloudinit"`
}

// New gives new mixin by unmarshaling yaml-encoded p
// into a Mixin value.
//
// If cloud-init is empty or p has unexpected content or format,
// the function panics.
func New(p []byte) *Mixin {
	var m Mixin

	if err := yaml.Unmarshal(p, &m); err != nil {
		panic(err)
	}

	if len(m.CloudInit) == 0 {
		panic("empty cloud-init script")
	}

	m.Machine = object.FixYAML(m.Machine).(map[string]interface{})
	m.CloudInit = metadata.CloudInit(object.FixYAML((map[string]interface{})(m.CloudInit)).(map[string]interface{}))

	return &m
}
