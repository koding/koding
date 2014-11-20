package main

import "sync"

var (
	metrics = &Metrics{
		Items: make([]*Metric, 0),
		Mutex: &sync.Mutex{},
	}
)

type Metrics struct {
	Items []*Metric
	Mutex *sync.Mutex
}

type Metric struct {
	Name      string
	Collector Collector
}

func registerMetric(metric *Metric) {
	metrics.Mutex.Lock()
	metrics.Items = append(metrics.Items, metric)
	metrics.Mutex.Unlock()
}
