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

	PaidPlanMultiplier float64 = 2
	LimitMultiplier    float64 = 4

	BlockDuration = time.Hour * 24 * 365

	// defines list of metrics, all queue/fetch/save operations
	// must iterate this list and not use metric directly
	metricsToSave = []Metric{
		&Cloudwatch{Name: NetworkOut, Limits: Limits{
			StopLimitKey:  NetworkOutLimit,
			BlockLimitKey: NetworkOutLimit * LimitMultiplier,
		}},
	}
)

func main() {
	initialize()

	startTime := time.Now()
	defer func() {
		Log.Info("Exited...ran for: %s", time.Since(startTime))
	}()

	c := cron.New()

	// queue to get metrics every 4 mins; uses redis set to queue
	// the usernames so multiple workers don't queue the same usernames.
	// this needs to be done at top of hour, so running multiple workers
	// won't cause a problem.
	c.AddFunc("0 0-59/4 * * * *", func() {
		err := queueUsernamesForMetricGet()
		if err != nil {
			Log.Fatal(err.Error())
		}
	})

	// get and save metrics every 4 mins, starting at 1st minute
	// queue overlimit users for either stop or block depending
	// on their usage
	c.AddFunc("0 1-59/4 * * * *", func() {
		err := getAndSaveQueueMachineMetrics()
		if err != nil {
			Log.Fatal(err.Error())
		}

		err = queueOverlimitUsers()
		if err != nil {
			Log.Fatal(err.Error())
		}

		err = dealWithMachinesOverLimit()
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

	err := http.ListenAndServe(":"+port, nil)
	if err != nil {
		Log.Fatal(err.Error())
	}
}
