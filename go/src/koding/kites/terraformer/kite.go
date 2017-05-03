package terraformer

import (
	"errors"
	"koding/artifact"
	"koding/kites/common"
	"koding/kites/config"

	"github.com/koding/kite"

	dogstatsd "github.com/DataDog/datadog-go/statsd"
)

// NewKite creates a new kite for serving terraformer
func NewKite(t *Terraformer, conf *Config) (*kite.Kite, error) {
	cfg, err := config.ReadKiteConfig(conf.Debug)
	if err != nil {
		return nil, err
	}

	k := setupKite(kite.NewWithConfig(Name, Version, cfg), conf)

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
	return metricName, common.WrapKiteHandler(dd, "terraformer", metricName, handler)
}

func setupKite(k *kite.Kite, conf *Config) *kite.Kite {

	k.Config.Port = conf.Port

	if conf.Region != "" {
		k.Config.Region = conf.Region
	}

	if conf.Environment != "" {
		k.Config.Environment = conf.Environment
	}

	if conf.Debug {
		k.SetLogLevel(kite.DEBUG)
	}

	if conf.Test {
		k.Config.DisableAuthentication = true
	}

	return k
}
