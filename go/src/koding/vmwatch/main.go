package main

import (
	"log"
	"time"

	"github.com/robfig/cron"
)

var (
	metricsToSave  = []Metric{&Cloudwatch{"NetworkOut"}}
	tickerInterval = time.Minute * 45
)

func main() {
	c := cron.New()
	c.AddFunc("@hourly", func() {
		err := queueUsernamesForMetricGet()
		if err != nil {
			log.Fatal(err)
		}
	})

	c.AddFunc("0 5-59/30 * * * *", func() {
		err := getAndSaveQueueMachineMetrics()
		if err != nil {
			log.Fatal(err)
		}
	})

	go func() {
		ticker := time.NewTicker(tickerInterval)

		for _ = range ticker.C {
			err := stopVmsOverLimit()
			if err != nil {
				log.Fatal(err)
			}
		}
	}()
}
