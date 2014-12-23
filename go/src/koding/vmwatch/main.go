package main

import (
	"log"
	"time"
)

var (
	metricsToSave  = []Metric{&Cloudwatch{"NetworkOut"}}
	tickerInterval = time.Minute * 45
)

func main() {
	go func() {
		ticker := time.NewTicker(tickerInterval)

		for _ = range ticker.C {
			err := getAndSaveRunningVmsMetrics()
			if err != nil {
				log.Fatal(err)
			}
		}
	}()

	go func() {
		ticker := time.NewTicker(tickerInterval)

		for _ = range ticker.C {
			err := stopRunningVmsOverLimit()
			if err != nil {
				log.Fatal(err)
			}
		}
	}()
}
