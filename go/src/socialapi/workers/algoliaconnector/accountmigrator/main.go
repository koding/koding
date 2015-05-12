package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"

	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/algoliaconnector/algoliaconnector"

	"github.com/algolia/algoliasearch-client-go/algoliasearch"
	"github.com/koding/bongo"
	"github.com/koding/runner"
)

var Name = "AlgoliaAccountMigrator"

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}
	defer r.Close()

	// init mongo connection
	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	algolia := algoliasearch.NewClient(
		appConfig.Algolia.AppId,
		appConfig.Algolia.ApiSecretKey,
	)

	// create message handler
	handler := algoliaconnector.New(r.Log, algolia, appConfig.Algolia.IndexSuffix)

	for b := 0; ; b++ {
		var accounts []models.Account

		err := (&models.Account{}).Some(&accounts, &bongo.Query{
			Pagination: *bongo.NewPagination(100, b*100),
		})
		if err != nil {
			r.Log.Error(err.Error())
			continue
		}

		for _, account := range accounts {
			r.Log.Info(fmt.Sprintf("currently migrating: '%v'", account.Nick))
			if err := handler.AccountUpdated(&account); err != nil {
				r.Log.Error(err.Error())
				continue
			}
		}

		if len(accounts) < 100 {
			break
		}
	}
}
