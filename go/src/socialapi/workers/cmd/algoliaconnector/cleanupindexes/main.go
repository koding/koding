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
	index, ok := indexes.(map[string]interface{})
	if !ok {
		return
	}

	items, ok := index["items"].([]interface{})
	if !ok {
		return
	}
	for _, item := range items {
		it, ok := item.(map[string]interface{})
		if !ok {
			continue
		}
		updatedAt := it["updatedAt"].(string)
		t, err := time.Parse(time.RFC3339, updatedAt)
		if err != nil {
			fmt.Println("parsing time:", err)
			return
		}

		if t.Before(GetLast60Days()) {
			if _, err := handler.InitAndDeleteIndex(it["name"].(string)); err != nil {
				fmt.Println(err)
				return
			}
		}
	}

	r.Wait()
}

func GetLast60Days() time.Time {
	year, month, day := GetTodayDate().UTC().Date()
	return time.Date(year, month, day-60, 0, 0, 0, 0, time.UTC)
}

func GetTodayDate() time.Time {
	year, month, day := time.Now().UTC().Date()
	return time.Date(year, month, day, 0, 0, 0, 0, time.UTC)
}
