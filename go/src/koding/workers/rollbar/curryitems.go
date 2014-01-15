package main

import (
	"github.com/sent-hil/rollbar"
	"koding/db/mongodb"
	"labix.org/v2/mgo"
	"strconv"
	"sync"
	"time"
)

var rollbarClient = rollbar.NewClient("9fb7f29ad0dc478ba4cfd6bbfbecbd47")

type SaveableItem struct {
	ItemId           int       `bson:"itemId"`
	ProjectId        int       `bson:"projectId"`
	CodeVersion      int       `bson:"codeVersion"`
	CreatedAt        time.Time `bson:"createdAt"`
	TotalOccurrences int       `bson:"totalOccurrences"`
	Title            string
	Level            string
	Status           string
}

func curryItemsFromRollbarToDb() error {
	var wg sync.WaitGroup

	var latestItems, err = getLatestItemsFromRollbar()
	if err != nil {
		return err
	}

	log.Debug("Got %v latest items from Rollbar", len(latestItems))

	for _, i := range latestItems {
		wg.Add(1)

		var saveableItem = &SaveableItem{
			ItemId:           i.Id,
			ProjectId:        i.ProjectId,
			Title:            i.Title,
			TotalOccurrences: i.TotalOccurrences,
			Status:           i.Status,
			Level:            i.Level,
		}

		go func(item rollbar.Item) {
			defer wg.Done()

			// Get code version from first occurence of incident.
			var instancesResp, err = getInstanceForItem(item.FirstOccurrenceId)
			if err != nil {
				log.Error(err.Error())
			}

			// Normalize data according to our needs.
			var codeVersionInt, _ = strconv.Atoi(instancesResp.Result.Data.Client.Javascript.CodeVersion)
			saveableItem.CodeVersion = codeVersionInt
			saveableItem.CreatedAt = time.Unix(i.FirstOccurrenceTimestamp, 0)

			//log.Debug("%v", saveableItem)

			err = saveItem(saveableItem)
			if err != nil {
				log.Error(err.Error())
			}

		}(i)
	}

	wg.Wait()

	log.Debug("Saved %v items to Rollbar", len(latestItems))

	return nil
}

func getLatestItemsFromRollbar() ([]rollbar.Item, error) {
	var itemsService = rollbar.ItemsService{rollbarClient}
	var itemsResp, err = itemsService.All()

	return itemsResp.Result.Items, err
}

func getInstanceForItem(itemId int) (*rollbar.SingleInstanceResponse, error) {
	var instancesService = rollbar.InstanceService{rollbarClient}
	var instancesResp, err = instancesService.Get(itemId)

	return instancesResp, err
}

func saveItem(s *SaveableItem) error {
	var insertQuery = func(c *mgo.Collection) error {
		return c.Insert(s)
	}

	var err = mongodb.Run("rollbarItems", insertQuery)

	return err
}
