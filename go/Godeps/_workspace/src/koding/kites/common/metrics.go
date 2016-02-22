package common

import "github.com/koding/metrics"

func MustInitMetrics(name string) *metrics.DogStatsD {
	stats, err := metrics.NewDogStatsD(name)
	if err != nil {
		panic(err)
	}

	return stats
}
