package config

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"net"
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

	// Check if routes values are correct.
	for route, host := range Builtin.Routes {
		if host == "" {
			panic("empty host for route: " + route)
		}
	}
}

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
func (u *URL) WithPath(paths ...string) *URL {
	ur := *u.URL
	ur.Path = path.Join(ur.Path, path.Join(paths...))
	return &URL{URL: &ur}
}

// Copy returns a copy of the u.
func (u *URL) Copy() *URL {
	if u.IsNil() {
		return nil
	}

	uCopy := *u.URL
	if u.URL.User != nil {
		userCopy := *u.URL.User
		uCopy.User = &userCopy
	}

	return &URL{
		URL: &uCopy,
	}
}

// IsNil returns true if either u or the underlying url is nil.
func (u *URL) IsNil() bool {
	return u == nil || u.URL == nil
}

// Endpoint represents a single endpoint.
type Endpoint struct {
	Public  *URL `json:"public,omitempty"`
	Private *URL `json:"private,omitempty"`
}

// NewEndpoint gives new endpoint with public field set to u.
//
// The u is expected to parse as url.URL, otherwise the function
// panics.
//
// If u is empty, NewEndpoint returns zero value for an Endpoint
// type with all pointer fields initialized.
func NewEndpoint(u string) *Endpoint {
	e := &Endpoint{
		Public: &URL{URL: &url.URL{}},
	}

	if u != "" {
		var err error
		e.Public.URL, err = url.Parse(u)
		if err != nil {
			panic(fmt.Errorf("NewEndpoint(%q): %s", u, err))
		}
	}

	return e
}

// NewEndpointURL gives new endpoint with:
//
//   - public field set to u
//   - private field set to 127.0.0.1:<port>, where
//     port is port part of u.Hostname
//
// The u argument is expected to be non-nil.
func NewEndpointURL(u *url.URL) *Endpoint {
	uPriv := *u
	uPriv.Scheme = "http"
	uPriv.Host = "127.0.0.1"

	if _, port, err := net.SplitHostPort(u.Host); err == nil {
		uPriv.Host = net.JoinHostPort(uPriv.Host, port)
	}

	return &Endpoint{
		Public:  &URL{URL: u},
		Private: &URL{URL: &uPriv},
	}
}

// Equal gives true when e and rhs endpoints match.
func (e *Endpoint) Equal(rhs *Endpoint) bool {
	if (e.Public != nil) != (rhs.Public != nil) {
		return false
	}

	if e.Public != nil && e.Public.String() != rhs.Public.String() {
		return false
	}

	if (e.Private != nil) != (rhs.Private != nil) {
		return false
	}

	return e.Private == nil || e.Private.String() == rhs.Private.String()
}

// WithPath gives new Endpoint with path appended to both
// Public and Private URLs.
func (e *Endpoint) WithPath(path string) *Endpoint {
	ePath := &Endpoint{}

	if e.Public != nil {
		ePath.Public = e.Public.WithPath(path)
	}

	if e.Private != nil {
		ePath.Private = e.Private.WithPath(path)
	}

	return ePath
}

// Copy returns a copy of the e.
func (e *Endpoint) Copy() *Endpoint {
	if e.IsNil() {
		return nil
	}
	return &Endpoint{
		Public:  e.Public.Copy(),
		Private: e.Private.Copy(),
	}
}

// IsNil returns true if either e or both of the public and private urls are nil.
func (e *Endpoint) IsNil() bool {
	return e == nil || (e.Public.IsNil() && e.Private.IsNil())
}

// Config stores all static configuration data generated during ./configure phase.
type Config struct {
	Environment string `json:"environment" required:"true"`
	Buckets     struct {
		PublicLogs Bucket `json:"publicLogs" required:"true"`
	} `json:"buckets" required:"true"`
	Endpoints struct {
		IP           *Endpoint `json:"ip" required:"true"`
		IPCheck      *Endpoint `json:"ipCheck" required:"true"`
		KDLatest     *Endpoint `json:"kdLatest" required:"true"`
		KlientLatest *Endpoint `json:"klientLatest" required:"true"`
		KodingBase   *Endpoint `json:"kodingBase" required:"true"`
		TunnelServer *Endpoint `json:"tunnelServer" required:"true"`
	} `json:"endpoints"`
	Routes map[string]string `json:"routes"`
}

// KontrolPublic gives new public endpoint for the given URL.
func (c *Config) KontrolPublic() *url.URL {
	u := *c.Endpoints.KodingBase.Public.URL
	u.Path = "/kontrol/kite"
	return &u
}

// Bucket represents a S3 storage bucket. It stores bucket name and the physical
// region in which bucket was created.
type Bucket struct {
	Name   string `json:"name" required:"true"`
	Region string `json:"region" required:"true"`
}

func mustURL(s string) *URL {
	u, err := url.Parse(s)
	if err != nil {
		panic(`url.Parse("` + s + `"): ` + err.Error())
	}

	return &URL{URL: u}
}

// ReplaceEnv should be used in case when caller environment is different than
// the build in one. This function should be removed when service environments
// are unified/cleaned.
func ReplaceEnv(e *Endpoint, env string) *Endpoint {
	return ReplaceCustomEnv(e, Builtin.Environment, env)
}

// ReplaceCustomEnv should be used in case when provided environment is different than
// the build one.
//
// This function should be removed when service environments are unified/cleaned.
func ReplaceCustomEnv(e *Endpoint, env, newEnv string) *Endpoint {
	// This is a workaround when caller's env doesn't match build in one.
	eReplaced := &Endpoint{}

	if e.Public != nil {
		eReplaced.Public = mustURL(strings.Replace(e.Public.String(), env, RmAlias(newEnv), -1))
	}

	if e.Private != nil {
		eReplaced.Private = mustURL(strings.Replace(e.Private.String(), env, RmAlias(newEnv), -1))
	}

	return eReplaced
}

var defaultAliases = aliases{
	"production":  {},
	"managed":     {},
	"development": {"sandbox", "dev"},
	"devmanaged":  {},
	"default":     {},
}

type aliases map[string][]string

// RmAlias removes aliased environments like sandbox which is in fact
// a development build. If provided environment is not found, this function
// returns build in environment.
func RmAlias(env string) string {
	return rmAlias(env, Builtin.Environment)
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
