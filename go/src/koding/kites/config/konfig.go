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
	"runtime"
	"sort"
	"strings"
	"time"

	"github.com/boltdb/bolt"
	jwt "github.com/dgrijalva/jwt-go"
	konfig "github.com/koding/kite/config"
	"github.com/koding/kite/kitekey"
)

// KonfigCache is a default konfig.bolt configuration.
//
// The konfig.bolt stores user configuration for
// KD / Klient apps.
var KonfigCache = &CacheOptions{
	File: filepath.Join(KodingHome(), "konfig.bolt"),
	BoltDB: &bolt.Options{
		Timeout: 5 * time.Second,
	},
	Bucket: []byte("konfig"),
}

// Endpoints represents a configuration of Koding
// endpoints, which are used by KD / Klient.
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

// Kloud gives an endpoint for Kloud kite.
func (e *Endpoints) Kloud() *Endpoint {
	return e.Koding.WithPath("/kloud/kite")
}

// Kontrol gives an endpoint for Kontrol kite.
func (e *Endpoints) Kontrol() *Endpoint {
	return e.Koding.WithPath("/kontrol/kite")
}

// Remote gives an endpoint for remote.api.
func (e *Endpoints) Remote() *Endpoint {
	return e.Koding.WithPath("/remote.api")
}

// Social gives an endpoint for social.api.
func (e *Endpoints) Social() *Endpoint {
	return e.Koding.WithPath("/api/social")
}

// Mount describes configuration of mounts.
type Mount struct {
	// Mount is a default home path of mounted directories.
	//
	// If empty, defaults to ~/koding/mnt/.
	Home string `json:"home,omitempty"`

	// Exports maps named mounts to local paths.
	//
	// The Exports["default"] export is used as
	// a default one when caller does not specify
	// a mount path.
	//
	// The Exports["default"] defaults to $HOME.
	Exports map[string]string `json:"exports,omitempty"`

	// Inspect configures behavior of mount inspect command.
	Inspect *MountInspect `json:"inspect,omitempty"`

	// Sync configures behavior of synchronization goroutines.
	Sync *MountSync `json:"sync,omitempty"`

	// Debug is a debug level used for logging within
	// mounts.
	//
	//   <=0  - turns off debug logging
	//   1    - turns on debug logging for syncer events
	//   2-8  - reserved for future use
	//   >=9  - turns on debug logging for fuse events
	//
	Debug int `json:"debug,omitempty,string"`
}

// MountInspect describes configuration of mount inspect command.
type MountInspect struct {
	// History configures the length of inspect history,
	// which is 100 by default.
	History int `json:"history,omitempty,string"`
}

// MountSync describes configuration of synchronization goroutines.
type MountSync struct {
	// Workers configures number of concurrent rsync processes,
	// which is 2 * cpu by default.
	Workers int `json:"workers,omitempty,string"`
}

// Export gives a path for the named mount.
//
// If the named mount does not exist, it returns false.
//
// If the path contains '~' - it is expended to
// a home directory of a current user.
func (m *Mount) Export(name string) (string, bool) {
	if m == nil {
		return "", false
	}

	if dir, ok := m.Exports[name]; ok {
		return expandHome(dir), true
	}

	return "", false
}

// Template represents a KD template configuration.
type Template struct {
	File string `json:"file,omitempty"`
}

// Konfig represents a single configuration stored
// in a konfig.bolt database.
type Konfig struct {
	Endpoints *Endpoints `json:"endpoints,omitempty"`

	KontrolURL string `json:"kontrolURL,omitempty"` // deprecated / read-only
	TunnelURL  string `json:"tunnelURL,omitempty"`  // deprecated / read-only

	// Kite configuration.
	Environment string `json:"environment,omitempty"`
	KiteKeyFile string `json:"kiteKeyFile,omitempty"`
	KiteKey     string `json:"kiteKey,omitempty"`

	// Mount describes configuration of mounts.
	Mount *Mount `json:"mount,omitempty"`

	// Template describes configuration of KD template.
	Template *Template `json:"template,omitempty"`

	// Koding networking configuration.
	//
	// TODO(rjeczalik): store command line flags in konfig.bolt
	// per Koding executable (KD / Klient).
	TunnelID string `json:"tunnelID,omitempty"`

	// Public S3 bucket for writing logs.
	PublicBucketName   string `json:"publicBucketName,omitempty"`
	PublicBucketRegion string `json:"publicBucketRegion,omitempty"`

	LockTimeout    int  `json:"lockTimeout,omitempty,string"`
	DisableMetrics bool `json:"disableMetrics,string,omitempty"`
	Debug          bool `json:"debug,string,omitempty"`
}

// KiteHome gives directory of the kite.key file.
//
// Deprecated: Use KiteKeyFile instead.
func (k *Konfig) KiteHome() string {
	return filepath.Dir(k.KiteKeyFile)
}

// KiteConfig build *kite.Config value which is used
// to initialize new kite.Kite values.
func (k *Konfig) KiteConfig() *konfig.Config {
	return k.buildKiteConfig()
}

// KlientGzURL gives an URL for Klient binary.
//
// TODO(rjeczalik): Rework into lookup and move to kloud/metadata package.
func (k *Konfig) KlientGzURL() string {
	u := *k.Endpoints.KlientLatest.Public.URL
	u.Path = path.Join(path.Dir(u.Path), "latest", "klient.gz")
	return u.String()
}

// Valid implements the stack.Validator interface.
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

// ID gives an identifier of the Konfig value.
//
// The konfig.bolt stores multiple configurations, one for each
// baseurl.
//
// The ID is unique per baseurl.
func (k *Konfig) ID() string {
	return ID(k.KodingPublic().String())
}

// ID creates an identifier for the given Koding base URL.
func ID(kodingURL string) string {
	if kodingURL == "" {
		return ""
	}
	if u, err := url.Parse(kodingURL); err == nil {
		// Since id is input sensitive we clean the path so "example.com/koding"
		// "example.com/koding/" are effectively the same urls.
		u.Path = strings.TrimRight(path.Clean(u.Path), "/")
		switch u.Scheme {
		case "http":
			u.Host = strings.TrimSuffix(u.Host, ":80")
		case "https":
			u.Host = strings.TrimSuffix(u.Host, ":443")
		}
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

// NewKonfigURL gives new configuration for the given base URL.
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

// NewKonfig creates new configuration by reading
// embedded kites/config/config.json file.
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
		Mount: &Mount{
			Home: filepath.Join(CurrentUser.HomeDir, "koding", "mnt"),
			Exports: map[string]string{
				"default": CurrentUser.HomeDir,
			},
			Inspect: &MountInspect{
				History: 100,
			},
			Sync: &MountSync{
				Workers: 2 * runtime.NumCPU(),
			},
		},
		Template: &Template{
			File: "kd.yaml",
		},
		PublicBucketName:   Builtin.Buckets.PublicLogs.Name,
		PublicBucketRegion: Builtin.Buckets.PublicLogs.Region,
		LockTimeout:        3,
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
