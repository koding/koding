package config

import (
	"bytes"
	"encoding/json"
	"fmt"
	"strings"
	"text/template"

	"github.com/koding/logging"
)

//go:generate go run genconfig.go -o config.go
//go:generate go fmt config.go

var defaultAliases = aliases{
	"production":  {},
	"managed":     {},
	"development": {"sandbox", "default", "dev"},
	"devmanaged":  {},
}

type aliases map[string][]string

// Get removes aliased environments like sandbox which is in fact a development
// build. If provided environment is not found, this function returns defaultEnv.
func (a aliases) Get(env, defaultEnv string) string {
	for e := range a {
		if e == env {
			return e
		}

		// Lookup for environment aliases.
		for _, alias := range a[e] {
			if alias == env {
				return e
			}
		}
	}

	return defaultEnv
}

var defaultGroups = groups{
	{"production", "managed"},
	{"development", "devmanaged"},
}

type groups [][]string

// SameGroup checks if provided environments belong to the same environment
// group.
func (g groups) SameGroup(enva, envb string) bool {
	if enva == envb {
		return true
	}

	idxa, idxb := -1, -1
	for i := range g {
		for j := range g[i] {
			if g[i][j] == enva {
				idxa = i
			}
			if g[i][j] == envb {
				idxb = i
			}
		}
	}

	return idxa == idxb
}

// Get gets group name. This function converts managed environments to its
// compile time counterparts.
func (g groups) Get(env string) string {
	for i := range g {
		for j := range g[i] {
			if g[i][j] == env {
				return g[i][0]
			}
		}
	}

	// This function always receives environments defined in defaultAliases
	// map. It means that if we reach this panic, we have made a programming
	// error.
	panic("unknown environment: " + env)
}

type params struct {
	Environment string `json:"environment"`
	Group       string `json:"group"`
}

// Bucket represents a S3 storage bucket. It stores bucket name and the physical
// region in which bucket was created.
type Bucket struct {
	Name   string `json:"name"`
	Region string `json:"region"`
}

// Config stores the configuration of application. It holds endpoints, routes
// and buckets.
type Config struct {
	Environment string
	Log         logging.Logger
	Host2ip     map[string]string

	tmpls map[string]*template.Template
}

// Clone performs a deep copy of underlying Config object.
func (c *Config) Clone() (*Config, error) {
	// Shallow copy.
	clon := *c

	clon.Host2ip = make(map[string]string)
	for host, ip := range c.Host2ip {
		clon.Host2ip[host] = ip
	}

	clon.tmpls = make(map[string]*template.Template)
	for typeName, tmpl := range c.tmpls {
		tmplClon, err := tmpl.Clone()
		if err != nil {
			return nil, err
		}

		clon.tmpls[typeName] = tmplClon
	}

	return &clon, nil
}

// GetEnvironment tries to deduce the real environment of provided env string.
// Eg. If `managed` environment is passed, this function will recognize that
// managed environment is for production builds. It will check if configuration
// was build for production environments and return valid environment name. In
// example above it will be `production` string.
func (c *Config) GetEnvironment(env string) string {
	env = defaultAliases.Get(env, c.Environment)

	if !defaultGroups.SameGroup(env, c.Environment) {
		c.log().Warning("unrecognized environment %q; %q will be used instead", env, c.Environment)
	}

	return env
}

func (c *Config) log() logging.Logger {
	if c.Log == nil {
		return logging.DefaultLogger
	}

	return c.Log
}

// GetBucket returns a bucket object generated from compiled template.
//
// `typeName` defines compiled configuration variable key.
//
// Key prefix is either `buckets.` for Buckets.
func (c *Config) GetBucket(typeName, env string) (*Bucket, error) {
	tmpl, ok := c.tmpls[typeName]
	if !ok {
		name := strings.TrimLeft(typeName, "buckets.")
		return nil, fmt.Errorf("cannot find bucket info for %q", name)
	}

	buf := &bytes.Buffer{}
	if err := tmpl.Execute(buf, params{Environment: env, Group: defaultGroups.Get(env)}); err != nil {
		return nil, err
	}

	var bucket = &Bucket{}
	if err := json.NewDecoder(buf).Decode(bucket); err != nil {
		return nil, err
	}

	return bucket, nil
}

// SetBucket allows to set or replace already stored bucket template. This
// function should be used only during development when one wants to temporarily
// replace or add new bucket to configuration.
func (c *Config) SetBucket(typeName string, b *Bucket) error {
	data, err := json.Marshal(b)
	if err != nil {
		return err
	}

	c.tmpls[typeName] = template.Must(template.New(typeName).Parse(string(data)))
	return nil
}

// GetEndpoint returns a URL string generated from compiled template.
//
// `typeName` defines compiled configuration variable key.
//
// Key prefix is `endpoints.` for endpoints.
func (c *Config) GetEndpoint(typeName, env string) (string, error) {
	tmpl, ok := c.tmpls[typeName]
	if !ok {
		name := strings.TrimLeft(typeName, "endpoints.")
		return "", fmt.Errorf("cannot find endpoint info for %q", name)
	}

	buf := &bytes.Buffer{}
	if err := tmpl.Execute(buf, params{Environment: env, Group: defaultGroups.Get(env)}); err != nil {
		return "", err
	}

	var endpoint = ""
	if err := json.NewDecoder(buf).Decode(&endpoint); err != nil {
		return "", err
	}

	return endpoint, nil
}

// SetEndpoint allows to set or replace already stored endpoint template. This
// function should be used only during development when one wants to temporarily
// replace or add new endpoint to configuration.
func (c *Config) SetEndpoint(typeName, e string) error {
	c.tmpls[typeName] = template.Must(template.New(typeName).Parse(`"` + e + `"`))
	return nil
}

// Route maps host names to IP addresses.
func (c *Config) Route(host string) string {
	return c.Host2ip[host]
}

// Route maps host names to IP addresses.
//
// Route is a wrapper around DefaultConfig.Route.
func Route(host string) string {
	return DefaultConfig.Route(host)
}
