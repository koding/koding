package controller

import (
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/helpers"
	"strconv"
)

var errAccountCount = 0

const (
	MigrationCompleted = "completed"
	MigrationFailed    = "failed"
)

func (mwc *Controller) handleAccountError(oldAccount *mongomodels.Account, err error) {
	errAccountCount++
	mwc.log.Error("Error occurred for account %s: %s", oldAccount.Id.Hex(), err)
	s := modelhelper.Selector{"_id": oldAccount.Id}
	o := modelhelper.Selector{"$set": modelhelper.Selector{"migration": MigrationFailed, "error": err.Error()}}
	if err := modelhelper.UpdateAccount(s, o); err != nil {
		mwc.log.Warning("Could not update account document: %s", err)
	}
}

func (mwc *Controller) migrateAllAccounts() {
	mwc.log.Notice("Account migration started")
	successCount := 0

	s := modelhelper.Selector{
		"type": "registered",
	}

	migrateAccount := func(account interface{}) error {
		oldAccount := account.(*mongomodels.Account)
		socialApiId, err := oldAccount.GetSocialApiId()
		if err != nil {
			mwc.handleAccountError(oldAccount, err)
			return nil
		}

		if socialApiId != 0 {
			return nil
		}

		s := modelhelper.Selector{"_id": oldAccount.Id}
		if socialApiId > 0 {
			o := modelhelper.Selector{"$set": modelhelper.Selector{
				"migration": MigrationCompleted,
			}}
			modelhelper.UpdateAccount(s, o)
			successCount++
			return nil
		}

		id, err := mwc.AccountIdByOldId(
			oldAccount.Id.Hex(),
		)
		if err != nil {
			mwc.handleAccountError(oldAccount, err)
			return nil
		}

		o := modelhelper.Selector{"$set": modelhelper.Selector{
			"socialApiId": strconv.FormatInt(id, 10),
			"migration":   MigrationCompleted,
		}}
		if err := modelhelper.UpdateAccount(s, o); err != nil {
			mwc.handleAccountError(oldAccount, err)
			return nil
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

	helpers.Iter(modelhelper.Mongo, iterOptions)

	mwc.log.Notice("Account migration completed for %d account with %d errors", successCount, errAccountCount)
}
