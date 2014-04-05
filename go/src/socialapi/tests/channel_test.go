package main

import (
	"fmt"
	"socialapi/models"
	"testing"
	"labix.org/v2/mgo/bson"

	. "github.com/smartystreets/goconvey/convey"
)

var AccountOldId = bson.NewObjectId()

func TestChannelCreation(t *testing.T) {
	Convey("while  testing channel", t, func() {
		Convey("First Create User", func() {

			Convey("we should be able to create it", func() {

			})

			Convey("we should be able to update it", nil)

			Convey("owner should be able to add new participants into it", nil)

			Convey("normal user shouldnt be able to add new participants from it", nil)

			Convey("owner should be able to remove new participants into it", nil)

			Convey("normal user shouldnt be able to remove new participants from it", nil)
		})
	})
}

func TestPinnedActivityChannel(t *testing.T) {
	Convey("while  testing pinned activity channel", t, func() {
		Convey("First Create User", func() {

			account := models.NewAccount()
			account.OldId = AccountOldId.Hex()
			account, err := createAccount(account)
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)
			So(account.Id, ShouldNotEqual, 0)

			nonOwnerAccount := models.NewAccount()
			nonOwnerAccount.OldId = AccountOldId.Hex()
			nonOwnerAccount, err = createAccount(nonOwnerAccount)
			So(err, ShouldBeNil)
			So(nonOwnerAccount, ShouldNotBeNil)

			Convey("requester should have one", func() {
				account := account
				channel, err := fetchPinnedActivityChannel(account)
				So(err, ShouldBeNil)
				So(channel, ShouldNotBeNil)
				So(channel.Id, ShouldNotEqual, 0)
				So(channel.TypeConstant, ShouldEqual, models.Channel_TYPE_PINNED_ACTIVITY)
				So(channel.CreatorId, ShouldEqual, account.Id)
			})

			Convey("owner should be able to update it", nil)

			Convey("non-owner should not be able to update it", func() {

			})

			Convey("owner should not be able to add new participants into it", func() {
				channel, err := fetchPinnedActivityChannel(account)
				So(err, ShouldBeNil)
				So(channel, ShouldNotBeNil)
				channelParticipant, err := addChannelParticipant(channel.Id, nonOwnerAccount.Id)
				// there should be an err
				So(err, ShouldNotBeNil)
				// channel should be nil
				So(channelParticipant, ShouldBeNil)
			})

			Convey("normal user shouldnt be able to add new participants to it", nil)

			Convey("owner should  not be able to remove participant from it", nil)

			Convey("normal user shouldnt be able to remove participants from it", nil)

		})
	})
}

func fetchPinnedActivityChannel(a *models.Account) (*models.Channel, error) {
	url := fmt.Sprintf("/activity/pin/channel?accountId=%d", a.Id)
	cm := models.NewChannel()
	cmI, err := sendModel("GET", url, cm)
	if err != nil {
		return nil, err
	}
	return cmI.(*models.Channel), nil
}

func createAccount(a *models.Account) (*models.Account, error) {
	acc, err := sendModel("POST", "/account", a)
	if err != nil {
		return nil, err
	}

	return acc.(*models.Account), nil
}
