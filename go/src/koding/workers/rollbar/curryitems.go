package main

import (
	"github.com/sent-hil/rollbar"
	"koding/db/mongodb"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
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
				log.Error("Getting instance for item %v: %v", item.Id, err)
			}

			// Normalize data according to our needs.
			var codeVersionInt, _ = strconv.Atoi(instancesResp.Result.Data.Client.Javascript.CodeVersion)
			saveableItem.CodeVersion = codeVersionInt
			saveableItem.CreatedAt = time.Unix(i.FirstOccurrenceTimestamp, 0)

			//log.Debug("%v", saveableItem)

			err = saveOrUpdateItem(saveableItem)
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

func saveOrUpdateItem(s *SaveableItem) error {
	var foundItem SaveableItem
	var findQuery = func(c *mgo.Collection) error {
		return c.Find(bson.M{"itemId": s.ItemId}).One(&foundItem)
	}

	var secondErr error
	var err = mongodb.Run("rollbarItems", findQuery)
	if err != nil {
		secondErr = saveItem(s)
	} else {
		secondErr = updateItem(s)
	}

	return secondErr
}

func saveItem(s *SaveableItem) error {
	log.Debug("Item with id: %v not found, saving", s.ItemId)

	var query = func(c *mgo.Collection) error {
		return c.Insert(s)
	}

	var err = mongodb.Run("rollbarItems", query)

	return err
}

func updateItem(s *SaveableItem) error {
	log.Debug("Item with id: %v found, updating", s.ItemId)

	var query = func(c *mgo.Collection) error {
		var findQuery = bson.M{"itemId": s.ItemId}
		var updateQuery = bson.M{"$set": bson.M{"totalOccurrences": s.TotalOccurrences}}

		return c.Update(findQuery, updateQuery)
	}

	var err = mongodb.Run("rollbarItems", query)

	return err
}
