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

			Convey("we should be able to create it", nil)

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

			Convey("non-owner should not be able to update it", nil)

			Convey("owner should not be able to add new participants into it", func() {
				channel, err := fetchPinnedActivityChannel(account)
				So(err, ShouldBeNil)
				So(channel, ShouldNotBeNil)
				channelParticipant, err := addChannelParticipant(channel.Id, account.Id, nonOwnerAccount.Id)
				// there should be an err
				So(err, ShouldNotBeNil)
				// channel should be nil
				So(channelParticipant, ShouldBeNil)
			})

			Convey("normal user shouldnt be able to add new participants to it", func() {
				channel, err := fetchPinnedActivityChannel(account)
				So(err, ShouldBeNil)
				So(channel, ShouldNotBeNil)
				channelParticipant, err := addChannelParticipant(channel.Id, nonOwnerAccount.Id, nonOwnerAccount.Id)
				// there should be an err
				So(err, ShouldNotBeNil)
				// channel should be nil
				So(channelParticipant, ShouldBeNil)
			})

			Convey("owner should  not be able to remove participant from it", func() {
				channel, err := fetchPinnedActivityChannel(account)
				So(err, ShouldBeNil)
				So(channel, ShouldNotBeNil)
				channelParticipant, err := deleteChannelParticipant(channel.Id, account.Id, nonOwnerAccount.Id)
				// there should be an err
				So(err, ShouldNotBeNil)
				// channel should be nil
				So(channelParticipant, ShouldBeNil)
			})

			Convey("normal user shouldnt be able to remove participants from it", func() {
				channel, err := fetchPinnedActivityChannel(account)
				So(err, ShouldBeNil)
				So(channel, ShouldNotBeNil)
				channelParticipant, err := deleteChannelParticipant(channel.Id, nonOwnerAccount.Id, nonOwnerAccount.Id)
				// there should be an err
				So(err, ShouldNotBeNil)
				// channel should be nil
				So(channelParticipant, ShouldBeNil)
			})

			Convey("owner should be able to add new message into it", func() {
				// use account id as message id
				_, err := addPinnedMessage(account.Id, account.Id, "koding")
				// there should be an err
				So(err, ShouldBeNil)
			})

			Convey("owner should  be able to remove message from it", func() {
				// use account id as message id
				_, err := removePinnedMessage(account.Id, account.Id, "koding")
				So(err, ShouldBeNil)
			})

			Convey("owner should be able to list messages", func() {
				channel, err := fetchPinnedActivityChannel(account)
				So(err, ShouldBeNil)
				So(channel, ShouldNotBeNil)
				history, err := getHistory(channel.Id, account.Id)
				// there should be an err
				So(err, ShouldBeNil)
				// channel should be nil
				So(history, ShouldNotBeNil)

				So(history, ShouldNotBeNil)

			})

			Convey("Messages shouldnt be added as pinned twice ", func() {
				// use account id as message id
				_, err := addPinnedMessage(account.Id, account.Id, "koding")
				// there should be an err
				So(err, ShouldBeNil)
				// use account id as message id
				_, err = addPinnedMessage(account.Id, account.Id, "koding")
				// there should be an err
				So(err, ShouldNotBeNil)
			})

			Convey("Non-exist message should not be added as pinned ", nil)

		})
	})
}

func listPinnedMessages(accountId int64, groupName string) (*models.HistoryResponse, error) {
	url := fmt.Sprintf("/activity/pin/list?accountId=%d&groupName=%s", accountId, groupName)
	history, err := sendModel("GET", url, models.NewHistoryResponse())
	if err != nil {
		return nil, err
	}
	return history.(*models.HistoryResponse), nil
}

func addPinnedMessage(accountId, messageId int64, groupName string) (*models.PinRequest, error) {
	req := models.NewPinRequest()
	req.AccountId = accountId
	req.MessageId = messageId
	req.GroupName = groupName

	url := "/activity/pin/add"
	cmI, err := sendModel("POST", url, req)
	if err != nil {
		return nil, err
	}
	return cmI.(*models.PinRequest), nil

}

func removePinnedMessage(accountId, messageId int64, groupName string) (*models.PinRequest, error) {
	req := models.NewPinRequest()
	req.AccountId = accountId
	req.MessageId = messageId
	req.GroupName = groupName

	url := "/activity/pin/remove"
	cmI, err := sendModel("POST", url, req)
	if err != nil {
		return nil, err
	}
	return cmI.(*models.PinRequest), nil

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
