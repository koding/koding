package metrics

import "sync"

type Registry struct {
	Items []*Metric
	Mutex *sync.Mutex
}

type Metric struct {
	Name      string
	Collector Collector
}

func RegisterMetric(registry *Registry, metric *Metric) {
	registry.Mutex.Lock()
	registry.Items = append(registry.Items, metric)
	registry.Mutex.Unlock()
}
