package terraformer

import (
	"errors"
	"koding/artifact"
	"koding/kites/terraformer/secretkey"

	"github.com/koding/kite"
	kiteconfig "github.com/koding/kite/config"
	"github.com/koding/metrics"
)

func (t *Terraformer) newKite(conf *Config) (*kite.Kite, error) {
	var err error
	k := kite.New(Name, Version)
	k.Config, err = kiteconfig.Get()
	if err != nil {
		return nil, err
	}

	k = t.setupKite(k, conf)

	// track every kind of call
	k.PreHandleFunc(createTracker(t.Metrics))

	// Terraformer handling methods
	k.HandleFunc("apply", t.Apply)
	k.HandleFunc("destroy", t.Destroy)
	k.HandleFunc("plan", t.Plan)

	// artifact handling
	k.HandleHTTPFunc("/healthCheck", artifact.HealthCheckHandler(Name))
	k.HandleHTTPFunc("/version", artifact.VersionHandler())

	// allow kloud to make calls to us
	k.Authenticators["kloud"] = func(r *kite.Request) error {
		if r.Auth.Key != secretkey.TerraformSecretKey {
			return errors.New("wrong secret key passed, you are not authenticated")
		}
		return nil
	}

	return k, nil
}

func (t *Terraformer) setupKite(k *kite.Kite, conf *Config) *kite.Kite {

	k.Config.Port = conf.Port

	if conf.Region != "" {
		k.Config.Region = conf.Region
	}

	if conf.Environment != "" {
		k.Config.Environment = conf.Environment
	}

	if t.Debug {
		k.SetLogLevel(kite.DEBUG)
	}

	if conf.Test {
		k.Config.DisableAuthentication = true
	}

	return k
}

func createTracker(metrics *metrics.DogStatsD) kite.HandlerFunc {
	return func(r *kite.Request) (interface{}, error) {
		// if metrics not set, act as noop
		if metrics == nil {
			return true, nil
		}

		if err := metrics.Count(
			"callCount", // metric name
			1,           // count
			[]string{"funcName:" + r.Method}, // tags for metric call
			1.0, // rate
		); err != nil {
			// TODO(cihangir) should we log/return error?
		}

		return true, nil
	}
}
