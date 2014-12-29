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

	// get and save metrics at 5th and 35th minutes of every hour; the
	// reason for 5th minute, is to not queue and pop at the same time.
	c.AddFunc("0 15 * * * *", func() {
		err := getAndSaveQueueMachineMetrics()
		if err != nil {
			log.Fatal(err)
		}
	})

	// stop machines overlimit at 10th and 40th minutes of every hour;
	// there's no reason for running it at a certain point of the hour,
	// there's no overlap for the logs to not overlap.
	c.AddFunc("0 0,30 * * * *", func() {
		err := stopMachinesOverLimit()
		if err != nil {
			log.Fatal(err)
		}
	})

	c.Start()

	// run forever
	select {}
}
