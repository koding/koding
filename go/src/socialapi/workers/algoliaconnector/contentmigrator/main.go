package main

import (
	"fmt"

	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/algoliaconnector/algoliaconnector"

	"github.com/algolia/algoliasearch-client-go/algoliasearch"
	"github.com/koding/bongo"
	"github.com/koding/runner"
)

var Name = "AlgoliaContentMigrator"

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

	if err := migrateChannels(r, handler); err != nil {
		panic(err)
	}
}

func migrateChannels(r *runner.Runner, handler *algoliaconnector.Controller) error {
	count := 0
	for b := 0; ; b++ {

		var messages []models.ChannelMessage

		err := models.NewChannelMessage().Some(&messages, &bongo.Query{
			Pagination: bongo.Pagination{
				Limit: 100,
				Skip:  b * 100,
			},
		})
		if err != nil {
			return err
		}

		for _, message := range messages {
			cmls, err := message.GetChannelMessageLists()
			if err != nil {
				return err
			}

			for _, cml := range cmls {
				count++
				r.Log.Info("[%d]: currently migrating channel.Id: %d message.Id: %d", count, cml.ChannelId, cml.MessageId)
				if err := handler.MessageListSaved(&cml); err != nil {
					return err
				}
			}

		}

		if len(messages) < 100 {
			return nil
		}
	}
}
