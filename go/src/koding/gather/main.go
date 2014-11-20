package main

import (
	"fmt"
	"koding/gather/metrics"
	"log"
	"strings"
	"sync"
)

var (
	metricsRegistry = &metrics.Metrics{
		Items: make([]*metrics.Metric, 0),
		Mutex: &sync.Mutex{},
	}
)

func main() {
	dfCollector := func(location int) *metrics.MultipleCmd {
		return metrics.NewMultipleCmd(
			metrics.NewSingleCmd("df", "-lh"),
			metrics.NewSingleCmd("grep", "/dev"),
			metrics.NewSingleCmd("awk", fmt.Sprintf(`{print $%d}`, location)),
		)
	}

	totalDisk := &metrics.Metric{
		Name:      "total_disk",
		Collector: dfCollector(2),
	}

	// usedDisk := &Metric{
	//   Name:      "used_disk",
	//   Collector: dfCollector(3),
	// }

	// freeDisk := &Metric{
	//   Name:      "free_disk",
	//   Collector: dfCollector(4),
	// }

	// percentUsedDisk := &Metric{
	//   Name:      "percent_used_disk",
	//   Collector: dfCollector(5),
	// }

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

	// metrics.RegisterMetric(metricsRegistry, numberOfUsers)
	// metrics.RegisterMetric(metricsRegistry, typeOfFiles)
	metrics.RegisterMetric(metricsRegistry, totalDisk)
	// metrics.RegisterMetric(metricsRegistry, usedDisk)
	// metrics.RegisterMetric(metricsRegistry, freeDisk)
	// metrics.RegisterMetric(metricsRegistry, percentUsedDisk)

	for _, metric := range metricsRegistry.Items {
		metricsRegistry.Mutex.Lock()

		out, err := metric.Collector.Run()
		if err != nil {
			log.Println(err)
			continue
		}

		fmt.Println(metric.Name, strings.TrimSpace(string(out)))

		metricsRegistry.Mutex.Unlock()

		break
	}
}
