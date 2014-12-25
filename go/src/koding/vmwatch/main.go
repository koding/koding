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

	// queue to get metrics at top of every hour
	c.AddFunc("@hourly", func() {
		err := queueUsernamesForMetricGet()
		if err != nil {
			log.Fatal(err)
		}
	})

	// get and save metrics at 5th and 35th minutes of every hour
	c.AddFunc("0 5-59/30 * * * *", func() {
		err := getAndSaveQueueMachineMetrics()
		if err != nil {
			log.Fatal(err)
		}
	})

	// stop machines overlimit at 10th and 40th minutes of every hour
	c.AddFunc("0 10-59/35 * * * *", func() {
		err := stopVmsOverLimit()
		if err != nil {
			log.Fatal(err)
		}
	})
}
