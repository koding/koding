package main

import (
	"log"

	"github.com/robfig/cron"
)

var (
	metricsToSave = []Metric{&Cloudwatch{"NetworkOut"}}
)

func main() {
	c := cron.New()

	// queue to get metrics at top of every hour; uses redis set to queue
	// the usernames so multiple workers don't queue the same usernames.
	c.AddFunc("@hourly", func() {
		err := queueUsernamesForMetricGet()
		if err != nil {
			log.Fatal(err)
		}
	})

	// get and save metrics at 15th minute of every hour; the reason for
	// 15th minute, is to not queue and pop at the same time.
	c.AddFunc("0 15 * * * *", func() {
		err := getAndSaveQueueMachineMetrics()
		if err != nil {
			log.Fatal(err)
		}
	})

	// stop machines overlimit at 20th & 40th of every hour; there's no reason
	// for running it at a certain point except not having overlap in logs
	c.AddFunc("0 20,40 * * * *", func() {
		err := stopMachinesOverLimit()
		if err != nil {
			log.Fatal(err)
		}
	})

	c.Start()

	// run forever
	select {}
}
