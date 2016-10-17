package config

import (
	"bytes"
	"strings"

	"github.com/koding/multiconfig"
)

//go:generate $GOPATH/bin/go-bindata -mode 420 -modtime 1476710288 -pkg config -o config.json.go config.json
//go:generate go fmt config.json.go

// Builtin stores configuration that was generated at compile time.
var Builtin *Config

func init() {
	rawCfg := MustAsset("config.json")

	loaders := []multiconfig.Loader{
		&multiconfig.JSONLoader{Reader: bytes.NewReader(rawCfg)},
		&multiconfig.EnvironmentLoader{Prefix: "KONFIG_GOKODING"},
	}

	d := &multiconfig.DefaultLoader{
		Loader: multiconfig.MultiLoader(loaders...),
	}

	Builtin = &Config{}
	if err := d.Load(Builtin); err != nil {
		panic(err)
	}

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

// Config stores all static configuration data generated during ./configure phase.
type Config struct {
	Environment string `json:"environment" required:"true"`
	Buckets     struct {
		PublicLogs Bucket `json:"publicLogs" required:"true"`
	} `json:"buckets" required:"true"`
	Endpoints struct {
		IP           Endpoint `json:"ip" required:"true"`
		IPCheck      Endpoint `json:"ipCheck" required:"true"`
		KDLatest     Endpoint `json:"kdLatest" required:"true"`
		KlientLatest Endpoint `json:"klientLatest" required:"true"`
		Kloud        Endpoint `json:"kloud" required:"true"`
		Kontrol      Endpoint `json:"kontrol" required:"true"`
		TunnelServer Endpoint `json:"tunnelServer" required:"true"`
	}
	Routes map[string]string `json:"routes"`
}

// Bucket represents a S3 storage bucket. It stores bucket name and the physical
// region in which bucket was created.
type Bucket struct {
	Name   string `json:"name" required:"true"`
	Region string `json:"region" required:"true"`
}

// Get should be used in case when caller environment may be different than
// build in one. This function should be removed when service environments are
// unified/cleaned.
func (b *Bucket) Get(env string) *Bucket {
	// This is a workaround when caller's env doesn't match build in one.
	env = RmAlias(env)
	return &Bucket{
		Name:   strings.Replace(b.Name, environment, env, -1),
		Region: b.Region,
	}
}

// Endpoint represents a URL to requested resource.
type Endpoint string

// Get should be used in case when caller environment may be different than
// build in one. This function should be removed when service environments are
// unified/cleaned.
func (e Endpoint) Get(env string) Endpoint {
	// This is a workaround when caller's env doesn't match build in one.
	env = RmAlias(env)
	return Endpoint(strings.Replace(string(e), environment, env, -1))
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
