package main

import (
	"math/rand"
	"socialapi/models"
	"socialapi/rest"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestGroupChannel(t *testing.T) {
	Convey("while testing group channel", t, func() {

		Convey("channel should be there", func() {
			account := models.NewAccount()
			account.OldId = AccountOldId.Hex()
			account, err := rest.CreateAccount(account)
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)

			channel1, err := rest.CreateChannelByGroupNameAndType(account.Id, "testgroup", models.Channel_TYPE_GROUP)
			So(err, ShouldBeNil)
			So(channel1, ShouldNotBeNil)

			channel2, err := rest.CreateChannelByGroupNameAndType(account.Id, "testgroup", models.Channel_TYPE_GROUP)
			So(err, ShouldBeNil)
			So(channel2, ShouldNotBeNil)

			So(channel1.Id, ShouldEqual, channel2.Id)
		})

		Convey("owner should be able to update it", func() {
			account := models.NewAccount()
			account.OldId = AccountOldId.Hex()
			account, err := rest.CreateAccount(account)
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)

			channel1, err := rest.CreateChannelByGroupNameAndType(account.Id, "testgroup", models.Channel_TYPE_GROUP)
			So(err, ShouldBeNil)
			So(channel1, ShouldNotBeNil)
			// fetching channel returns creator id
			_, err = rest.UpdateChannel(channel1)
			So(err, ShouldBeNil)
		})

		Convey("owner should only be able to update name and purpose of the channel", nil)

		Convey("normal user should not be able to update it", func() {
			account := models.NewAccount()
			account.OldId = AccountOldId.Hex()
			account, err := rest.CreateAccount(account)
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)

			channel1, err := rest.CreateChannelByGroupNameAndType(account.Id, "testgroup", models.Channel_TYPE_GROUP)
			So(err, ShouldBeNil)
			So(channel1, ShouldNotBeNil)

			channel1.CreatorId = rand.Int63()
			_, err = rest.UpdateChannel(channel1)
			So(err, ShouldNotBeNil)
		})

		Convey("owner cant delete it", func() {
			account := models.NewAccount()
			account.OldId = AccountOldId.Hex()
			account, err := rest.CreateAccount(account)
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)

			channel1, err := rest.CreateChannelByGroupNameAndType(account.Id, "testgroup", models.Channel_TYPE_GROUP)
			So(err, ShouldBeNil)
			So(channel1, ShouldNotBeNil)

			err = rest.DeleteChannel(account.Id, channel1.Id)
			So(err, ShouldNotBeNil)
		})

		Convey("normal user cant delete it", func() {
			account := models.NewAccount()
			account.OldId = AccountOldId.Hex()
			account, err := rest.CreateAccount(account)
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)

			channel1, err := rest.CreateChannelByGroupNameAndType(account.Id, "testgroup", models.Channel_TYPE_GROUP)
			So(err, ShouldBeNil)
			So(channel1, ShouldNotBeNil)

			err = rest.DeleteChannel(rand.Int63(), channel1.Id)
			So(err, ShouldNotBeNil)
		})

		Convey("member can post status update", nil)

		Convey("non-member can not post status update", nil)

		Convey("member can post status update", nil)

		Convey("non-member can not post status update", nil)

	})
}
