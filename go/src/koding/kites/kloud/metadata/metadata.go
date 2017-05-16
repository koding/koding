package metadata

import (
	"bytes"
	"encoding/json"
	"errors"
	"koding/kites/config"
)

//go:generate $GOPATH/bin/go-bindata -mode 420 -modtime 1470666525 -pkg metadata -o provision.sh.go provision.sh
//go:generate gofmt -l -w -s provision.sh.go

// Default asset URLs used by kloud when deploying klient.
//
// They are being downloaded on a remote vm during provisioning.
//
// TODO(rjeczalik): make it configurable during ./configure = add to kites/config/config.json
var (
	DefaultEntrypointBaseURL = "https://koding.com/s3/koding-klient/entrypoint"
	DefaultScreenURL         = "https://koding.com/d/screen.tar.gz"
	DefaultCertURL           = "https://koding.com/d/ca-certificates.crt.gz"
)

var provision = string(mustAsset("provision.sh"))

func mustAsset(file string) []byte {
	p, err := Asset(file)
	if err != nil {
		panic(err)
	}
	return p
}

// Config is used to build cloud-init from user_data
// in order to install klient service on a remote vm
// and authenticate and connect to Koding.
type Config struct {
	Konfig   *config.Konfig    // Koding endpoints configuration
	KiteKey  string            // KiteKey used by klient to authenticate with Koding
	Userdata string            // User script to run after provisioning, if any
	Exports  map[string]string // Maps names with mount paths, for use with kd mount.
	Debug    bool              // Whether klient should be started in debug mode; configurable by debug field in stack template
}

// New builds new cloud-init for the given configuration.
//
// If cfg.Userdata is a cloud-init file, it will be
// merged back into kloud's one. If there are conflicts
// between the two cloud-init scripts, stack build will
// fail - we do not allow user to overwrite kloud's
// cloud-init.
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

// TODO(rjeczalik): refactor to a separate function in kites/config
// and use in marathon as well.
func newMetadata(cfg *Config) ([]byte, error) {
	konfig := &config.Konfig{
		Endpoints:   cfg.Konfig.Endpoints,
		Environment: cfg.Konfig.Environment,
		KiteKey:     cfg.KiteKey,
		Mount: &config.Mount{
			Exports: cfg.Exports,
		},
		PublicBucketName:   cfg.Konfig.PublicBucketName,
		PublicBucketRegion: cfg.Konfig.PublicBucketRegion,
		Debug:              cfg.Debug,
	}

	m := map[string]interface{}{
		"konfig.konfig.konfigs": map[string]interface{}{
			konfig.ID(): konfig,
		},
		"konfig.konfig.konfigs.used": map[string]interface{}{
			"id": konfig.ID(),
		},
	}

	var buf bytes.Buffer

	enc := json.NewEncoder(&buf)
	enc.SetEscapeHTML(false)

	if err := enc.Encode(m); err != nil {
		return nil, err
	}

	return buf.Bytes(), nil
}
