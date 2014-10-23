package stats

import "github.com/ooyala/go-dogstatsd"

type DogStatsD struct {
	statsd *dogstatsd.Client
}

func NewDogStatsD(env string) *DogStatsD {
	// 127.0.0.1:8125 is the URI for dogstastd process running in our servers
	c, err := dogstatsd.New("127.0.0.1:8125")
	if err != nil {
		return nil, err
	}

	// Prefix every metric with the env name
	if env != "" {
		env = env + "."
	}

	c.Namespace = env + "koding."

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
