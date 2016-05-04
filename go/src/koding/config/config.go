package config

import "encoding/json"

//go:generate $GOPATH/bin/go-bindata -mode 420 -modtime 1446555960 -pkg config -o config.json.go config.json

// Builtin represents an embedded configuration.
var Builtin *Config

// Config contains default values for services.
type Config struct {
	Endpoints Endpoints `json:"endpoints"`
}

// Endpoint represents a single worker's endpoint
// mapped to environments
type Endpoint struct {
	Environment []string `json:"environment"`
	URL         string   `json:"url"`
}

// Endpoints describes all workers and
// their default configuration.
type Endpoints map[string][]*Endpoint

// URL gives a url address for the given worker and environment.
//
// If specified worker does not exist
func (e Endpoints) URL(worker, environment string) string {
	endpoints, ok := e[worker]
	if !ok {
		return ""
	}

	var url string

	for _, endpoint := range endpoints {
		// Default URL is an endpoint with no explicit
		// environments set.
		if len(endpoint.Environment) == 0 {
			url = endpoint.URL
			continue
		}

		for _, env := range endpoint.Environment {
			switch env {
			case environment:
				return endpoint.URL
			case "development", "devmanaged":
				// If there's no default endpoint we fallback
				// to a development one.
				if url == "" {
					url = endpoint.URL
				}
			}
		}
	}

	return url
}

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
