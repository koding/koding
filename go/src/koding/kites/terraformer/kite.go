package terraformer

import (
	"koding/artifact"
	"koding/kites/common"
	"koding/kites/terraformer/kodingcontext"

	"github.com/koding/kite"
	kiteconfig "github.com/koding/kite/config"
	"github.com/koding/logging"
	"github.com/koding/metrics"
)

func NewKite(conf *Config, c *kodingcontext.Context, log logging.Logger) (*kite.Kite, error) {
	var err error
	k := kite.New(Name, Version)
	k.Config, err = kiteconfig.Get()
	if err != nil {
		return nil, err
	}

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

	// init terraformer
	t := New()
	t.Metrics = common.MustInitMetrics(Name)
	t.Log = log
	t.Debug = conf.Debug
	t.Context = c

	// track every kind of call
	k.PreHandleFunc(createTracker(t.Metrics))

	// Terraformer handling methods
	k.HandleFunc("apply", t.Apply)
	k.HandleFunc("destroy", t.Destroy)
	k.HandleFunc("plan", t.Plan)

	// artifact handling
	k.HandleHTTPFunc("/healthCheck", artifact.HealthCheckHandler(Name))
	k.HandleHTTPFunc("/version", artifact.VersionHandler())

	return k, nil
}

func createTracker(metrics *metrics.DogStatsD) kite.HandlerFunc {
	return func(r *kite.Request) (interface{}, error) {
		metrics.Count(
			"callCount", // metric name
			1,           // count
			[]string{"funcName:" + r.Method}, // tags for metric call
			1.0, // rate
		)

		return true, nil
	}
}
