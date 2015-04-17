package main

import (
	"io/ioutil"
	"koding/artifact"
	"koding/kites/cmd/terraformer/pkg"
	"koding/kites/common"
	"koding/kites/terraformer"
	"koding/kites/terraformer/commands"
	"log"
	"os"

	"github.com/hashicorp/terraform/plugin"
	"github.com/koding/kite"
	kiteconfig "github.com/koding/kite/config"
	"github.com/koding/metrics"
	"github.com/koding/multiconfig"
)

var (
	Name    = "terraformer"
	Version = "0.0.1"
)

func main() {
	conf := &terraformer.Config{}

	// Load the config, reads environment variables or from flags
	multiconfig.New().MustLoad(conf)

	log.SetOutput(ioutil.Discard) // terraform outputs many logs, discard them

	c := createContex()

	// Make sure we clean up any managed plugins at the end of this
	defer plugin.CleanupClients()

	k := newKite(conf, c)

	registerURL := k.RegisterURL(true)

	if err := k.RegisterForever(registerURL); err != nil {
		k.Log.Fatal(err.Error())
	}

	k.Run()
}

func createContex() *commands.Context {
	log.SetOutput(ioutil.Discard) // terraform outputs many logs, discard them

	config := pkg.BuiltinConfig
	if err := config.Discover(); err != nil {
		os.Exit(1)
	}

	providers := config.ProviderFactories()
	provisioners := config.ProvisionerFactories()

	return commands.NewContext(providers, provisioners)
}

func newKite(conf *terraformer.Config, c *commands.Context) *kite.Kite {
	k := kite.New(Name, Version)
	k.Config = kiteconfig.MustGet()
	k.Config.Port = conf.Port
	k.Config.DisableAuthentication = true //TODO make this configurable

	if conf.Region != "" {
		k.Config.Region = conf.Region
	}

	if conf.Environment != "" {
		k.Config.Environment = conf.Environment
	}

	if conf.Debug {
		k.SetLogLevel(kite.DEBUG)
	}

	stats := common.MustInitMetrics(Name)

	t := terraformer.New()
	t.Metrics = stats
	t.Log = common.NewLogger(Name, conf.Debug)
	t.Debug = conf.Debug
	t.Context = c

	// track every kind of call
	k.PreHandleFunc(createTracker(stats))

	// Terraformer handling methods
	k.HandleFunc("apply", t.Apply)
	k.HandleFunc("destroy", t.Destroy)
	k.HandleFunc("plan", t.Plan)

	k.HandleHTTPFunc("/healthCheck", artifact.HealthCheckHandler(Name))
	k.HandleHTTPFunc("/version", artifact.VersionHandler())

	return k
}

func createTracker(metrics *metrics.DogStatsD) kite.HandlerFunc {
	return func(r *kite.Request) (interface{}, error) {
		metrics.Count(
			"functionCallCount", // metric name
			1,                   // count
			[]string{"funcName:" + r.Method}, // tags for metric call
			1.0, // rate
		)

		return true, nil
	}
}
