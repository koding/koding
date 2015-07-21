package main

import (
	"socialapi/models"
	"socialapi/rest"
	"socialapi/workers/common/tests"
	"testing"

	"github.com/jinzhu/gorm"
	"github.com/koding/runner"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelCreation(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("while  testing channel", t, func() {
			Convey("First Create Users", func() {
				account, err := models.CreateAccountInBothDbs()
				So(err, ShouldBeNil)

				groupName := models.RandomGroupName()

				ses, err := models.FetchOrCreateSession(account.Nick, groupName)
				So(err, ShouldBeNil)
				So(ses, ShouldNotBeNil)

				groupChannel := models.CreateTypedGroupedChannelWithTest(
					account.Id,
					models.Channel_TYPE_GROUP,
					groupName,
				)

				So(err, ShouldBeNil)
				So(groupChannel, ShouldNotBeNil)

				nonOwnerAccount := models.NewAccount()
				nonOwnerAccount.OldId = AccountOldId2.Hex()
				nonOwnerAccount, err = rest.CreateAccount(nonOwnerAccount)
				So(err, ShouldBeNil)
				So(nonOwnerAccount, ShouldNotBeNil)

				noses, err := models.FetchOrCreateSession(
					nonOwnerAccount.Nick,
					groupName,
				)

				So(err, ShouldBeNil)
				So(noses, ShouldNotBeNil)

				Convey("we should be able to create it", func() {
					channel1, err := rest.CreateChannelByGroupNameAndType(
						account.Id,
						groupName,
						models.Channel_TYPE_PRIVATE_MESSAGE,
						ses.ClientId,
					)
					So(err, ShouldBeNil)
					So(channel1, ShouldNotBeNil)

					_, err = rest.AddChannelParticipant(channel1.Id, account.Id, account.Id)
					So(err, ShouldBeNil)

					Convey("owner should be able to update it", func() {
						updatedPurpose := "another purpose from the paradise"
						channel1.Purpose = updatedPurpose

						channel2, err := rest.UpdateChannel(channel1, ses.ClientId)
						So(err, ShouldBeNil)
						So(channel2, ShouldNotBeNil)

						So(channel1.Purpose, ShouldEqual, channel1.Purpose)

						Convey("owner should be able to update payload", func() {
							if channel1.Payload == nil {
								channel1.Payload = gorm.Hstore{}
							}

							value := "value"
							channel1.Payload = gorm.Hstore{
								"key": &value,
							}
							channel2, err := rest.UpdateChannel(channel1, ses.ClientId)
							So(err, ShouldBeNil)
							So(channel2, ShouldNotBeNil)
							So(channel1.Payload, ShouldNotBeNil)
							So(*channel1.Payload["key"], ShouldEqual, value)
						})

					})

					Convey("owner should be get channel by name", func() {
						channel2, err := rest.FetchChannelByName(
							account.Id,
							channel1.Name,
							channel1.GroupName,
							channel1.TypeConstant,
							ses.ClientId,
						)
						So(err, ShouldBeNil)
						So(channel2, ShouldNotBeNil)
						So(channel1.Id, ShouldEqual, channel2.Id)
						So(channel1.Name, ShouldEqual, channel2.Name)
						So(channel1.GroupName, ShouldEqual, channel2.GroupName)
					})

					Convey("non-owner should not be able to update it", func() {
						updatedPurpose := "another purpose from the paradise"
						channel1.Purpose = updatedPurpose
						channel1.CreatorId = nonOwnerAccount.Id

						channel2, err := rest.UpdateChannel(channel1, noses.ClientId)
						So(err, ShouldNotBeNil)
						So(channel2, ShouldBeNil)
					})

					Convey("non-owner should not be able to get channel by name", func() {
						_, err := rest.FetchChannelByName(
							nonOwnerAccount.Id,
							channel1.Name,
							channel1.GroupName,
							channel1.TypeConstant,
							noses.ClientId,
						)
						So(err, ShouldNotBeNil)
					})

				})

				Convey("normal user shouldnt be able to add new participants to pinned activity channel", func() {
					channel1, err := rest.CreateChannelByGroupNameAndType(
						account.Id,
						groupName,
						models.Channel_TYPE_PINNED_ACTIVITY,
						ses.ClientId,
					)
					So(err, ShouldBeNil)
					So(channel1, ShouldNotBeNil)

					channelParticipant, err := rest.AddChannelParticipant(channel1.Id, nonOwnerAccount.Id, nonOwnerAccount.Id)
					// there should be an err
					So(err, ShouldNotBeNil)
					// channel should be nil
					So(channelParticipant, ShouldBeNil)
				})

				Convey("owner should be able list participants", func() {
					channel1, err := rest.CreateChannelByGroupNameAndType(
						account.Id,
						groupName,
						models.Channel_TYPE_DEFAULT,
						ses.ClientId,
					)
					So(err, ShouldBeNil)
					So(channel1, ShouldNotBeNil)

					// add first participant
					channelParticipant1, err := rest.AddChannelParticipant(channel1.Id, account.Id, nonOwnerAccount.Id)
					// there should be an err
					So(err, ShouldBeNil)
					// channel should be nil
					So(channelParticipant1, ShouldNotBeNil)

					nonOwnerAccount2 := models.NewAccount()
					nonOwnerAccount2.OldId = AccountOldId3.Hex()
					nonOwnerAccount2, err = rest.CreateAccount(nonOwnerAccount2)
					So(err, ShouldBeNil)
					So(nonOwnerAccount2, ShouldNotBeNil)

					channelParticipant2, err := rest.AddChannelParticipant(channel1.Id, account.Id, nonOwnerAccount2.Id)
					// there should be an err
					So(err, ShouldBeNil)
					// channel should be nil
					So(channelParticipant2, ShouldNotBeNil)

					participants, err := rest.ListChannelParticipants(channel1.Id, account.Id)
					// there should be an err
					So(err, ShouldBeNil)
					So(participants, ShouldNotBeNil)

					// owner
					// nonOwner1
					// nonOwner2
					So(len(participants), ShouldEqual, 3)
				})

				Convey("normal user should be able to list participants", func() {
					channel1, err := rest.CreateChannelByGroupNameAndType(
						account.Id,
						groupName,
						models.Channel_TYPE_DEFAULT,
						ses.ClientId,
					)
					So(err, ShouldBeNil)
					So(channel1, ShouldNotBeNil)

					// add first participant
					channelParticipant1, err := rest.AddChannelParticipant(channel1.Id, account.Id, nonOwnerAccount.Id)
					// there should be an err
					So(err, ShouldBeNil)
					// channel should be nil
					So(channelParticipant1, ShouldNotBeNil)

					nonOwnerAccount2 := models.NewAccount()
					nonOwnerAccount2.OldId = AccountOldId3.Hex()
					nonOwnerAccount2, err = rest.CreateAccount(nonOwnerAccount2)
					So(err, ShouldBeNil)
					So(nonOwnerAccount2, ShouldNotBeNil)

					channelParticipant2, err := rest.AddChannelParticipant(channel1.Id, account.Id, nonOwnerAccount2.Id)
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
	})
}
