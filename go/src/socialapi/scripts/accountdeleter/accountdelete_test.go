package main

import (
	"socialapi/models"
	"socialapi/rest"
	"socialapi/workers/common/tests"
	"testing"

	"gopkg.in/mgo.v2/bson"

	"github.com/koding/runner"
	. "github.com/smartystreets/goconvey/convey"
)

var AccountOldId = bson.NewObjectId()

func TestAccountCreation(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("while  creating account", t, func() {
			Convey("First Create User", func() {
				Convey("Should not error if you pass old id", func() {
					account := models.NewAccount()
					account.OldId = AccountOldId.Hex()
					account, err := rest.CreateAccount(account)
					So(err, ShouldBeNil)
					So(account, ShouldNotBeNil)
					Convey("User should be in postgre when fetch from postgre", func() {
						accounts, err := models.FetchAccountsWithBongoOffset(100, 0)
						So(err, ShouldBeNil)
						So(accounts, ShouldNotBeNil)
						Convey("Created account should be in account list", func() {
							var doesExist bool
							for _, ac := range accounts {
								if ac.OldId == account.OldId {
									doesExist = true
								}
							}
							So(doesExist, ShouldBeTrue)
						})
					})
					Convey("User should not be in postgre if doesn't exist in mongo", func() {
						err := account.DeleteIfNotInMongo()
						So(err, ShouldBeNil)
						Convey("Created account should not be in account list after checking mongodb", func() {
							accounts, err := models.FetchAccountsWithBongoOffset(100, 0)
							So(err, ShouldBeNil)

							var doesExist bool
							for _, ac := range accounts {
								if ac.OldId == account.OldId {
									doesExist = true
								}
							}
							So(doesExist, ShouldBeFalse)
						})
					})
					Convey("Users creation should be succussfully", func() {
						err := accountCreatorWithCount(10)
						So(err, ShouldBeNil)
						Convey("Users should be in postgre with many accounts", func() {
							accounts, err := models.FetchAccountsWithBongoOffset(100, 0)
							So(err, ShouldBeNil)
							So(len(accounts), ShouldBeGreaterThan, 9)
						})
						Convey("Users should not be in postgre after deleting accounts", func() {
							err := models.DeleteDiffedDBAccounts()
							So(err, ShouldBeNil)
						})
					})
				})
			})
		})
	})
}

func accountCreatorWithCount(count int) error {
	for i := 0; i < count; i++ {
		account := models.NewAccount()
		account.OldId = bson.NewObjectId().Hex()
		account, err := rest.CreateAccount(account)
		if err != nil {
			return err
		}
	}
	return nil
}
