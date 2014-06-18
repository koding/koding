package controller

import (
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/helpers"
	"socialapi/models"
	"strconv"
)

func (mwc *Controller) migrateAllAccounts() error {
	errCount := 0
	successCount := 0

	s := modelhelper.Selector{
		"socialApiId": modelhelper.Selector{"$exists": false},
	}

	migrateAccount := func(account interface{}) error {
		oldAccount := account.(*mongomodels.Account)
		if oldAccount.SocialApiId != 0 {
			return nil
		}

		id, err := models.AccountIdByOldId(
			oldAccount.Id.Hex(),
			oldAccount.Profile.Nickname,
		)
		if err != nil {
			errCount++
			mwc.log.Error("Error occurred for account %s: %s", oldAccount.Id.Hex())
			return nil
		}

		s := modelhelper.Selector{"_id": oldAccount.Id}
		o := modelhelper.Selector{"$set": modelhelper.Selector{"socialApiId": strconv.FormatInt(id, 10)}}
		if err := modelhelper.UpdateAccount(s, o); err != nil {
			mwc.log.Warning("Could not update account document: %s", err)
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

	mwc.log.Notice("Account migration completed for %d account with %d errors", successCount, errCount)

	return nil
}
