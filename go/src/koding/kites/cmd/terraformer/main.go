package main

import (
	"koding/artifact"
	"koding/kites/common"
	"koding/kites/terraformer"

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

	// Load the config, it's reads environment variables or from flags
	multiconfig.New().MustLoad(conf)

	k := newKite(conf)

	if conf.Debug {
		k.Log.Info("Debug mode enabled")
	}

	registerURL := k.RegisterURL(true)

	if err := k.RegisterForever(registerURL); err != nil {
		k.Log.Fatal(err.Error())
	}

	k.Run()
}

func newKite(conf *terraformer.Config) *kite.Kite {
	k := kite.New(Name, Version)
	k.Config = kiteconfig.MustGet()
	k.Config.Port = conf.Port

	if conf.Region != "" {
		k.Config.Region = conf.Region
	}

	if conf.Environment != "" {
		k.Config.Environment = conf.Environment
	}

	stats := common.MustInitMetrics(Name)

	t := terraformer.New()
	t.Metrics = stats
	t.Log = common.NewLogger(Name, conf.Debug)

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
