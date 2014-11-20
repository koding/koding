package metrics

import "sync"

type Metrics struct {
	Items []*Metric
	Mutex *sync.Mutex
}

type Metric struct {
	Name      string
	Collector Collector
}

func RegisterMetric(metrics *Metrics, metric *Metric) {
	metrics.Mutex.Lock()
	metrics.Items = append(metrics.Items, metric)
	metrics.Mutex.Unlock()
}
