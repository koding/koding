package metrics

import (
	"log"
	"time"

	dogstatsd "github.com/DataDog/datadog-go/statsd"
	metrics "github.com/rcrowley/go-metrics"
)

type DogStatsD struct {
	statsd *dogstatsd.Client
}

func NewDogStatsD(env string) (*DogStatsD, error) {
	// 127.0.0.1:8125 is the URI for dogstastd process running in our servers
	c, err := dogstatsd.New("127.0.0.1:8125")
	if err != nil {
		return nil, err
	}

	// Prefix every metric with the env name
	if env != "" {
		env = env + "."
	}

	c.Namespace = env + "koding.monitoring."

	return &DogStatsD{
		statsd: c,
	}, nil
}

func (s *DogStatsD) Close() error {
	if s.statsd == nil {
		return nil
	}

	return s.statsd.Close()
}

// Gauge measure the value of a metric at a particular time
func (s *DogStatsD) Gauge(name string, value float64, tags []string, rate float64) error {
	if s.statsd == nil {
		return nil
	}

	return s.statsd.Gauge(name, value, tags, rate)
}

// Count track how many times something happened per second
func (s *DogStatsD) Count(name string, value int64, tags []string, rate float64) error {
	if s.statsd == nil {
		return nil
	}

	return s.statsd.Count(name, value, tags, rate)
}

// Timing track how long something happened.
func (s *DogStatsD) Timing(name string, value time.Duration, tags []string, rate float64) error {
	if s.statsd == nil {
		return nil
	}

	return s.statsd.Timing(name, value, tags, rate)
}

// Histogram track the statistical distribution of a set of values
func (s *DogStatsD) Histogram(name string, value float64, tags []string, rate float64) error {
	if s.statsd == nil {
		return nil
	}

	return s.statsd.Histogram(name, value, tags, rate)
}

// Sets count the number of unique elements in a group
func (s *DogStatsD) Set(name string, value string, tags []string, rate float64) error {
	if s.statsd == nil {
		return nil
	}

	return s.statsd.Set(name, value, tags, rate)
}

func Collect(r metrics.Registry, s *DogStatsD, d time.Duration) {
	for _ = range time.Tick(d) {
		if err := sh(r, s); nil != err {
			log.Println(err)
		}
	}
}

func sh(r metrics.Registry, s *DogStatsD) error {
	r.Each(func(name string, i interface{}) {

		process := func(i int64) float64 {
			if i == 0 {
				i = 1
			}
			return float64(i)
		}

		switch metric := i.(type) {
		case metrics.Counter:
			s.Gauge(name+".gauge", process(metric.Count()), nil, 1.0)
		case metrics.Gauge:
			s.Gauge(name+".gauge", process(metric.Value()), nil, 1.0)
		case metrics.Histogram:
			h := metric.Snapshot()
			s.Gauge(name+".count.gauge", process(h.Count()), nil, 1.0)
		case metrics.Meter:
			m := metric.Snapshot()
			s.Gauge(name+".count.gauge", process(m.Count()), nil, 1.0)
		case metrics.Timer:
			t := metric.Snapshot()
			s.Gauge(name+".mean.timer", t.Mean(), nil, 1.0)
			s.Gauge(name+".max.timer", process(t.Max()), nil, 1.0)
			s.Gauge(name+".min.timer", process(t.Min()), nil, 1.0)
		}
	})
	return nil
}
