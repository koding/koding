package config

import (
	"bytes"
	"encoding/json"
	"flag"
	"net/url"
	"path"
	"strconv"
	"strings"

	"github.com/koding/multiconfig"
)

//go:generate go run genconfig.go -pkg config -i config.json -o config.json.go

// Builtin stores configuration that was generated at compile time.
var Builtin *Config

func init() {
	rawCfg := MustAsset("config.json")

	loaders := []multiconfig.Loader{
		&multiconfig.JSONLoader{Reader: bytes.NewReader(rawCfg)},
		&multiconfig.EnvironmentLoader{Prefix: "KONFIG_GOKODING"},
	}

	d := &multiconfig.DefaultLoader{
		Loader:    multiconfig.MultiLoader(loaders...),
		Validator: &multiconfig.RequiredValidator{},
	}

	Builtin = &Config{}

	d.MustLoad(Builtin)
	d.MustValidate(Builtin)

	// set global compile time environment.
	environment = Builtin.Environment

	// Check if routes values are correct.
	for route, host := range Builtin.Routes {
		if host == "" {
			panic("empty host for route: " + route)
		}
	}
}

// environment defines the environment on which configuration was generated.
var environment string

// URL is a wrapper for url.URL that implements the following interfaces:
//
//   - flag.Getter
//   - json.Marshaler
//   - json.Unmarshaler
//
type URL struct {
	*url.URL
}

var (
	_ flag.Getter      = (*URL)(nil)
	_ json.Marshaler   = (*URL)(nil)
	_ json.Unmarshaler = (*URL)(nil)
)

// Get implements the flag.Getter interface.
func (u URL) Get() interface{} {
	return u.URL
}

// Set implements the flag.Value interface.
func (u *URL) Set(s string) error {
	ur, err := url.Parse(s)
	if err != nil {
		return err
	}
	u.URL = ur
	return nil
}

// Unmarshal implements the json.Unmarshaler interface.
func (u *URL) UnmarshalJSON(p []byte) error {
	s, err := strconv.Unquote(string(p))
	if err != nil {
		return err
	}
	u.URL, err = url.Parse(s)
	return err
}

// MarshalJSON implements the json.Marshaler interface.
func (u *URL) MarshalJSON() ([]byte, error) {
	return []byte(strconv.Quote(u.String())), nil
}

// WithPath gives new URL with append paths to its Path field.
func (u *URL) WithPath(paths ...string) *url.URL {
	ur := *u.URL
	ur.Path = path.Join(ur.Path, path.Join(paths...))
	return &ur
}

// Endpoint represents a single endpoint.
type Endpoint struct {
	Public  *URL `json:"public,omitempty"`
	Private *URL `json:"private,omitempty"`
}

// Config stores all static configuration data generated during ./configure phase.
type Config struct {
	Environment string `json:"environment" required:"true"`
	Buckets     struct {
		PublicLogs Bucket `json:"publicLogs" required:"true"`
	} `json:"buckets" required:"true"`
	Endpoints struct {
		IP           string    `json:"ip" required:"true"`
		IPCheck      string    `json:"ipCheck" required:"true"`
		KDLatest     string    `json:"kdLatest" required:"true"`
		KlientLatest string    `json:"klientLatest" required:"true"`
		Kloud        string    `json:"kloud" required:"true"`
		KodingBase   string    `json:"kodingBase" required:"true"`
		Kontrol      string    `json:"kontrol" required:"true"`
		RemoteAPI    *Endpoint `json:"remoteAPI" requied:"true"`
		TunnelServer string    `json:"tunnelServer" required:"true"`
		SocialAPI    *Endpoint `json:"socialAPI" requied:"true"`
	}
	Routes map[string]string `json:"routes"`
}

// Bucket represents a S3 storage bucket. It stores bucket name and the physical
// region in which bucket was created.
type Bucket struct {
	Name   string `json:"name" required:"true"`
	Region string `json:"region" required:"true"`
}

// ReplaceEnv should be used in case when caller environment is different than
// the build in one. This function should be removed when service environments
// are unified/cleaned.
func ReplaceEnv(variable, env string) string {
	// This is a workaround when caller's env doesn't match build in one.
	return strings.Replace(variable, environment, RmAlias(env), -1)
}

var defaultAliases = aliases{
	"production":  {},
	"managed":     {},
	"development": {"sandbox", "default", "dev"},
	"devmanaged":  {},
}

type aliases map[string][]string

// RmAlias removes aliased environments like sandbox which is in fact
// a development build. If provided environment is not found, this function
// returns build in environment.
func RmAlias(env string) string {
	return rmAlias(env, environment)
}

func rmAlias(env, defaultEnv string) string {
	for e := range defaultAliases {
		if e == env {
			return e
		}

		// Lookup for environment aliases.
		for _, alias := range defaultAliases[e] {
			if alias == env {
				return e
			}
		}
	}

	return defaultEnv
}

// RmManaged maps managed environments to their build in counterparts.
func RmManaged(env string) string {
	switch env {
	case "managed":
		return "production"
	case "devmanaged":
		return "development"
	default:
		return env
	}
}
