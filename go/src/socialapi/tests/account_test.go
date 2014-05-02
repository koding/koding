package main

import (
	"labix.org/v2/mgo/bson"
	"socialapi/models"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

var AccountOldId = bson.NewObjectId()
var AccountOldId2 = bson.NewObjectId()
var AccountOldId3 = bson.NewObjectId()
var AccountOldId4 = bson.NewObjectId()
var AccountOldId5 = bson.NewObjectId()

func TestAccountCreation(t *testing.T) {
	Convey("while  creating account", t, func() {
		Convey("First Create User", func() {

			Convey("Should error if you dont pass old id", func() {
				account := models.NewAccount()
				account, err := createAccount(account)
				So(err, ShouldNotBeNil)
				So(account, ShouldBeNil)
			})

			Convey("Should not error if you pass old id", func() {
				account := models.NewAccount()
				account.OldId = AccountOldId.Hex()
				account, err := createAccount(account)
				So(err, ShouldBeNil)
				So(account, ShouldNotBeNil)
			})

			Convey("Should return same id with same old id", func() {
				// first create account
				account := models.NewAccount()
				account.OldId = AccountOldId.Hex()
				firstAccount, err := createAccount(account)
				So(err, ShouldBeNil)
				So(firstAccount, ShouldNotBeNil)

				// then try to create it again
				secondAccount, err := createAccount(account)
				So(err, ShouldBeNil)
				So(secondAccount, ShouldNotBeNil)

				So(firstAccount.Id, ShouldEqual, secondAccount.Id)
			})
		})
	})
}

func createAccount(a *models.Account) (*models.Account, error) {
	acc, err := sendModel("POST", "/account", a)
	if err != nil {
		return nil, err
	}

	return acc.(*models.Account), nil
}
