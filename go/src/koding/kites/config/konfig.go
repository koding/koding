package config

import (
	"encoding/json"
	"net/url"
	"path"
	"path/filepath"
	"time"

	"koding/kites/kloud/utils/object"

	"github.com/boltdb/bolt"
	jwt "github.com/dgrijalva/jwt-go"
	konfig "github.com/koding/kite/config"
	"github.com/koding/kite/kitekey"
)

var KonfigCache = &CacheOptions{
	File: filepath.Join(KodingHome(), "konfig.bolt"),
	BoltDB: &bolt.Options{
		Timeout: 5 * time.Second,
	},
	Bucket: []byte("konfig"),
}

type Endpoints struct {
	// Koding base endpoint.
	Koding *Endpoint `json:"koding,omitempty"`

	// Tunnel / proxy environment endpoints.
	Tunnel  *Endpoint `json:"tunnel,omitempty"`
	IP      *Endpoint `json:"ip,omitempty"`
	IPCheck *Endpoint `json:"ipCheck,omitempty"`

	// Klient / KD endpoints.
	KlientLatest *Endpoint `json:"klientLatest,omitempty"`
	KDLatest     *Endpoint `json:"kdLatest,omitempty"`
	Klient       *Endpoint `json:"klient,omitempty"`
}

func (e *Endpoints) Kloud() *Endpoint {
	return e.Koding.WithPath("/kloud/kite")
}

func (e *Endpoints) Kontrol() *Endpoint {
	return e.Koding.WithPath("/kontrol/kite")
}

func (e *Endpoints) Remote() *Endpoint {
	return e.Koding.WithPath("/remote.api")
}

func (e *Endpoints) Social() *Endpoint {
	return e.Koding.WithPath("/api/social")
}

type Konfig struct {
	Endpoints *Endpoints `json:"endpoints,omitempty"`

	// Kite configuration.
	Environment string `json:"environment,omitempty"`
	KiteKeyFile string `json:"kiteKeyFile,omitempty"`
	KiteKey     string `json:"kiteKey,omitempty"`

	// Koding networking configuration.
	//
	// TODO(rjeczalik): store command line flags in konfig.bolt
	// per Koding executable (KD / Klient).
	TunnelID string `json:"tunnelID,omitempty"`

	// Public S3 bucket for writing logs.
	PublicBucketName   string `json:"publicBucketName,omitempty"`
	PublicBucketRegion string `json:"publicBucketRegion,omitempty"`

	Debug bool `json:"debug,omitempty"`

	// Metadata keeps per-app configuration.
	Metadata map[string]interface{} `json:"metadata,omitempty"`
}

func (k *Konfig) KiteHome() string {
	return filepath.Dir(k.KiteKeyFile)
}

func (k *Konfig) KiteConfig() *konfig.Config {
	return k.buildKiteConfig()
}

func (k *Konfig) KlientGzURL() string {
	u := *k.Endpoints.KlientLatest.Public.URL
	u.Path = path.Join(path.Dir(u.Path), "latest", "klient.gz")
	return u.String()
}

func (k *Konfig) buildKiteConfig() *konfig.Config {
	if k.KiteKey != "" {
		tok, err := jwt.ParseWithClaims(k.KiteKey, &kitekey.KiteClaims{}, kitekey.GetKontrolKey)
		if err == nil {
			cfg := &konfig.Config{}

			if err = cfg.ReadToken(tok); err == nil {
				return cfg
			}
		}
	}

	if k.KiteKeyFile != "" {
		if cfg, err := konfig.NewFromKiteKey(k.KiteKeyFile); err == nil {
			return cfg
		}
	}

	if cfg, err := konfig.Get(); err == nil {
		return cfg
	}

	return konfig.New()
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
		Environment: e.Env,
		KiteKeyFile: "/etc/kite/kite.key",
		Endpoints: &Endpoints{
			Koding:       Builtin.Endpoints.KodingBase,
			Tunnel:       Builtin.Endpoints.TunnelServer,
			IP:           Builtin.Endpoints.IP,
			IPCheck:      Builtin.Endpoints.IPCheck,
			KlientLatest: ReplaceEnv(Builtin.Endpoints.KlientLatest, e.klientEnv()),
			KDLatest:     ReplaceEnv(Builtin.Endpoints.KDLatest, RmManaged(e.kdEnv())),
			Klient: &Endpoint{
				Private: &URL{&url.URL{
					Scheme: "http",
					Host:   "127.0.0.1:56789",
					Path:   "/kite",
				}},
			},
		},
		PublicBucketName:   Builtin.Buckets.PublicLogs.Name,
		PublicBucketRegion: Builtin.Buckets.PublicLogs.Region,
		Debug:              false,
	}
}

func ReadKonfig(e *Environments) *Konfig {
	c := NewCache(KonfigCache)
	defer c.Close()

	return ReadKonfigFromCache(e, c)
}

func ReadKonfigFromCache(e *Environments, c *Cache) *Konfig {
	var override Konfig
	var builtin = NewKonfig(e)

	if err := c.GetValue("konfig", &override); err == nil {
		if err := mergeIn(builtin, &override); err != nil {
			panic("unexpected failure reading konfig: " + err.Error())
		}
	}

	return builtin
}

func mergeIn(kfg, mixin *Konfig) error {
	p, err := json.Marshal(object.Inline(mixin, kfg))
	if err != nil {
		return err
	}

	return json.Unmarshal(p, kfg)
}
