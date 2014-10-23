package metrics

import (
	"log"
	"time"

	"github.com/ooyala/go-dogstatsd"
	"github.com/rcrowley/go-metrics"
)

type Stat struct {
	statsd *dogstatsd.Client
}

func NewStat(appName string) (*Stat, error) {
	c, err := dogstatsd.New("127.0.0.1:8125")
	if err != nil {
		return nil, err
	}

	// Prefix every metric with the app name
	if appName != "" {
		appName = appName + "."
	}

	c.Namespace = "koding." + appName

	return &Stat{
		statsd: c,
	}, nil
}

func (s *Stat) Close() error {
	if s.statsd == nil {
		return nil
	}

	return s.statsd.Close()
}

// Gauge measure the value of a metric at a particular time
func (s *Stat) Gauge(name string, value float64, tags []string, rate float64) error {
	if s.statsd == nil {
		return nil
	}

	return s.statsd.Gauge(name, value, tags, rate)
}

// Count track how many times something happened per second
func (s *Stat) Count(name string, value int64, tags []string, rate float64) error {
	if s.statsd == nil {
		return nil
	}

	return s.statsd.Count(name, value, tags, rate)
}

// Histogram track the statistical distribution of a set of values
func (s *Stat) Histogram(name string, value float64, tags []string, rate float64) error {
	if s.statsd == nil {
		return nil
	}

	return s.statsd.Histogram(name, value, tags, rate)
}

// Sets count the number of unique elements in a group
func (s *Stat) Set(name string, value string, tags []string, rate float64) error {
	if s.statsd == nil {
		return nil
	}

	return s.statsd.Set(name, value, tags, rate)
}

func DogStatsD(r metrics.Registry, s *Stat, d time.Duration) {
	for {
		if err := sh(r, s); nil != err {
			log.Println(err)
		}
		time.Sleep(d)
	}
}

func sh(r metrics.Registry, s *Stat) error {
	r.Each(func(name string, i interface{}) {
		switch metric := i.(type) {
		case metrics.Counter:
			s.Gauge(name, float64(metric.Count()), nil, 1.0)
		case metrics.Gauge:
			s.Gauge(name, float64(metric.Value()), nil, 1.0)
		case metrics.GaugeFloat64:
			s.Gauge(name, float64(metric.Value()), nil, 1.0)
		case metrics.Histogram:
			h := metric.Snapshot()
			ps := h.Percentiles([]float64{0.5, 0.75, 0.95, 0.99, 0.999})
			s.Gauge(name+".count", float64(h.Count()), nil, 1.0)
			s.Gauge(name+".min", float64(h.Min()), nil, 1.0)
			s.Gauge(name+".max", float64(h.Max()), nil, 1.0)
			s.Gauge(name+".mean", float64(h.Mean()), nil, 1.0)
			s.Gauge(name+".std-dev", float64(h.StdDev()), nil, 1.0)
			s.Gauge(name+".50-percentile", float64(ps[0]), nil, 1.0)
			s.Gauge(name+".75-percentile", float64(ps[1]), nil, 1.0)
			s.Gauge(name+".95-percentile", float64(ps[2]), nil, 1.0)
			s.Gauge(name+".99-percentile", float64(ps[3]), nil, 1.0)
			s.Gauge(name+".999-percentile", float64(ps[4]), nil, 1.0)
		case metrics.Meter:
			m := metric.Snapshot()
			s.Gauge(name+".count", float64(m.Count()), nil, 1.0)
			s.Gauge(name+".one-minute", float64(m.Rate1()), nil, 1.0)
			s.Gauge(name+".five-minute", float64(m.Rate5()), nil, 1.0)
			s.Gauge(name+".fifteen-minute", float64(m.Rate15()), nil, 1.0)
			s.Gauge(name+".mean", float64(m.RateMean()), nil, 1.0)
		case metrics.Timer:
			t := metric.Snapshot()
			ps := t.Percentiles([]float64{0.5, 0.75, 0.95, 0.99, 0.999})
			s.Gauge(name+".count", float64(t.Count()), nil, 1.0)
			s.Gauge(name+".min", float64(t.Min()), nil, 1.0)
			s.Gauge(name+".max", float64(t.Max()), nil, 1.0)
			s.Gauge(name+".mean", float64(t.Mean()), nil, 1.0)
			s.Gauge(name+".std-dev", float64(t.StdDev()), nil, 1.0)
			s.Gauge(name+".50-percentile", float64(ps[0]), nil, 1.0)
			s.Gauge(name+".75-percentile", float64(ps[1]), nil, 1.0)
			s.Gauge(name+".95-percentile", float64(ps[2]), nil, 1.0)
			s.Gauge(name+".99-percentile", float64(ps[3]), nil, 1.0)
			s.Gauge(name+".999-percentile", float64(ps[4]), nil, 1.0)
			s.Gauge(name+".one-minute", float64(t.Rate1()), nil, 1.0)
			s.Gauge(name+".five-minute", float64(t.Rate5()), nil, 1.0)
			s.Gauge(name+".fifteen-minute", float64(t.Rate15()), nil, 1.0)
			s.Gauge(name+".mean-rate", float64(t.RateMean()), nil, 1.0)
		}
	})
	return nil
}
