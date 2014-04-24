package main

import (
	"fmt"
	"math/rand"
	"socialapi/models"
	"strconv"
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelCreation(t *testing.T) {
	Convey("while  testing channel", t, func() {
		Convey("First Create Users", func() {
			account1 := models.NewAccount()
			account1.OldId = AccountOldId.Hex()
			account, err := createAccount(account1)
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)

			nonOwnerAccount := models.NewAccount()
			nonOwnerAccount.OldId = AccountOldId2.Hex()
			nonOwnerAccount, err = createAccount(nonOwnerAccount)
			So(err, ShouldBeNil)
			So(nonOwnerAccount, ShouldNotBeNil)

			Convey("we should be able to create it", func() {
				channel1, err := createChannelByGroupNameAndType(account1.Id, "testgroup", models.Channel_TYPE_CHAT)
				So(err, ShouldBeNil)
				So(channel1, ShouldNotBeNil)

				Convey("owner should be able to update it", func() {
					updatedPurpose := "another purpose from the paradise"
					channel1.Purpose = updatedPurpose

					channel2, err := updateChannel(channel1)
					So(err, ShouldBeNil)
					So(channel2, ShouldNotBeNil)

					So(channel1.Purpose, ShouldEqual, channel1.Purpose)
				})
				Convey("non-owner should not be able to update it", func() {
					updatedPurpose := "another purpose from the paradise"
					channel1.Purpose = updatedPurpose
					channel1.CreatorId = nonOwnerAccount.Id

					channel2, err := updateChannel(channel1)
					So(err, ShouldNotBeNil)
					So(channel2, ShouldBeNil)
				})
			})

			Convey("owner should be able to add new participants into it", func() {
				channel1, err := createChannelByGroupNameAndType(account1.Id, "testgroup", models.Channel_TYPE_CHAT)
				So(err, ShouldBeNil)
				So(channel1, ShouldNotBeNil)

				channelParticipant, err := addChannelParticipant(channel1.Id, account1.Id, nonOwnerAccount.Id)
				// there should be an err
				So(err, ShouldBeNil)
				// channel should be nil
				So(channelParticipant, ShouldNotBeNil)
			})

			Convey("normal user shouldnt be able to add new participants to it", func() {
				channel1, err := createChannelByGroupNameAndType(account1.Id, "testgroup", models.Channel_TYPE_CHAT)
				So(err, ShouldBeNil)
				So(channel1, ShouldNotBeNil)

				channelParticipant, err := addChannelParticipant(channel1.Id, nonOwnerAccount.Id, nonOwnerAccount.Id)
				// there should be an err
				So(err, ShouldNotBeNil)
				// channel should be nil
				So(channelParticipant, ShouldBeNil)
			})

			Convey("owner should be able to remove participants from it", func() {
				channel1, err := createChannelByGroupNameAndType(account1.Id, "testgroup", models.Channel_TYPE_CHAT)
				So(err, ShouldBeNil)
				So(channel1, ShouldNotBeNil)

				channelParticipant, err := addChannelParticipant(channel1.Id, account1.Id, nonOwnerAccount.Id)
				// there should be an err
				So(err, ShouldBeNil)
				// channel should be nil
				So(channelParticipant, ShouldNotBeNil)

				_, err = deleteChannelParticipant(channel1.Id, account1.Id, nonOwnerAccount.Id)
				// there should be an err
				So(err, ShouldBeNil)
			})

			Convey("normal user shouldnt be able to remove participants from it", func() {
				channel1, err := createChannelByGroupNameAndType(account1.Id, "testgroup", models.Channel_TYPE_CHAT)
				So(err, ShouldBeNil)
				So(channel1, ShouldNotBeNil)

				channelParticipant, err := addChannelParticipant(channel1.Id, account1.Id, nonOwnerAccount.Id)
				// there should be an err
				So(err, ShouldBeNil)
				// channel should be nil
				So(channelParticipant, ShouldNotBeNil)

				_, err = deleteChannelParticipant(channel1.Id, nonOwnerAccount.Id, nonOwnerAccount.Id)
				// there should be an err
				So(err, ShouldNotBeNil)
			})

			Convey("owner should be able list participants", func() {
				channel1, err := createChannelByGroupNameAndType(account1.Id, "testgroup", models.Channel_TYPE_CHAT)
				So(err, ShouldBeNil)
				So(channel1, ShouldNotBeNil)

				// add first participant
				channelParticipant1, err := addChannelParticipant(channel1.Id, account1.Id, nonOwnerAccount.Id)
				// there should be an err
				So(err, ShouldBeNil)
				// channel should be nil
				So(channelParticipant1, ShouldNotBeNil)

				nonOwnerAccount2 := models.NewAccount()
				nonOwnerAccount2.OldId = AccountOldId3.Hex()
				nonOwnerAccount2, err = createAccount(nonOwnerAccount2)
				So(err, ShouldBeNil)
				So(nonOwnerAccount2, ShouldNotBeNil)

				channelParticipant2, err := addChannelParticipant(channel1.Id, account1.Id, nonOwnerAccount2.Id)
				// there should be an err
				So(err, ShouldBeNil)
				// channel should be nil
				So(channelParticipant2, ShouldNotBeNil)

				participants, err := listChannelParticipants(channel1.Id, account1.Id)
				// there should be an err
				So(err, ShouldBeNil)
				So(participants, ShouldNotBeNil)
				So(len(participants), ShouldEqual, 2)

			})

			Convey("normal user should be able to list participants", func() {
				channel1, err := createChannelByGroupNameAndType(account1.Id, "testgroup", models.Channel_TYPE_CHAT)
				So(err, ShouldBeNil)
				So(channel1, ShouldNotBeNil)

				// add first participant
				channelParticipant1, err := addChannelParticipant(channel1.Id, account1.Id, nonOwnerAccount.Id)
				// there should be an err
				So(err, ShouldBeNil)
				// channel should be nil
				So(channelParticipant1, ShouldNotBeNil)

				nonOwnerAccount2 := models.NewAccount()
				nonOwnerAccount2.OldId = AccountOldId3.Hex()
				nonOwnerAccount2, err = createAccount(nonOwnerAccount2)
				So(err, ShouldBeNil)
				So(nonOwnerAccount2, ShouldNotBeNil)

				channelParticipant2, err := addChannelParticipant(channel1.Id, account1.Id, nonOwnerAccount2.Id)
				// there should be an err
				So(err, ShouldBeNil)
				// channel should be nil
				So(channelParticipant2, ShouldNotBeNil)

				participants, err := listChannelParticipants(channel1.Id, nonOwnerAccount2.Id)
				// there should be an err
				So(err, ShouldBeNil)
				So(participants, ShouldNotBeNil)
				So(len(participants), ShouldEqual, 2)
			})
		})
	})
}

func createChannel(creatorId int64) (*models.Channel, error) {
	c := models.NewChannel()
	rand.Seed(time.Now().UnixNano())
	groupName := c.GroupName + strconv.Itoa(rand.Intn(100000000))

	return createChannelByGroupNameAndType(creatorId, groupName, c.TypeConstant)
}

func createChannelByGroupNameAndType(creatorId int64, groupName, typeConstant string) (*models.Channel, error) {
	c := models.NewChannel()
	c.GroupName = groupName
	c.CreatorId = creatorId
	c.TypeConstant = typeConstant
	c.Name = c.Name + strconv.Itoa(rand.Intn(100000000))
	cm, err := sendModel("POST", "/channel", c)
	if err != nil {
		return nil, err
	}
	return cm.(*models.Channel), nil
}

func updateChannel(cm *models.Channel) (*models.Channel, error) {
	url := fmt.Sprintf("/channel/%d", cm.Id)
	cmI, err := sendModel("POST", url, cm)
	if err != nil {
		return nil, err
	}

	return cmI.(*models.Channel), nil
}

func getChannel(id int64) (*models.Channel, error) {

	url := fmt.Sprintf("/channel/%d", id)
	cm := models.NewChannel()
	cmI, err := sendModel("GET", url, cm)
	if err != nil {
		return nil, err
	}
	return cmI.(*models.Channel), nil
}

func deleteChannel(creatorId, channelId int64) error {
	c := models.NewChannel()
	c.CreatorId = creatorId
	c.Id = channelId

	url := fmt.Sprintf("/channel/%d/delete", channelId)
	_, err := sendModel("POST", url, c)
	if err != nil {
		return err
	}
	return nil
}
