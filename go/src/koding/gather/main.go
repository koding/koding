package main

import (
	"fmt"
	"log"
	"strings"
	"sync"
)

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

func main() {
	dfCollector := func(location int) *MultipleCmd {
		return NewMultipleCmd(
			NewSingleCmd("df", "-lh"),
			NewSingleCmd("grep", "/dev"),
			NewSingleCmd("awk", fmt.Sprintf(`{print $%d}`, location)),
		)
	}

	totalDisk := &Metric{
		Name:      "total_disk",
		Collector: dfCollector(2),
	}

	usedDisk := &Metric{
		Name:      "used_disk",
		Collector: dfCollector(3),
	}

	freeDisk := &Metric{
		Name:      "free_disk",
		Collector: dfCollector(4),
	}

	percentUsedDisk := &Metric{
		Name:      "percent_used_disk",
		Collector: dfCollector(5),
	}

	usersFromPasswd := NewSingleCmd("cut", "-d", ":", "-f", "1", "/etc/passwd")
	grepDefaultUsers := NewSingleCmd("egrep", "-v",
		`(#|root|daemon|bin|sys|sync|games|man|lp|mail|news|uucp|proxy|www-data|backup|list|irc|gnats|nobody|libuuid|syslog|messagebus|landscape|pollinate|ubuntu|sshd|colord)`,
	)
	uniqCount := NewSingleCmd("uniq", "-c")

	numberOfUsers := &Metric{
		Name: "number_of_users",
		Collector: NewMultipleCmd(
			usersFromPasswd,
			grepDefaultUsers,
			uniqCount,
		),
	}

	typeOfFiles := &Metric{
		Name: "type_of_files",
		Collector: NewMultipleCmd(
			usersFromPasswd,
			grepDefaultUsers,
			NewSingleCmd("head", "-n", "1"),
			NewSingleCmd(
				"find", "-L", ".", "-name", `*.*`,
				"-maxdepth", "5",
				"-type", "f",
				"-name", "*.*",
				"-not", "-path", "*/.gem/*",
				"-not", "-path", "*/.npm/*",
				"-not", "-path", "*node_modules/*",
			),
			NewSingleCmd("sed", `s|.*\.||`),
			NewSingleCmd("sort"),
			uniqCount,
			NewSingleCmd("sort", "-n"),
		),
	}

	registerMetric(numberOfUsers)
	registerMetric(typeOfFiles)
	registerMetric(totalDisk)
	registerMetric(usedDisk)
	registerMetric(freeDisk)
	registerMetric(percentUsedDisk)

	for _, metric := range metrics.Items {
		metrics.Mutex.Lock()

		out, err := metric.Collector.Run()
		if err != nil {
			log.Println(err)
			continue
		}

		fmt.Println(metric.Name, strings.TrimSpace(string(out)))

		metrics.Mutex.Unlock()

		break
	}
}
