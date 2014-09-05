package controller

import (
	"github.com/algolia/algoliasearch-client-go/algoliasearch"

	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/helpers"
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/algoliaconnector/algoliaconnector"
	"socialapi/workers/helper"
)

func (mwc *Controller) migrateAllAccountsToAlgolia() {
	mwc.log.Notice("Account migration to Algolia started")
	successCount := 0

	s := modelhelper.Selector{
		"type": "registered",
	}

	c := config.MustGet()

	algolia := algoliasearch.NewClient(c.Algolia.AppId, c.Algolia.ApiSecretKey)
	log := helper.CreateLogger(
		"Algolia account migrator",
		false,
	)
	// create message handler
	handler := algoliaconnector.New(log, algolia, c.Algolia.IndexSuffix)

	migrateAccount := func(account interface{}) error {
		oldAccount := account.(*mongomodels.Account)

		return handler.AccountSaved(&models.Account{
			OldId: oldAccount.Id.Hex(),
			Nick:  oldAccount.Profile.Nickname,
		})
	}

	iterOptions := helpers.NewIterOptions()
	iterOptions.CollectionName = "jAccounts"
	iterOptions.F = migrateAccount
	iterOptions.Filter = s
	iterOptions.Result = &mongomodels.Account{}
	iterOptions.Limit = 10000000
	iterOptions.Skip = 0

	helpers.Iter(modelhelper.Mongo, iterOptions)

	mwc.log.Notice("Account migration completed for %d account with %d errors", successCount, errAccountCount)
}
