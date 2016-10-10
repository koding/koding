// +build ignore

package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"log"
	"os"
	"path"

	config "."
)

// envGroups describes relations between environments. Since some of them can
// share identical configuration values.
type envGroups [][]string

var defaultGroups envGroups = [][]string{
	{"default"}, // local builds.
	{"dev", "development", "devmanaged", "sandbox"}, // development builds.
	{"production", "managed"},                       // production builds.
}

// Get gets the environment group. If defaultGroups variable doesn't have
// specified environment, returned slice will contain one element equal to
// provided function argument.
func (e envGroups) Get(environment string) []string {
	for _, dg := range defaultGroups {
		for i := range dg {
			if dg[i] == environment {
				return dg
			}
		}
	}

	return []string{environment}
}

// bucketEnv produces configuration constructor function that can create
// configuration with single bucket. Bucket data is taken from system
// environment.
func bucketEnv(name, bucketEnv, regionEnv string) func(string) *config.Config {
	return func(environment string) *config.Config {
		bucket := &config.Bucket{
			Environment: defaultGroups.Get(environment),
			Name:        os.Getenv(bucketEnv),
			Region:      os.Getenv(regionEnv),
		}

		// Some configurations returns `aws` when they want to use `us-east-1`
		// region.
		if bucket.Region == "aws" {
			bucket.Region = "us-east-1"
		}

		return &config.Config{
			Buckets: config.Buckets{
				name: []*config.Bucket{bucket},
			},
		}
	}
}

// endpointEnv produces configuration constructor function that can create
// configuration with single endpoint. Endpoint data is taken from system
// environment.
func endpointEnv(name, urlEnv, urlPath string) func(string) *config.Config {
	return func(environment string) *config.Config {
		endpoint := &config.Endpoint{
			Environment: defaultGroups.Get(environment),
			URL:         os.Getenv(urlEnv),
		}

		// Don't do anything if URL is empty.
		if endpoint.URL == "" {
			return nil
		}

		// Attach urlPath to URL if it's not empty.
		if urlPath != "" {
			endpoint.URL = path.Join(endpoint.URL, urlPath)
		}

		return &config.Config{
			Endpoints: config.Endpoints{
				name: []*config.Endpoint{endpoint},
			},
		}
	}
}

// endpointDefault produces configuration constructor function that can create
// configuration with single endpoint. Endpoint data is taken from function
// arguments.
func endpointDefault(name, environment, url string) func(string) *config.Config {
	return func(_ string) *config.Config {
		endpoint := &config.Endpoint{
			Environment: defaultGroups.Get(environment),
			URL:         url,
		}

		return &config.Config{
			Endpoints: config.Endpoints{
				name: []*config.Endpoint{endpoint},
			},
		}
	}
}

// routeDefault produces configuration constructor function that can create
// configuration with single route. Route data is taken from function arguments.
func routeDefault(name, addr string) func(string) *config.Config {
	return func(_ string) *config.Config {
		return &config.Config{
			Routes: map[string]string{
				name: addr,
			},
		}
	}
}

// constructors variable describes the order of configuration construction.
//
// TODO(ppknap): All *Default constructors should be moved to environment and
// handled by ./configure script.
var constructors = []func(string) *config.Config{
	endpointDefault("ip", "production", "https://p.koding.com/-/ip"),
	endpointDefault("ip", "default", "https://dev-p2.koding.com/-/ip"),
	endpointDefault("ip", "development", "https://dev-p2.koding.com/-/ip"),
	endpointDefault("ipcheck", "production", "https://p.koding.com/-/ipcheck"),
	endpointDefault("ipcheck", "default", "https://dev-p2.koding.com/-/ipcheck"),
	endpointDefault("ipcheck", "development", "https://dev-p2.koding.com/-/ipcheck"),
	routeDefault("dev.koding.com", "127.0.0.1"),
	bucketEnv("publiclogs", "KONFIG_KLOUD_KEYGENBUCKET", "KONFIG_KLOUD_REGION"),
	endpointEnv("kloud", "KONFIG_KLOUD_REGISTERURL", ""),
	endpointEnv("kontrol", "KONFIG_KLOUD_KONTROLURL", ""),
	endpointEnv("tunnelserver", "KONFIG_KLOUD_TUNNELURL", "/kite"),
}

var output = flag.String("o", "-", "")

func main() {
	flag.Parse()

	environment := "default"
	if e := os.Getenv("KONFIG_KLOUD_ENVIRONMENT"); e != "" {
		environment = e
	}

	cfg := &config.Config{}
	for _, fn := range constructors {
		cfg.Merge(fn(environment))
	}

	b, err := json.Marshal(cfg)
	if err != nil {
		log.Fatal(err)
	}

	var out bytes.Buffer
	json.Indent(&out, b, "", "  ")

	w := os.Stdout
	if *output != "-" && *output != "" {
		f, err := os.Create(*output)
		if err != nil {
			log.Fatal(err)
		}
		w = f
	}
	defer w.Close()

	if _, err := out.WriteTo(w); err != nil {
		log.Fatal(err)
	}
}
