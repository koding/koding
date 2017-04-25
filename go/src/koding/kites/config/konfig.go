package config

import (
	"bytes"
	"crypto/sha1"
	"encoding/hex"
	"errors"
	"io/ioutil"
	"net/url"
	"os"
	"path"
	"path/filepath"
	"sort"
	"strings"
	"time"

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

// Local describes configuration of local paths.
type Local struct {
	// Mount is a default home path of mounted directories.
	//
	// If empty, defaults to ~/koding/mnt/.
	MountHome string `json:"mountHome,omitempty"`

	// Mounts maps named mounts to local paths.
	//
	// The Mounts["default"] export is used as
	// a default one when caller does not specify
	// a mount path.
	//
	// The Mounts["default"] defaults to $HOME.
	Mounts map[string]string `json:"mounts,omitempty"`
}

func (l *Local) MountPath(name string) (string, bool) {
	if l == nil {
		return "", false
	}

	if dir, ok := l.Mounts[name]; ok {
		return expandHome(dir), true
	}

	return "", false
}

type Konfig struct {
	Endpoints *Endpoints `json:"endpoints,omitempty"`

	KontrolURL string `json:"kontrolURL,omitempty"` // deprecated / read-only
	TunnelURL  string `json:"tunnelURL,omitempty"`  // deprecated / read-only

	// Kite configuration.
	Environment string `json:"environment,omitempty"`
	KiteKeyFile string `json:"kiteKeyFile,omitempty"`
	KiteKey     string `json:"kiteKey,omitempty"`

	// Local describes configuration of local paths.
	Local *Local `json:"local,omitempty"`

	// Koding networking configuration.
	//
	// TODO(rjeczalik): store command line flags in konfig.bolt
	// per Koding executable (KD / Klient).
	TunnelID string `json:"tunnelID,omitempty"`

	// Public S3 bucket for writing logs.
	PublicBucketName   string `json:"publicBucketName,omitempty"`
	PublicBucketRegion string `json:"publicBucketRegion,omitempty"`

	Debug bool `json:"debug,string,omitempty"`
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

func (k *Konfig) Valid() error {
	// TODO(rjeczalik): remove when KontrolURL is gone
	if _, err := url.Parse(k.KontrolURL); err == nil && k.KontrolURL != "" {
		return nil
	}

	if k.Endpoints == nil {
		return errors.New("endpoints are nil")
	}
	if k.Endpoints.Koding == nil {
		return errors.New("koding base endpoint is nil")
	}
	if k.Endpoints.Koding.Public == nil {
		return errors.New("public URL for koding base endpoint is nil")
	}
	return nil
}

func (k *Konfig) ID() string {
	return ID(k.KodingPublic().String())
}

func ID(kodingURL string) string {
	if kodingURL == "" {
		return ""
	}
	if u, err := url.Parse(kodingURL); err == nil {
		// Since id is input sensitive we clean the path so "example.com/koding"
		// "example.com/koding/" are effectively the same urls.
		u.Path = strings.TrimRight(path.Clean(u.Path), "/")
		kodingURL = u.String()
	}
	hash := sha1.Sum([]byte(kodingURL))
	return hex.EncodeToString(hash[:4])
}

// KodingPublic is here for backward-compatibility purposes.
//
// Old klient and kd deployments may not have .Endpoints configuration
// on a first run, this is why we fallback to old KontrolURL field.
//
// Which we should eventually get rid of.
//
// Deprecated: Use k.Endpoints.Koding.Public instead.
func (k *Konfig) KodingPublic() *url.URL {
	if e := k.Endpoints; e != nil && e.Koding != nil && e.Koding.Public != nil {
		return e.Koding.Public.URL
	}

	if u, err := url.Parse(k.KontrolURL); err == nil {
		u.Path = ""
		return u
	}

	return nil
}

func (k *Konfig) buildKiteConfig() *konfig.Config {
	kiteKey := k.KiteKey

	if kiteKey == "" && k.KiteKeyFile != "" {
		if p, err := ioutil.ReadFile(k.KiteKeyFile); err == nil && len(p) != 0 {
			kiteKey = string(bytes.TrimSpace(p))
		}
	}

	if kiteKey != "" {
		tok, err := jwt.ParseWithClaims(kiteKey, &kitekey.KiteClaims{}, kitekey.GetKontrolKey)
		if err == nil {
			cfg := NewKiteConfig(k.Debug)

			if err = cfg.ReadToken(tok); err == nil {
				return cfg
			}
		}
	}

	if cfg, err := ReadKiteConfig(k.Debug); err == nil {
		return cfg
	}

	return NewKiteConfig(k.Debug)
}

func NewKonfigURL(koding *url.URL) *Konfig {
	return &Konfig{
		Endpoints: &Endpoints{
			Koding: NewEndpointURL(koding),
		},
	}
}

type Konfigs map[string]*Konfig

func (kfg Konfigs) Slice() []*Konfig {
	keys := make([]string, 0, len(kfg))
	for k := range kfg {
		keys = append(keys, k)
	}
	sort.Strings(keys)

	slice := make([]*Konfig, 0, len(kfg))
	for _, key := range keys {
		slice = append(slice, kfg[key])
	}
	return slice
}

// Environment is a hacky workaround for kd <-> klient environments.
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
		Endpoints: &Endpoints{
			Koding:       Builtin.Endpoints.KodingBase.Copy(),
			Tunnel:       Builtin.Endpoints.TunnelServer.Copy(),
			IP:           Builtin.Endpoints.IP.Copy(),
			IPCheck:      Builtin.Endpoints.IPCheck.Copy(),
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
		Local: &Local{
			MountHome: filepath.Join(CurrentUser.HomeDir, "koding", "mnt"),
			Mounts: map[string]string{
				"default": CurrentUser.HomeDir,
			},
		},
		PublicBucketName:   Builtin.Buckets.PublicLogs.Name,
		PublicBucketRegion: Builtin.Buckets.PublicLogs.Region,
		Debug:              false,
	}
}

func expandHome(path string) string {
	const home = "~" + string(os.PathSeparator)

	switch {
	case path == "~":
		return CurrentUser.HomeDir
	case strings.HasPrefix(path, home):
		return filepath.Join(CurrentUser.HomeDir, path[len(home):])
	default:
		return path
	}
}
