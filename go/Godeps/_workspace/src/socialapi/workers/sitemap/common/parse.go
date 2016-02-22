package common

import (
	"socialapi/config"
	"time"
)

const DefaultInterval = 30 * time.Minute

func GetInterval() time.Duration {
	updateInterval := config.MustGet().Sitemap.UpdateInterval
	if updateInterval == "" {
		return DefaultInterval
	}

	t, err := time.ParseDuration(updateInterval)
	if err != nil {
		panic(err)
	}

	return t
}
