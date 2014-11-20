package main

import (
	"fmt"
	"koding/gather/metrics"
	"koding/gather/scripts"
	"log"
	"strings"
	"sync"
)

var (
	metricsRegistry = &metrics.Registry{
		Items: make([]*metrics.Metric, 0),
		Mutex: &sync.Mutex{},
	}
)

func main() {
	registerMetric(scripts.TotalDisk)
	registerMetric(scripts.UsedDisk)
	registerMetric(scripts.FreeDisk)
	registerMetric(scripts.PerUsedDisk)
	registerMetric(scripts.NumUsers)
	registerMetric(scripts.FileTypes)

	for _, metric := range metricsRegistry.Items {
		out, err := metric.Collector.Run()
		if err != nil {
			log.Println(err)
			continue
		}

		fmt.Println(metric.Name, strings.TrimSpace(string(out)))
	}
}

func registerMetric(metric *metrics.Metric) {
	metrics.RegisterMetric(metricsRegistry, metric)
}
