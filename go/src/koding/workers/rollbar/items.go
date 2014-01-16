package main

import (
	"strconv"
	"sync"
	"time"

	"koding/db/models"

	"github.com/sent-hil/rollbar"
	"labix.org/v2/mgo/bson"
)

var rollbarClient = rollbar.NewClient("9fb7f29ad0dc478ba4cfd6bbfbecbd47")

func importItemsFromRollbarToDb() error {
	var wg sync.WaitGroup

	var latestItems, err = getLatestItemsFromRollbar()
	if err != nil {
		return err
	}

	for _, i := range latestItems {
		wg.Add(1)

		var saveableItem = &models.RollbarItem{
			ItemId:            i.Id,
			ProjectId:         i.ProjectId,
			TotalOccurrences:  i.TotalOccurrences,
			FirstOccurrenceId: i.FirstOccurrenceId,
			LastOccurrenceId:  i.LastOccurrenceId,
			Title:             i.Title,
			Level:             i.Level,
			Status:            i.Status,
		}

		go func(item rollbar.Item) {
			defer wg.Done()

			// Get code version from first occurence of incident.
			var instancesResp, err = getInstanceForItem(item.FirstOccurrenceId)
			if err != nil {
				log.Error("Getting instance for item %v: %v", item.Id, err)
			}

			// Normalize data according to our needs.
			var codeVersionInt, _ = strconv.Atoi(instancesResp.Result.Data.Client.Javascript.CodeVersion)
			saveableItem.CodeVersion = codeVersionInt
			saveableItem.CreatedAt = time.Unix(i.FirstOccurrenceTimestamp, 0)

			err = saveableItem.UpsertByItemId()
			if err != nil {
				log.Error("Saving/updating item: %v", err)
			}
		}(i)
	}

	wg.Wait()

	return nil
}

func getLatestItemsFromRollbar() ([]rollbar.Item, error) {
	log.Debug("Fetching latest items from Rollbar")

	var itemsService = rollbar.ItemsService{rollbarClient}
	var itemsResp, err = itemsService.All()

	return itemsResp.Result.Items, err
}

func getInstanceForItem(itemId int) (*rollbar.SingleInstanceResponse, error) {
	log.Debug("Getting instances for item: %v from Rollbar", itemId)

	var instancesService = rollbar.InstanceService{rollbarClient}
	var instancesResp, err = instancesService.Get(itemId)

	return instancesResp, err
}
