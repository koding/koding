// vmwatcher is an enforcer that gets various metrics and stops the vm if it's
// over the limit for that metric; in addition it also exposes a http endpoint
// for various workers to check if user is overlimit before taking an action
// (ie starting a vm).
//
// The goal of this worker is to prevent users from abusing the system, not be
// a secondary storage for metrics data.
package main

import (
	"koding/artifact"
	"net/http"
	"time"

	"github.com/robfig/cron"
)

var (
	WorkerName    = "vmwatcher"
	WorkerVersion = "0.0.1"

	NetworkOut              = "NetworkOut"
	NetworkOutLimit float64 = 7 * 1024 // 7GB/week

	// defines list of metrics, all queue/fetch/save operations
	// must iterate this list and not use metric directly
	metricsToSave = []Metric{
		&Cloudwatch{Name: NetworkOut, Limit: NetworkOutLimit},
	}
)

func main() {
	initialize()

	startTime := time.Now()
	defer func() {
		Log.Info("Exited...ran for: %s", time.Since(startTime))
	}()

	c := cron.New()

	// queue to get metrics at top of every hour; uses redis set to queue
	// the usernames so multiple workers don't queue the same usernames.
	// this needs to be done at top of hour, so running multiple workers
	// won't cause a problem.
	c.AddFunc("0 0 * * * *", func() {
		err := queueUsernamesForMetricGet()
		if err != nil {
			Log.Fatal(err.Error())
		}
	})

	// get and save metrics at 15th minute of every hour
	c.AddFunc("0 15 * * * *", func() {
		err := getAndSaveQueueMachineMetrics()
		if err != nil {
			Log.Fatal(err.Error())
		}
	})

	// stop machines overlimit at 20th & 40th of every hour; there's no reason
	// for running it at a certain point except not having overlap in logs
	c.AddFunc("0 20,40 * * * *", func() {
		err := stopMachinesOverLimit()
		if err != nil {
			Log.Fatal(err.Error())
		}
	})

	c.Start()

	// expose api for workers like kloud to check if users is over limit
	http.HandleFunc("/", checkerHTTP)

	http.HandleFunc("/version", artifact.VersionHandler())
	http.HandleFunc("/healthCheck", artifact.HealthCheckHandler(WorkerName))

	Log.Info("Listening on port: %s", port)

	http.ListenAndServe(":"+port, nil)

}
