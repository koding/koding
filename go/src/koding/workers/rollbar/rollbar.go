package main

import (
	"github.com/op/go-logging"
	"github.com/sent-hil/rollbar"
	"koding/db/mongodb"
	"labix.org/v2/mgo"
	//"koding/db/mongodb"
	stdlog "log"
	"os"
	"strconv"
	"sync"
	"time"
)

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

var wg sync.WaitGroup
var log = logging.MustGetLogger("rollbar")
var rollbarClient = rollbar.NewClient("9fb7f29ad0dc478ba4cfd6bbfbecbd47")

func init() {
	logging.SetFormatter(logging.MustStringFormatter("%{message}"))

	var logBackend = logging.NewLogBackend(os.Stderr, "", stdlog.LstdFlags|stdlog.Lshortfile)
	logBackend.Color = true

	logging.SetBackend(logBackend)
}

func main() {

	// Get list of latest items from Rollbar.
	var itemsService = rollbar.ItemsService{rollbarClient}
	var itemsResp, err = itemsService.All()
	if err != nil {
		panic(err)
	}

	for _, i := range itemsResp.Result.Items {
		wg.Add(1)

		var saveableItem = SaveableItem{
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
			var instancesService = rollbar.InstanceService{rollbarClient}
			var instancesResp, err = instancesService.Get(item.FirstOccurrenceId)
			if err != nil {
				panic(err)
			}

			// Normalize data according to our needs.
			var codeVersionInt, _ = strconv.Atoi(instancesResp.Result.Data.Client.Javascript.CodeVersion)
			saveableItem.CodeVersion = codeVersionInt
			saveableItem.CreatedAt = time.Unix(i.FirstOccurrenceTimestamp, 0)

			log.Debug("%v", saveableItem)

			// Save required information to database.
			var insertQuery = func(c *mgo.Collection) error {
				return c.Insert(saveableItem)
			}

			err = mongodb.Run("rollbarItems", insertQuery)
			if err != nil {
				panic(err)
			}
		}(i)
	}

	wg.Wait()
}
