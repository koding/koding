package metadata

import (
	"encoding/json"
	"errors"
	"koding/kites/config"
)

//go:generate $GOPATH/bin/go-bindata -mode 420 -modtime 1470666525 -pkg metadata -o provision.sh.go provision.sh
//go:generate gofmt -l -w -s provision.sh.go

// TODO(rjeczalik): make it configurable
var (
	DefaultEntrypoingBaseURL = "https://koding-klient.s3.amazonaws.com/entrypoint"
	DefaultScreenURL         = "https://koding-dl.s3.amazonaws.com/screen.tar.gz"
	DefaultCertURL           = "https://koding-dl.s3.amazonaws.com/ca-certificates.crt.gz"
)

var provision = string(mustAsset("provision.sh"))

func mustAsset(file string) []byte {
	p, err := Asset(file)
	if err != nil {
		panic(err)
	}
	return p
}

type Config struct {
	Konfig   *config.Konfig
	KiteKey  string
	Userdata string
	Debug    bool
}

func New(cfg *Config) (CloudInit, error) {
	metadata, err := newMetadata(cfg)
	if err != nil {
		return nil, errors.New("error building metadata: " + err.Error())
	}

	ci, err := ParseCloudInit([]byte(cfg.Userdata))
	switch err {
	case nil:
		user := ci
		ci = NewCloudInit(&CloudConfig{
			Metadata: string(metadata),
		})

		if err := Merge(user, ci); err != nil {
			return nil, errors.New("error merging cloud-init from user-data: " + err.Error())
		}

	case ErrNotCloudInit:
		ci = NewCloudInit(&CloudConfig{
			Metadata: string(metadata),
			Userdata: cfg.Userdata,
		})
	default:
		return nil, errors.New("error parsing cloud-init from user-data: " + err.Error())
	}

	return ci, nil
}

func newMetadata(cfg *Config) ([]byte, error) {
	konfig := &config.Konfig{
		Endpoints: cfg.Konfig.Endpoints,
		KiteKey:   cfg.KiteKey,
		Debug:     cfg.Debug,
	}

	m := map[string]interface{}{
		"konfig.konfig.konfigs": map[string]interface{}{
			konfig.ID(): konfig,
		},
		"konfig.konfig.konfigs.used": map[string]interface{}{
			"id": konfig.ID(),
		},
	}

	return json.Marshal(m)
}
