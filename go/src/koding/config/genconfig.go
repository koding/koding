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

type group int

// envGroups describes relations between environments. Since some of them can
// share identical configuration values.
type envGroups map[bool][][]string

var defaultGroups envGroups = map[bool][][]string{
	true: {
		{"default"}, // local builds.
		{"dev", "development", "sandbox", "devmanaged"}, // development builds.
		{"production", "managed"},                       // production builds.
	},
	false: {
		{"default"},                       // local builds.
		{"dev", "development", "sandbox"}, // development builds.
		{"devmanaged"},                    // development managed builds.
		{"production"},                    // production builds.
		{"managed"},                       // production managed.
	},
}

// Get gets the environment group. If defaultGroups variable doesn't have
// specified environment, returned slice will contain one element equal to
// provided function argument.
func (e envGroups) Get(withManaged bool, environment string) []string {
	for _, dg := range defaultGroups[withManaged] {
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
func bucketEnv(withManaged bool, name, bucketEnv, regionEnv string) func(string) *config.Config {
	return func(environment string) *config.Config {
		bucket := &config.Bucket{
			Environment: defaultGroups.Get(withManaged, environment),
			Name:        os.Getenv(bucketEnv),
			Region:      os.Getenv(regionEnv),
		}

		// If bucket is undefined we skips it.
		if bucket.Name == "" {
			return nil
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
func endpointEnv(withManaged bool, name, urlEnv, urlPath string) func(string) *config.Config {
	// All provided environment keys are required to exist.
	mustEnvVar(urlEnv)
	return func(environment string) *config.Config {
		endpoint := &config.Endpoint{
			Environment: defaultGroups.Get(withManaged, environment),
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
func endpointDefault(withManaged bool, name, environment, url string) func(string) *config.Config {
	return func(_ string) *config.Config {
		endpoint := &config.Endpoint{
			Environment: defaultGroups.Get(withManaged, environment),
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

func mustEnvVar(keys ...string) {
	for _, key := range keys {
		if _, ok := os.LookupEnv(key); !ok {
			panic("missing environment key for " + key)
		}
	}
}

// constructors variable describes the order of configuration construction.
//
// TODO(ppknap): All *Default constructors should be moved to environment and
// handled by ./configure script.
var constructors = []func(string) *config.Config{
	endpointDefault(true, "ip", "production", "https://p.koding.com/-/ip"),
	endpointDefault(true, "ip", "default", "https://dev-p2.koding.com/-/ip"),
	endpointDefault(true, "ip", "development", "https://dev-p2.koding.com/-/ip"),
	endpointDefault(true, "ipcheck", "production", "https://p.koding.com/-/ipcheck"),
	endpointDefault(true, "ipcheck", "default", "https://dev-p2.koding.com/-/ipcheck"),
	endpointDefault(true, "ipcheck", "development", "https://dev-p2.koding.com/-/ipcheck"),
	endpointDefault(true, "kd-latest", "production", "https://koding-kd.s3.amazonaws.com/production/latest-version.txt"),
	endpointDefault(true, "kd-latest", "default", "https://koding-kd.s3.amazonaws.com/development/latest-version.txt"),
	endpointDefault(true, "kd-latest", "development", "https://koding-kd.s3.amazonaws.com/development/latest-version.txt"),
	endpointDefault(false, "klient-latest", "default", "https://koding-klient.s3.amazonaws.com/development/latest-version.txt"),
	endpointDefault(false, "klient-latest", "production", "https://koding-klient.s3.amazonaws.com/production/latest-version.txt"),
	endpointDefault(false, "klient-latest", "managed", "https://koding-klient.s3.amazonaws.com/managed/latest-version.txt"),
	endpointDefault(false, "klient-latest", "development", "https://koding-klient.s3.amazonaws.com/development/latest-version.txt"),
	endpointDefault(false, "klient-latest", "devmanaged", "https://koding-klient.s3.amazonaws.com/devmanaged/latest-version.txt"),

	routeDefault("dev.koding.com", "127.0.0.1"),

	bucketEnv(true, "publiclogs", "KONFIG_KLOUD_KEYGENBUCKET", "KONFIG_KLOUD_REGION"),

	endpointEnv(true, "kloud", "KONFIG_KLOUD_REGISTERURL", ""),
	endpointEnv(true, "kontrol", "KONFIG_KLOUD_KONTROLURL", ""),
	endpointEnv(true, "tunnelserver", "KONFIG_KLOUD_TUNNELURL", "/kite"),
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
