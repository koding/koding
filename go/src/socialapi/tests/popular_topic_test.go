package main

import (
	"encoding/json"
	"fmt"
	"math/rand"
	"socialapi/models"
	"strconv"
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
)

func TestPopularTopic(t *testing.T) {

	Convey("order should be preserved", t, func() {
		account := models.NewAccount()
		account.OldId = AccountOldId.Hex()
		account, err := createAccount(account)
		So(err, ShouldBeNil)
		So(account, ShouldNotBeNil)

		rand.Seed(time.Now().UnixNano())

		groupName := "testgroup" + strconv.FormatInt(rand.Int63(), 10)
		channel1, err := createChannelByGroupNameAndType(account.Id, groupName, models.Channel_TYPE_GROUP)
		So(err, ShouldBeNil)
		So(channel1, ShouldNotBeNil)

		for i := 0; i < 5; i++ {
			post, err := createPostWithBody(channel1.Id, account.Id, "create a message #5times")
			So(err, ShouldBeNil)
			So(post, ShouldNotBeNil)
		}

		for i := 0; i < 4; i++ {
			post, err := createPostWithBody(channel1.Id, account.Id, "create a message #4times")
			So(err, ShouldBeNil)
			So(post, ShouldNotBeNil)
		}

		for i := 0; i < 3; i++ {
			post, err := createPostWithBody(channel1.Id, account.Id, "create a message #3times")
			So(err, ShouldBeNil)
			So(post, ShouldNotBeNil)
		}

		//required for backgroud task to be finished
		time.Sleep(1 * time.Second)

		popularTopics, err := fetchPopularTopics(account.Id, groupName)

		So(err, ShouldBeNil)
		So(popularTopics, ShouldNotBeNil)

		So(len(popularTopics), ShouldBeGreaterThanOrEqualTo, 3)

		So(popularTopics[0].Channel.Name, ShouldEqual, "5times")
		So(popularTopics[0].IsParticipant, ShouldEqual, false)
		So(popularTopics[0].ParticipantCount, ShouldEqual, 0)

		So(popularTopics[1].Channel.Name, ShouldEqual, "4times")
		So(popularTopics[1].IsParticipant, ShouldEqual, false)
		So(popularTopics[1].ParticipantCount, ShouldEqual, 0)

		So(popularTopics[2].Channel.Name, ShouldEqual, "3times")
		So(popularTopics[2].IsParticipant, ShouldEqual, false)
		So(popularTopics[2].ParticipantCount, ShouldEqual, 0)

	})
}

func fetchPopularTopics(accountId int64, groupName string) ([]*models.ChannelContainer, error) {
	url := fmt.Sprintf("/popular/topics/weekly?accountId=%d&groupName=%s", accountId, groupName)
	res, err := sendRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}

	var channels []*models.ChannelContainer
	err = json.Unmarshal(res, &channels)
	if err != nil {
		return nil, err
	}

	return channels, nil
}
