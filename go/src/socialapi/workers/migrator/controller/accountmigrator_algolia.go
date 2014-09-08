package controller

import (
	"github.com/algolia/algoliasearch-client-go/algoliasearch"

	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/helpers"
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/algoliaconnector/algoliaconnector"
)

func (mwc *Controller) migrateAllAccountsToAlgolia() {
	mwc.log.Notice("Account migration to Algolia started")
	successCount := 0

	s := modelhelper.Selector{
		"type":        "registered",
		"syncAlgolia": modelhelper.Selector{"$exists": false},
	}

	c := config.MustGet()

	algolia := algoliasearch.NewClient(c.Algolia.AppId, c.Algolia.ApiSecretKey)
	// create message handler
	handler := algoliaconnector.New(mwc.log, algolia, c.Algolia.IndexSuffix)

	migrateAccount := func(account interface{}) error {
		oldAccount := account.(*mongomodels.Account)
		err := handler.AccountSaved(&models.Account{
			OldId: oldAccount.Id.Hex(),
			Nick:  oldAccount.Profile.Nickname,
		})

		if err != nil {
			return err
		}

		// added for incremental algolia updates
		sel := modelhelper.Selector{"_id": oldAccount.Id}

		o := modelhelper.Selector{"$set": modelhelper.Selector{
			"syncAlgolia": MigrationCompleted,
		}}

		if err := modelhelper.UpdateAccount(sel, o); err != nil {
			return err
		}

		successCount++

		return nil
	}

	iterOptions := helpers.NewIterOptions()
	iterOptions.CollectionName = "jAccounts"
	iterOptions.F = migrateAccount
	iterOptions.Filter = s
	iterOptions.Result = &mongomodels.Account{}
	iterOptions.Limit = 10000000
	iterOptions.Skip = 0
	iterOptions.Sort = []string{"-_id"}

	helpers.Iter(modelhelper.Mongo, iterOptions)

	mwc.log.Notice("Algolia account migration completed for %d accounts", successCount)
}
