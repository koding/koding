package mixin

import "koding/kites/kloud/metadata"

//go:generate $GOPATH/bin/go-bindata -mode 420 -modtime 1475345133 -pkg mixin -o app.yaml.go app.yaml

// Raw represents a raw mixin content.
type Raw []byte

// CloudInit unmarshals r into a valid cloud-init object value.
//
// It panics when r is not a valid cloud-init value.
func (r Raw) CloudInit() metadata.CloudInit {
	ci, err := metadata.ParseCloudInit([]byte(r))
	if err != nil {
		panic(err)
	}
	return ci
}

var App = mustMixin("app.yaml")

func mustMixin(asset string) Raw {
	r := Raw(MustAsset(asset))
	_ = r.CloudInit() // ensure it's a valid cloud-init content
	return r
}
