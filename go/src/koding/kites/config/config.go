package config

import "encoding/json"

//go:generate go run genconfig.go -o config.json
//go:generate $GOPATH/bin/go-bindata -mode 420 -modtime 1446555960 -pkg config -o config.json.go config.json

func init() {
	p, err := Asset("config.json")
	if err != nil {
		panic(err)
	}

	Builtin = &Config{}

	if err := json.Unmarshal(p, Builtin); err != nil {
		panic(err)
	}
}

// Builtin represents an embedded configuration.
var Builtin *Config

// Config contains default values for services.
type Config struct {
	Buckets   Buckets           `json:"buckets"`
	Endpoints Endpoints         `json:"endpoints"`
	Routes    map[string]string `json:"routes"`
}

// Merge attaches values from input Config object to caller object.
func (c *Config) Merge(in *Config) {
	if in == nil {
		return
	}

	// Merge buckets or attach these from input.
	if c.Buckets == nil {
		c.Buckets = make(Buckets)
	}
	c.Buckets.merge(in.Buckets)

	// Merge endpoint or attach these from input.
	if c.Endpoints == nil {
		c.Endpoints = make(Endpoints)
	}
	c.Endpoints.merge(in.Endpoints)

	// Merge routes.
	if c.Routes == nil {
		c.Routes = make(map[string]string)
	}
	for name, addr := range in.Routes {
		c.Routes[name] = addr
	}
}

// removeStrings removes provided strings from src string slice.
func removeStrings(src []string, rm ...string) (result []string) {
loop:
	for i := range src {
		for j := range rm {
			if src[i] == rm[j] {
				continue loop
			}
		}
		result = append(result, src[i])
	}

	return result
}
