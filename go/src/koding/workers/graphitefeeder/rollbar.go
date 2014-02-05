package main

import (
	"github.com/sent-hil/rollbar"
	"time"
)

func init() {
	registerAnalytic(numberOfCouldntFetchFiles)
	registerAnalytic(numberOfTimeoutReachedForKiteRequest)
}

var (
	rollbarClient = rollbar.NewClient("36426ed40a554ab09db7914aa1f0efe1")
)

func numberOfCouldntFetchFiles() (string, int) {
	var itemsService = rollbar.ItemsService{C: rollbarClient}

	var identifier = "Couldn't fetch files"
	var id = 274022596

	var itemResponse, err = itemsService.GetItem(id)
	if err != nil {
		panic(err)
	}

	var item = itemResponse.Result

	var name string

	name = "rollbar.errors.couldnt_fetch_files"
	PublishToGraphite(name, item.TotalOccurrences, time.Now().Unix())

	name = "rollbar.errors.couldnt_fetch_files_occurence"
	PublishToGraphite(name, 1, int64(item.LastOccurrenceTimestamp))

	return identifier, item.TotalOccurrences
}

func numberOfTimeoutReachedForKiteRequest() (string, int) {
	var itemsService = rollbar.ItemsService{C: rollbarClient}

	var identifier = "Timeout reached for kite request"
	var id = 274022560

	var itemResponse, err = itemsService.GetItem(id)
	if err != nil {
		panic(err)
	}

	var item = itemResponse.Result

	var name string

	name = "rollbar.errors.kite_request_timeout_reached"
	PublishToGraphite(name, item.TotalOccurrences, time.Now().Unix())

	name = "rollbar.errors.kite_request_timeout_reached_occurence"
	PublishToGraphite(name, 1, int64(item.LastOccurrenceTimestamp))

	return identifier, item.TotalOccurrences
}
