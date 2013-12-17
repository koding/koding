package main

import (
	"github.com/sent-hil/rollbar"
	"log"
)

func init() {
	registerAnalytic(numberOfCouldntFetchFiles)
	registerAnalytic(numberOfTimeoutReachedForKiteRequest)
}

var rollbarClient = rollbar.NewClient("089bd80bbfc2450dbe7b4ea2a897a181")

func numberOfCouldntFetchFiles() (string, int) {
	var itemsService = rollbar.ItemsService{C: rollbarClient}

	var identifier = "Couldn't fetch files"
	var id = "272174924"

	var item, err = itemsService.GetItem(id)
	if err != nil {
		panic(err)
	}

	log.Println("item", item)

	return identifier, item.TotalOccurrences
}

func numberOfTimeoutReachedForKiteRequest() (string, int) {
	var itemsService = rollbar.ItemsService{C: rollbarClient}

	var identifier = "Timeout reached for kite request"
	var id = "271964933"

	var item, err = itemsService.GetItem(id)
	if err != nil {
		panic(err)
	}

	log.Println("item", item)

	return identifier, item.TotalOccurrences
}
