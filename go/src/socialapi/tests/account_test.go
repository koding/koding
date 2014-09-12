package main

import (
	"fmt"
	"math/rand"
	"socialapi/models"
	"socialapi/rest"
	"strconv"
	"testing"
	"time"

	"labix.org/v2/mgo/bson"

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
				account, err := rest.CreateAccount(account)
				So(err, ShouldNotBeNil)
				So(account, ShouldBeNil)
			})

			Convey("Should not error if you pass old id", func() {
				account := models.NewAccount()
				account.OldId = AccountOldId.Hex()
				account, err := rest.CreateAccount(account)
				So(err, ShouldBeNil)
				So(account, ShouldNotBeNil)
			})

			Convey("Should return same id with same old id", func() {
				// first create account
				account := models.NewAccount()
				account.OldId = AccountOldId.Hex()
				firstAccount, err := rest.CreateAccount(account)
				So(err, ShouldBeNil)
				So(firstAccount, ShouldNotBeNil)

				// then try to create it again
				secondAccount, err := rest.CreateAccount(account)
				So(err, ShouldBeNil)
				So(secondAccount, ShouldNotBeNil)

				So(firstAccount.Id, ShouldEqual, secondAccount.Id)
			})
		})
	})
}

func TestCheckOwnership(t *testing.T) {
	Convey("accounts can own things", t, func() {
		bob := models.NewAccount()
		bob.Nick = "bob"
		bob.OldId = bson.NewObjectId().Hex()
		bobsAccount, err := rest.CreateAccount(bob)
		So(err, ShouldBeNil)

		ted := models.NewAccount()
		ted.Nick = "ted"
		ted.OldId = bson.NewObjectId().Hex()
		tedsAccount, err := rest.CreateAccount(ted)
		So(err, ShouldBeNil)

		rand.Seed(time.Now().UnixNano())
		groupName := "testgroup" + strconv.FormatInt(rand.Int63(), 10)

		bobsGroup, err := rest.CreateChannelByGroupNameAndType(bobsAccount.Id, groupName, models.Channel_TYPE_GROUP)
		So(err, ShouldBeNil)

		bobsPost, err := rest.CreatePost(bobsGroup.Id, bobsAccount.Id)
		So(err, ShouldBeNil)

		fmt.Println(tedsAccount, bobsPost)

		Convey("it should say when an account owns a post", func() {
			isOwner, err := rest.CheckPostOwnership(bobsAccount, bobsPost)
			So(err, ShouldBeNil)
			So(isOwner, ShouldBeTrue)
		})

		Convey("it should say when an account doesn't own a post", func() {
			isOwner, err := rest.CheckPostOwnership(tedsAccount, bobsPost)
			So(err, ShouldBeNil)
			So(isOwner, ShouldBeFalse)
		})

		bobsChannel, err := rest.CreateChannel(bob.Id)
		So(err, ShouldBeNil)

		Convey("it should say when an account owns a channel", func() {
			isOwner, err := rest.CheckChannelOwnership(bobsAccount, bobsChannel)
			So(err, ShouldBeNil)
			So(isOwner, ShouldBeTrue)
		})

		Convey("it should say when an account doesn't own a channel", func() {
			isOwner, err := rest.CheckChannelOwnership(tedsAccount, bobsChannel)
			So(err, ShouldBeNil)
			So(isOwner, ShouldBeFalse)
		})
	})
}
