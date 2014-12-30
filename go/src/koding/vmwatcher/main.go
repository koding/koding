// vmwatcher is an enforcer that gets various metrics (currently only
// `NetworkOut` from cloudwatch api is implemented) and stops the vm if it's
// over the limit for that metric; in addition it also exposes a http endpoint
// for various workers (kloud for now) to check if user is overlimit before
// taking an action (ie starting a vm).
//
// The goal of this worker is to prevent users from abusing the system, not be
// a secondary storage for metrics data.
package main

import (
	"encoding/json"
	"io"
	"log"
	"net/http"

	"github.com/robfig/cron"
)

var (
	WorkerName    = "vmwatcher"
	WorkerVersion = "0.0.1"

	NetworkOut             = "NetworkOut"
	NetworkOutLimt float64 = 7

	// defines list of metrics, all queue/fetch/save operations
	// must iterate this list and not use metric directly
	metricsToSave = []Metric{
		&Cloudwatch{Name: NetworkOut, Limit: NetworkOutLimt},
	}
)

func main() {
	c := cron.New()

	// queue to get metrics at top of every hour; uses redis set to queue
	// the usernames so multiple workers don't queue the same usernames.
	// this needs to be done at top of hour, so running multiple workers
	// won't cause a problem.
	c.AddFunc("@hourly", func() {
		err := queueUsernamesForMetricGet()
		if err != nil {
			log.Fatal(err)
		}
	})

	// get and save metrics at 15th minute of every hour
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

	http.HandleFunc("/", checkerHttp)
	http.ListenAndServe(":"+port, nil)
}

func checkerHttp(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	username := r.URL.Query().Get("account_id")
	if username == "" {
		io.WriteString(w, `{"error":"account_id is required"}`)
		return
	}

	response := checker(username)

	js, err := json.Marshal(response)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Write(js)
}
