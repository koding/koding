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

	exporter Exporter
)

func main() {
	registerMetric(scripts.TotalDisk)
	registerMetric(scripts.UsedDisk)
	registerMetric(scripts.FreeDisk)
	registerMetric(scripts.PerUsedDisk)
	// registerMetric(scripts.NumUsers)
	// registerMetric(scripts.FileTypes)

	exporter = NewEsExporter("fcd741dd72ad8998000.qbox.io", "443")

	for _, metric := range metricsRegistry.Items {
		out, err := metric.Collector.Run()
		if err != nil {
			log.Println(err)
			continue
		}

		var result = strings.TrimSpace(string(out))

		fmt.Println(metric.Name, result)

		err = exporter.Create(metric.Name, []byte(fmt.Sprintf(`{"data":"%s"}`, result)))
		if err != nil {
			log.Fatal(err)
		}
	}
}

func registerMetric(metric *metrics.Metric) {
	metrics.RegisterMetric(metricsRegistry, metric)
}
