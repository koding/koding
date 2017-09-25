package terraformer

import (
	"errors"

	"koding/artifact"
	"koding/kites/config"
	"koding/kites/metrics"

	dogstatsd "github.com/DataDog/datadog-go/statsd"
	"github.com/koding/kite"
	kitecfg "github.com/koding/kite/config"
)

// NewKite creates a new kite for serving terraformer
func NewKite(t *Terraformer, conf *Config) (*kite.Kite, error) {
	cfg, err := config.ReadKiteConfig(conf.Debug)
	if err != nil {
		return nil, err
	}

	setupKite(cfg, conf)

	k := kite.NewWithConfig(Name, Version, cfg)
	if conf.Debug {
		k.SetLogLevel(kite.DEBUG)
	}

	// handle current status of terraformer
	k.PostHandleFunc(t.handleState)

	// Terraformer handling methods
	k.HandleFunc(wrapHandler(t.Metrics, "apply", t.Apply))
	k.HandleFunc(wrapHandler(t.Metrics, "destroy", t.Destroy))
	k.HandleFunc(wrapHandler(t.Metrics, "plan", t.Plan))

	// artifact handling
	k.HandleHTTPFunc("/healthCheck", artifact.HealthCheckHandler(Name))
	k.HandleHTTPFunc("/version", artifact.VersionHandler())

	secretKey := conf.SecretKey

	// allow kloud to make calls to us
	k.Authenticators["kloud"] = func(r *kite.Request) error {
		if r.Auth.Key != secretKey {
			return errors.New("wrong secret key passed, you are not authenticated")
		}
		return nil
	}

	return k, nil
}

func wrapHandler(dd *dogstatsd.Client, metricName string, handler kite.HandlerFunc) (string, kite.HandlerFunc) {
	return metricName, metrics.WrapKiteHandler(dd, metricName, handler)
}

func setupKite(cfg *kitecfg.Config, conf *Config) {
	cfg.Port = conf.Port

	if conf.Region != "" {
		cfg.Region = conf.Region
	}

	if conf.Environment != "" {
		cfg.Environment = conf.Environment
	}

	if conf.Test {
		cfg.DisableAuthentication = true
	}

	if conf.KontrolURL != "" {
		cfg.KontrolURL = conf.KontrolURL
	}
}
