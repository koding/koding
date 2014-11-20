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

func registerMetric(metric *metrics.Metric) {
	metrics.RegisterMetric(metricsRegistry, metric)
}

func main() {
	registerMetric(scripts.TotalDisk)
	registerMetric(scripts.UsedDisk)
	registerMetric(scripts.FreeDisk)
	registerMetric(scripts.PerUsedDisk)
	// registerMetric(scripts.NumUsers)
	// registerMetric(scripts.HomeDirFiles)

	// usersFromPasswd := NewSingleCmd("cut", "-d", ":", "-f", "1", "/etc/passwd")
	// grepDefaultUsers := NewSingleCmd("egrep", "-v",
	//   `(#|root|daemon|bin|sys|sync|games|man|lp|mail|news|uucp|proxy|www-data|backup|list|irc|gnats|nobody|libuuid|syslog|messagebus|landscape|pollinate|ubuntu|sshd|colord)`,
	// )
	// uniqCount := NewSingleCmd("uniq", "-c")

	// numberOfUsers := &Metric{
	//   Name: "number_of_users",
	//   Collector: NewMultipleCmd(
	//     usersFromPasswd,
	//     grepDefaultUsers,
	//     uniqCount,
	//   ),
	// }

	// typeOfFiles := &Metric{
	//   Name: "type_of_files",
	//   Collector: NewMultipleCmd(
	//     usersFromPasswd,
	//     grepDefaultUsers,
	//     NewSingleCmd("head", "-n", "1"),
	//     NewSingleCmd(
	//       "find", "-L", ".", "-name", `*.*`,
	//       "-maxdepth", "5",
	//       "-type", "f",
	//       "-name", "*.*",
	//       "-not", "-path", "*/.gem/*",
	//       "-not", "-path", "*/.npm/*",
	//       "-not", "-path", "*node_modules/*",
	//     ),
	//     NewSingleCmd("sed", `s|.*\.||`),
	//     NewSingleCmd("sort"),
	//     uniqCount,
	//     NewSingleCmd("sort", "-n"),
	//   ),
	// }

	for _, metric := range metricsRegistry.Items {
		metricsRegistry.Mutex.Lock()

		out, err := metric.Collector.Run()
		if err != nil {
			log.Println(err)
			continue
		}

		fmt.Println(metric.Name, strings.TrimSpace(string(out)))

		metricsRegistry.Mutex.Unlock()
	}
}
