package controller

import (
	"fmt"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"socialapi/models"
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

		a := models.NewAccount()
		a.OldId = oldAccount.Id.Hex()
		a.Nick = oldAccount.Profile.Nickname
		if err := a.FetchOrCreate(); err != nil {
			errCount++
			mwc.log.Error("Error occurred for account %s: %s", oldAccount.Id.Hex())
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
