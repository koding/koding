package common

import dogstatsd "github.com/DataDog/datadog-go/statsd"

// MustInitMetrics inits dogstats client.
func MustInitMetrics(name string) *dogstatsd.Client {
	stats, err := dogstatsd.New("127.0.0.1:8125")
	if err != nil {
		panic(err)
	}

	stats.Namespace = name + "_"
	return stats
}
