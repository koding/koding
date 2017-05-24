package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"log"
	"socialapi/config"
	"socialapi/workers/algoliaconnector/algoliaconnector"
	"time"

	"github.com/algolia/algoliasearch-client-go/algoliasearch"
	"github.com/koding/runner"
)

// Name is the name for runner
var Name = "AlgoliaIndexCleaner"

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		log.Fatal(err)
	}

	appConfig := config.MustRead(r.Conf.Path)

	algolia := algoliasearch.NewClient(appConfig.Algolia.AppId, appConfig.Algolia.ApiSecretKey)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	// create message handler
	handler := algoliaconnector.New(r.Log, algolia, appConfig.Algolia.IndexSuffix)

	indexes, err := handler.ListIndexes()
	if err != nil {
		log.Fatal(err)
	}

	for _, item := range indexes {

		t, err := time.Parse(time.RFC3339, item.UpdatedAt)
		if err != nil {
			fmt.Println("parsing time:", err)
		}

		if t.Before(GetLast30Days()) {
			if _, err := handler.InitAndDeleteIndex(item.Name); err != nil {
				fmt.Println(err)
				return
			}
		}
	}

	r.Wait()
}

func GetLast30Days() time.Time {
	year, month, day := GetTodayDate().UTC().Date()
	return time.Date(year, month, day-30, 0, 0, 0, 0, time.UTC)
}

func GetTodayDate() time.Time {
	year, month, day := time.Now().UTC().Date()
	return time.Date(year, month, day, 0, 0, 0, 0, time.UTC)
}
