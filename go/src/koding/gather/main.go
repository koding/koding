package main

import (
	"fmt"
	"koding/gather/metrics"
	"koding/gather/scripts"
	"log"
	"sync"
)

var (
	metricsRegistry = &metrics.Registry{
		Items: make([]*metrics.Metric, 0),
		Mutex: &sync.Mutex{},
	}

	exporter Exporter
)

const (
	ES_DOMAIN = "fcd741dd72ad8998000.qbox.io"
	ES_PORT   = "443"
)

func main() {
	registerMetric(scripts.UsersShell)
	registerMetric(scripts.GitRemotes)
	registerMetric(scripts.TotalDisk)
	registerMetric(scripts.UsedDisk)
	registerMetric(scripts.FreeDisk)
	registerMetric(scripts.PerUsedDisk)
	registerMetric(scripts.NumUsers)
	// registerMetric(scripts.FileTypes)

	exporter = NewEsExporter(ES_DOMAIN, ES_PORT)

	for _, metric := range metricsRegistry.Items {
		result, err := metric.Run()
		if err != nil {
			log.Println(err)
			continue
		}

		fmt.Println(metric.Name, result)

		err = exporter.Send(metric.Name, result)
		if err != nil {
			log.Fatal(metric.Name, err)
		}
	}
}

func registerMetric(metric *metrics.Metric) {
	metrics.RegisterMetric(metricsRegistry, metric)
}
