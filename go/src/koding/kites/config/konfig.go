package config

import (
	"path/filepath"
	"time"

	"koding/kites/kloud/utils/object"

	"github.com/boltdb/bolt"
)

var KonfigCache = &CacheOptions{
	File: filepath.Join(KodingHome(), "konfig.bolt"),
	BoltDB: &bolt.Options{
		Timeout: 5 * time.Second,
	},
	Bucket: []byte("konfig"),
}

type Konfig struct {
	// Kite configuration.
	KiteKeyFile string `json:"kiteKeyFile,omitempty"`

	// Koding endpoints konfiguration.
	KontrolURL string `json:"kontrolURL,omitempty"`
	KlientURL  string `json:"klientURL,omitempty"`
	KloudURL   string `json:"kloudURL,omitempty"`
	TunnelURL  string `json:"tunnelURL,omitempty"`
	IPURL      string `json:"ipURL,omitempty"`
	IPCheckURL string `json:"ipCheckURL,omiturl"`

	// Klient / KD auto-update endpoints.
	KlientLatestURL string `json:"klientLatestURL,omitempty"`
	KDLatestURL     string `json:"kdLatestURL,omitempty"`

	// Public S3 bucket for writing logs.
	PublicBucketName   string `json:"publicBucketName,omitempty"`
	PublicBucketRegion string `json:"publicBucketRegion,omitempty"`

	Debug bool `json:"debug,omitempty"`
}

func (k *Konfig) KiteHome() string {
	return filepath.Dir(k.KiteKeyFile)
}

// Enviroment is a hacky workaround for kd <-> klient environments.
// The managed klient expects to have kd from production channel,
// and devmanaged klient - from development. Depending from which
// app we load the the default Koding configuration, we need
// to cross-map the environments.
//
// TODO(rjeczalik): This should be fixed by removing managed / devmanaged
// channels - that is to improve "connect your vm" modal to
// not depend on special klient environment.
type Environments struct {
	Env       string
	KlientEnv string // Env is used if empty
	KDEnv     string // Env is used if empty
}

func (e *Environments) klientEnv() string {
	if e.KlientEnv != "" {
		return e.KlientEnv
	}
	return e.Env
}

func (e *Environments) kdEnv() string {
	if e.KDEnv != "" {
		return e.KDEnv
	}
	return e.Env
}

func NewKonfig(e *Environments) *Konfig {
	return &Konfig{
		KiteKeyFile:        "/etc/kite/kite.key",
		KlientURL:          "http://127.0.0.1:56789/kite",
		KontrolURL:         Builtin.Endpoints.URL("kontrol", e.Env),
		KloudURL:           Builtin.Endpoints.URL("kloud", e.Env),
		TunnelURL:          Builtin.Endpoints.URL("tunnelserver", e.Env),
		IPURL:              Builtin.Endpoints.URL("ip", e.Env),
		IPCheckURL:         Builtin.Endpoints.URL("ipcheck", e.Env),
		KlientLatestURL:    Builtin.Endpoints.URL("klient-latest", e.klientEnv()),
		KDLatestURL:        Builtin.Endpoints.URL("kd-latest", e.kdEnv()),
		PublicBucketName:   Builtin.Buckets.ByEnv("publiclogs", e.klientEnv()).Name,
		PublicBucketRegion: Builtin.Buckets.ByEnv("publiclogs", e.klientEnv()).Region,
		Debug:              false,
	}
}

func ReadKonfig(e *Environments) *Konfig {
	var override Konfig
	var builtin = NewKonfig(e)

	c := NewCache(KonfigCache)
	defer c.Close()

	if err := c.GetValue("konfig", &override); err == nil {
		object.Merge(builtin, &override)
	}

	return builtin
}
