package main

import (
	"socialapi/models"
	"socialapi/rest"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelCreation(t *testing.T) {
	Convey("while  testing channel", t, func() {
		Convey("First Create Users", func() {
			account1 := models.NewAccount()
			account1.OldId = AccountOldId.Hex()
			account, err := rest.CreateAccount(account1)
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)

			nonOwnerAccount := models.NewAccount()
			nonOwnerAccount.OldId = AccountOldId2.Hex()
			nonOwnerAccount, err = rest.CreateAccount(nonOwnerAccount)
			So(err, ShouldBeNil)
			So(nonOwnerAccount, ShouldNotBeNil)

			Convey("we should be able to create it", func() {
				channel1, err := rest.CreateChannelByGroupNameAndType(account1.Id, "testgroup", models.Channel_TYPE_CHAT)
				So(err, ShouldBeNil)
				So(channel1, ShouldNotBeNil)

				Convey("owner should be able to update it", func() {
					updatedPurpose := "another purpose from the paradise"
					channel1.Purpose = updatedPurpose

					channel2, err := rest.UpdateChannel(channel1)
					So(err, ShouldBeNil)
					So(channel2, ShouldNotBeNil)

					So(channel1.Purpose, ShouldEqual, channel1.Purpose)
				})
				Convey("non-owner should not be able to update it", func() {
					updatedPurpose := "another purpose from the paradise"
					channel1.Purpose = updatedPurpose
					channel1.CreatorId = nonOwnerAccount.Id

					channel2, err := rest.UpdateChannel(channel1)
					So(err, ShouldNotBeNil)
					So(channel2, ShouldBeNil)
				})
			})

			Convey("normal user shouldnt be able to add new participants to pinned activity channel", func() {
				channel1, err := rest.CreateChannelByGroupNameAndType(account1.Id, "testgroup", models.Channel_TYPE_PINNED_ACTIVITY)
				So(err, ShouldBeNil)
				So(channel1, ShouldNotBeNil)

				channelParticipant, err := rest.AddChannelParticipant(channel1.Id, nonOwnerAccount.Id, nonOwnerAccount.Id)
				// there should be an err
				So(err, ShouldNotBeNil)
				// channel should be nil
				So(channelParticipant, ShouldBeNil)
			})

			Convey("normal user should not be able to add new participants to chat channel", func() {
				channel1, err := rest.CreateChannelByGroupNameAndType(account1.Id, "testgroup", models.Channel_TYPE_CHAT)
				So(err, ShouldBeNil)
				So(channel1, ShouldNotBeNil)

				channelParticipant, err := rest.AddChannelParticipant(channel1.Id, nonOwnerAccount.Id, nonOwnerAccount.Id)
				// there should be an err
				So(err, ShouldNotBeNil)
				// channel should be nil
				So(channelParticipant, ShouldBeNil)
			})

			Convey("owner should be able to remove participants from chat channel it", func() {
				channel1, err := rest.CreateChannelByGroupNameAndType(account1.Id, "testgroup", models.Channel_TYPE_CHAT)
				So(err, ShouldBeNil)
				So(channel1, ShouldNotBeNil)

				channelParticipant, err := rest.AddChannelParticipant(channel1.Id, account1.Id, nonOwnerAccount.Id)
				// there should be an err
				So(err, ShouldBeNil)
				// channel should be nil
				So(channelParticipant, ShouldNotBeNil)

				_, err = rest.DeleteChannelParticipant(channel1.Id, account1.Id, nonOwnerAccount.Id)
				// there should be an err
				So(err, ShouldBeNil)
			})

			Convey("owner should be able list participants", func() {
				channel1, err := rest.CreateChannelByGroupNameAndType(account1.Id, "testgroup", models.Channel_TYPE_DEFAULT)
				So(err, ShouldBeNil)
				So(channel1, ShouldNotBeNil)

				// add first participant
				channelParticipant1, err := rest.AddChannelParticipant(channel1.Id, account1.Id, nonOwnerAccount.Id)
				// there should be an err
				So(err, ShouldBeNil)
				// channel should be nil
				So(channelParticipant1, ShouldNotBeNil)

				nonOwnerAccount2 := models.NewAccount()
				nonOwnerAccount2.OldId = AccountOldId3.Hex()
				nonOwnerAccount2, err = rest.CreateAccount(nonOwnerAccount2)
				So(err, ShouldBeNil)
				So(nonOwnerAccount2, ShouldNotBeNil)

				channelParticipant2, err := rest.AddChannelParticipant(channel1.Id, account1.Id, nonOwnerAccount2.Id)
				// there should be an err
				So(err, ShouldBeNil)
				// channel should be nil
				So(channelParticipant2, ShouldNotBeNil)

				participants, err := rest.ListChannelParticipants(channel1.Id, account1.Id)
				// there should be an err
				So(err, ShouldBeNil)
				So(participants, ShouldNotBeNil)

				// owner
				// nonOwner1
				// nonOwner2
				So(len(participants), ShouldEqual, 3)
			})

			Convey("normal user should be able to list participants", func() {
				channel1, err := rest.CreateChannelByGroupNameAndType(account1.Id, "testgroup", models.Channel_TYPE_DEFAULT)
				So(err, ShouldBeNil)
				So(channel1, ShouldNotBeNil)

				// add first participant
				channelParticipant1, err := rest.AddChannelParticipant(channel1.Id, account1.Id, nonOwnerAccount.Id)
				// there should be an err
				So(err, ShouldBeNil)
				// channel should be nil
				So(channelParticipant1, ShouldNotBeNil)

				nonOwnerAccount2 := models.NewAccount()
				nonOwnerAccount2.OldId = AccountOldId3.Hex()
				nonOwnerAccount2, err = rest.CreateAccount(nonOwnerAccount2)
				So(err, ShouldBeNil)
				So(nonOwnerAccount2, ShouldNotBeNil)

				channelParticipant2, err := rest.AddChannelParticipant(channel1.Id, account1.Id, nonOwnerAccount2.Id)
				// there should be an err
				So(err, ShouldBeNil)
				// channel should be nil
				So(channelParticipant2, ShouldNotBeNil)

				participants, err := rest.ListChannelParticipants(channel1.Id, nonOwnerAccount2.Id)
				// there should be an err
				So(err, ShouldBeNil)
				So(participants, ShouldNotBeNil)

				// owner
				// nonOwner1
				// nonOwner2
				So(len(participants), ShouldEqual, 3)
			})
		})
	})
}
