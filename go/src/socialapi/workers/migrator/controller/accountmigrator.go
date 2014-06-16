package controller

import (
	"fmt"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"socialapi/models"
	"strconv"
)

func (mwc *Controller) migrateAllAccounts() error {
	errCount := 0
	successCount := 0
	guestCount := 0

	s := modelhelper.Selector{
		"socialApiId": modelhelper.Selector{"$exists": false},
	}

	iter := modelhelper.GetAccountIter(s)
	defer iter.Close()
	var oldAccount mongomodels.Account
	for iter.Next(&oldAccount) {
		if oldAccount.SocialApiId != 0 {
			continue
		}

		id, err := models.AccountIdByOldId(
			oldAccount.Id.Hex(),
			oldAccount.Profile.Nickname,
		)
		if err != nil {
			errCount++
			mwc.log.Error("Error occurred for account %s: %s", oldAccount.Id.Hex())
			continue
		}

		s := modelhelper.Selector{"_id": oldAccount.Id}
		o := modelhelper.Selector{"$set": modelhelper.Selector{"socialApiId": strconv.FormatInt(id, 10)}}
		if err := modelhelper.UpdateAccount(s, o); err != nil {
			mwc.log.Warning("Could not update account document: %s", err)
			continue
		}

		successCount++
	}

	if err := iter.Err(); err != nil {
		return fmt.Errorf("%d errors occurred: %s", errCount, err)
	}

	mwc.log.Notice("Account migration completed for %d account with %d errors and %d guest accounts", successCount, errCount, guestCount)

	return nil
}
