package main

import (
	"fmt"

	"socialapi/config"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/algoliaconnector/algoliaconnector"

	"github.com/algolia/algoliasearch-client-go/algoliasearch"
	"github.com/koding/runner"
)

var Name = "AlgoliaTopicMigrator"

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}
	defer r.Close()

	appConfig := config.MustRead(r.Conf.Path)

	algolia := algoliasearch.NewClient(
		appConfig.Algolia.AppId,
		appConfig.Algolia.ApiSecretKey,
	)

	// create message handler
	handler := algoliaconnector.New(r.Log, algolia, appConfig.Algolia.IndexSuffix)
	counter := 0
	for b := 0; ; b++ {
		counter++

		topics, err := (&models.Channel{}).List(&request.Query{
			GroupName: "koding",
			Type:      "topic",
			Limit:     100,
			Skip:      b * 100,
		})
		if err != nil {
			r.Log.Error(err.Error())
			return
		}

		for _, topic := range topics {
			r.Log.Info("[%d] currently migrating: '%v'", counter, topic.Name)
			handler.ChannelCreated(&topic)
		}

		if len(topics) < 100 {
			break
		}
	}
}
