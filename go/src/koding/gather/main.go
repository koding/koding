package main

import (
	"flag"
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

	version = flag.Int("version", 0, "version number to be stored")
)

func main() {
	flag.Parse()

	if *version == 0 {
		log.Fatal("Please pass a version (non 0 value).")
	}

	registerMetric(scripts.NumUsers)
	registerMetric(scripts.UsersShell)

	registerMetric(scripts.NumGitRepos)
	registerMetric(scripts.GitRemotes)

	registerMetric(scripts.TotalDisk)
	registerMetric(scripts.UsedDisk)
	registerMetric(scripts.FreeDisk)
	registerMetric(scripts.PerUsedDisk)

	registerMetric(scripts.NumBashConfigLines)
	registerMetric(scripts.NumZshConfigLines)
	registerMetric(scripts.NumFishConfigLines)

	registerMetric(scripts.MongoInstalled)
	registerMetric(scripts.MysqlInstalled)
	registerMetric(scripts.PsqlInstalled)
	registerMetric(scripts.SqliteInstalled)

	// registerMetric(scripts.FileTypes)

	exporter = NewEsExporter(ES_DOMAIN, ES_PORT)

	for _, metric := range metricsRegistry.Items {
		result, err := metric.Run()
		if err != nil {
			log.Println(err)
			continue
		}

		fmt.Println(metric.Name, result)

		result["version"] = *version

		err = exporter.Send(metric.Name, result)
		if err != nil {
			log.Fatal(metric.Name, err)
		}
	}
}

func registerMetric(metric *metrics.Metric) {
	metrics.RegisterMetric(metricsRegistry, metric)
}
