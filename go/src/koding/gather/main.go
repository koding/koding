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

func main() {
	registerMetric(scripts.TotalDisk)
	registerMetric(scripts.UsedDisk)
	registerMetric(scripts.FreeDisk)
	registerMetric(scripts.PerUsedDisk)
	registerMetric(scripts.NumUsers)
	// registerMetric(scripts.FileTypes)

	exporter = NewEsExporter("fcd741dd72ad8998000.qbox.io", "443")

	for _, metric := range metricsRegistry.Items {
		out, err := metric.Run()
		if err != nil {
			log.Println(err)
			continue
		}

		var result = string(out)

		fmt.Println(result)

		// err = exporter.Create(metric.Name, []byte(fmt.Sprintf(`{"data":"%s"}`, result)))
		// if err != nil {
		//   log.Fatal(err)
		// }
	}
}

func registerMetric(metric *metrics.Metric) {
	metrics.RegisterMetric(metricsRegistry, metric)
}
