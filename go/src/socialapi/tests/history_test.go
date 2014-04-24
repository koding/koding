package main

import (
	"encoding/json"
	"fmt"
	"socialapi/models"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelHistory(t *testing.T) {
	Convey("While testing history of a channel", t, func() {
		var channel *models.Channel
		var err error
		Convey("We should be able to create it(channel) first", func() {
			account := models.NewAccount()
			account.OldId = AccountOldId.Hex()
			account, err = createAccount(account)
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)

			channel, err = createChannel(account.Id)
			So(err, ShouldBeNil)
			So(channel, ShouldNotBeNil)
			Convey("While posting a new message to it", func() {
				var channelParticipant *models.ChannelParticipant
				var err error
				Convey("We should be able to create a participant first", func() {
					channelParticipant, err = createChannelParticipant(channel.Id)
					So(err, ShouldBeNil)
					So(channelParticipant, ShouldNotBeNil)

					Convey("Create posts with created participant", func() {
						channel := channel
						for i := 0; i < 10; i++ {
							post, err := createPost(channel.Id, channelParticipant.AccountId)
							So(err, ShouldBeNil)
							So(post, ShouldNotBeNil)
							So(post.Id, ShouldNotEqual, 0)
							So(post.Body, ShouldNotEqual, "")

						}
						Convey("We should be able to fetch the history", func() {
							history, err := getHistory(channel.Id, channelParticipant.Id)
							So(err, ShouldBeNil)
							So(history, ShouldNotBeNil)
							So(len(history.MessageList), ShouldEqual, 10)
						})
					})
				})
			})
		})
	})
}

func getHistory(channelId, accountId int64) (*models.HistoryResponse, error) {
	url := fmt.Sprintf("/channel/%d/history?accountId=%d", channelId, accountId)
	res, err := sendRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}

	var history models.HistoryResponse
	err = json.Unmarshal(res, &history)
	if err != nil {
		return nil, err
	}

	return &history, nil
}
