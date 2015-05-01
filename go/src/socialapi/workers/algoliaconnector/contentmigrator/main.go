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
	var messages []models.ChannelMessageList
	for b := 0; ; b++ {
		err := models.NewChannelMessage().Some(&messages, &bongo.Query{
			Pagination: bongo.Pagination{
				Limit: 100,
				Skip:  b * 100,
			}})
		if err != nil {
			return err
		}

		for _, message := range messages {
			listing := models.NewChannelMessageList()

			if err := listing.One(&bongo.Query{
				Selector: map[string]interface{}{"message_id": message.Id}}); err != nil {
				return err
			}

			r.Log.Info(fmt.Sprintf("currently migrating ChannelMessageList: '%v'", listing.Id))

			if err := handler.MessageListSaved(listing); err != nil {
				return err
			}
		}

		if len(messages) < 100 {
			return nil
		}
	}
}
