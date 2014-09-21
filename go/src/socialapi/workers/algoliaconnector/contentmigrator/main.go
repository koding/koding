package main

import (
	"fmt"

	"socialapi/models"
	"socialapi/workers/algoliaconnector/algoliaconnector"
	"socialapi/workers/common/runner"

	"github.com/algolia/algoliasearch-client-go/algoliasearch"
	"github.com/koding/bongo"
)

var Name = "AlgoliaContentMigrator"

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}
	defer r.Close()

	algolia := algoliasearch.NewClient(
		r.Conf.Algolia.AppId,
		r.Conf.Algolia.ApiSecretKey)

	// create message handler
	handler := algoliaconnector.New(r.Log, algolia, r.Conf.Algolia.IndexSuffix)

	if err := migrateChannels(r, handler); err != nil {
		panic(err)
	}
}

func migrateChannels(r *runner.Runner, handler *algoliaconnector.Controller) error {
	var listings []models.ChannelMessageList
	for b := 0; ; b++ {
		err := models.NewChannelMessageList().Some(&listings, &bongo.Query{
			Pagination: bongo.Pagination{
				Limit: 100,
				Skip:  b * 100,
			}})
		if err != nil {
			return err
		}

		for _, listing := range listings {
			r.Log.Info(fmt.Sprintf("currently migrating ChannelMessageList: '%v'", listing.Id))
			if err := handler.MessageListSaved(&listing); err != nil {
				return err
			}
		}

		if len(listings) < 100 {
			return nil
		}
	}
}
