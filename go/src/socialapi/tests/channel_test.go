package main

import (
	"koding/db/mongodb/modelhelper"
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

				ses, err := modelhelper.FetchOrCreateSession(account.Nick, groupName)
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

				noses, err := modelhelper.FetchOrCreateSession(
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

					_, err = rest.AddChannelParticipant(channel1.Id, ses.ClientId, account.Id)
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
					Convey("participant should be able to update only purpose, not name or payload", func() {
						_, err = rest.AddChannelParticipant(channel1.Id, ses.ClientId, nonOwnerAccount.Id)
						So(err, ShouldBeNil)

						updatedPurpose := "ChannelPurposeUpdated"
						updatedName := "ChannelNameUpdated"
						channel1.Name = updatedName
						channel1.Purpose = updatedPurpose

						channel2, err := rest.UpdateChannel(channel1, noses.ClientId)
						So(err, ShouldBeNil)
						So(channel2, ShouldNotBeNil)
						So(channel2.Name, ShouldNotBeNil)
						// participant cannot update channel name
						// can update only purpose of the channel
						So(channel2.Name, ShouldNotEqual, updatedName)
						So(channel2.Purpose, ShouldEqual, updatedPurpose)
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
						So(channel1.GroupName, ShouldEqual, channel2.GroupName)
					})

					Convey("unread count should be set", func() {
						channelContainer, err := rest.FetchChannelContainerByName(account.Id, channel1.Name, channel1.GroupName, channel1.TypeConstant, ses.ClientId)
						So(err, ShouldBeNil)
						So(channelContainer, ShouldNotBeNil)
						So(channelContainer.UnreadCount, ShouldEqual, 0)

						post, err := rest.CreatePost(channel1.Id, ses.ClientId)
						So(err, ShouldBeNil)
						So(post, ShouldNotBeNil)

						channelContainer, err = rest.FetchChannelContainerByName(account.Id, channel1.Name, channel1.GroupName, channel1.TypeConstant, ses.ClientId)
						So(err, ShouldBeNil)
						So(channelContainer, ShouldNotBeNil)
						So(channelContainer.UnreadCount, ShouldEqual, 1)
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

					channelParticipant, err := rest.AddChannelParticipant(channel1.Id, noses.ClientId, nonOwnerAccount.Id)
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
					channelParticipant1, err := rest.AddChannelParticipant(channel1.Id, ses.ClientId, nonOwnerAccount.Id)
					// there should be an err
					So(err, ShouldBeNil)
					// channel should be nil
					So(channelParticipant1, ShouldNotBeNil)

					nonOwnerAccount2 := models.NewAccount()
					nonOwnerAccount2.OldId = AccountOldId3.Hex()
					nonOwnerAccount2, err = rest.CreateAccount(nonOwnerAccount2)
					So(err, ShouldBeNil)
					So(nonOwnerAccount2, ShouldNotBeNil)

					channelParticipant2, err := rest.AddChannelParticipant(channel1.Id, ses.ClientId, nonOwnerAccount2.Id)
					// there should be an err
					So(err, ShouldBeNil)
					// channel should be nil
					So(channelParticipant2, ShouldNotBeNil)

					participants, err := rest.ListChannelParticipants(channel1.Id, ses.ClientId)
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
					channelParticipant1, err := rest.AddChannelParticipant(channel1.Id, ses.ClientId, nonOwnerAccount.Id)
					// there should be an err
					So(err, ShouldBeNil)
					// channel should be nil
					So(channelParticipant1, ShouldNotBeNil)

					nonOwnerAccount2 := models.NewAccount()
					nonOwnerAccount2.OldId = AccountOldId3.Hex()
					nonOwnerAccount2, err = rest.CreateAccount(nonOwnerAccount2)
					So(err, ShouldBeNil)
					So(nonOwnerAccount2, ShouldNotBeNil)

					nonOwnerSes2, err := modelhelper.FetchOrCreateSession(nonOwnerAccount2.Nick, groupName)
					So(err, ShouldBeNil)
					So(nonOwnerSes2, ShouldNotBeNil)

					channelParticipant2, err := rest.AddChannelParticipant(channel1.Id, ses.ClientId, nonOwnerAccount2.Id)
					// there should be an err
					So(err, ShouldBeNil)
					// channel should be nil
					So(channelParticipant2, ShouldNotBeNil)

					participants, err := rest.ListChannelParticipants(channel1.Id, nonOwnerSes2.ClientId)
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

func TestChannelByParticipants(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("while fetching channels by their participants", t, func() {
			admin1, _, groupName1 := models.CreateRandomGroupDataWithChecks()

			ses1, err := modelhelper.FetchOrCreateSession(admin1.Nick, groupName1)
			So(err, ShouldBeNil)
			So(ses1, ShouldNotBeNil)

			acc1, err := models.CreateAccountInBothDbs()
			So(err, ShouldBeNil)
			So(acc1, ShouldNotBeNil)

			acc2, err := models.CreateAccountInBothDbs()
			So(err, ShouldBeNil)
			So(acc1, ShouldNotBeNil)

			tc1 := createChannelAndParticipants(admin1, groupName1, models.Channel_TYPE_TOPIC, ses1.ClientId, acc1.Id, acc2.Id)
			tc2 := createChannelAndParticipants(admin1, groupName1, models.Channel_TYPE_TOPIC, ses1.ClientId, acc1.Id, acc2.Id)

			Convey("valid request should return valid response", func() {
				channels, err := rest.FetchChannelsByParticipants([]int64{acc1.Id, acc2.Id}, models.Channel_TYPE_TOPIC, ses1.ClientId)
				// there should be an err
				So(err, ShouldBeNil)
				So(channels, ShouldNotBeNil)
				So(len(channels), ShouldEqual, 2)
				So(tc1.Id, ShouldEqual, channels[0].Channel.Id)
				So(tc2.Id, ShouldEqual, channels[1].Channel.Id)
			})

			Convey("other group's content should not be in the result set", func() {

				groupName2 := models.RandomGroupName()
				models.CreateTypedGroupedChannelWithTest(
					admin1.Id,
					models.Channel_TYPE_GROUP,
					groupName2,
				)

				ses2, err := modelhelper.FetchOrCreateSession(admin1.Nick, groupName2)
				So(err, ShouldBeNil)
				So(ses2, ShouldNotBeNil)

				gtc1 := createChannelAndParticipants(admin1, groupName2, models.Channel_TYPE_TOPIC, ses2.ClientId, acc1.Id, acc2.Id)
				gtc2 := createChannelAndParticipants(admin1, groupName2, models.Channel_TYPE_TOPIC, ses2.ClientId, acc1.Id, acc2.Id)

				channels, err := rest.FetchChannelsByParticipants([]int64{acc1.Id, acc2.Id}, models.Channel_TYPE_TOPIC, ses1.ClientId)
				// there should be an err
				So(err, ShouldBeNil)
				So(channels, ShouldNotBeNil)
				So(len(channels), ShouldEqual, 2)
				So(channels[0].Channel.GroupName, ShouldEqual, groupName1)
				So(channels[1].Channel.GroupName, ShouldEqual, groupName1)
				So(tc1.Id, ShouldEqual, channels[0].Channel.Id)
				So(tc2.Id, ShouldEqual, channels[1].Channel.Id)

				channels, err = rest.FetchChannelsByParticipants([]int64{acc1.Id, acc2.Id}, models.Channel_TYPE_TOPIC, ses2.ClientId)
				// there should be an err
				So(err, ShouldBeNil)
				So(channels, ShouldNotBeNil)
				So(len(channels), ShouldEqual, 2)
				So(channels[0].Channel.GroupName, ShouldEqual, groupName2)
				So(channels[1].Channel.GroupName, ShouldEqual, groupName2)
				So(gtc1.Id, ShouldEqual, channels[0].Channel.Id)
				So(gtc2.Id, ShouldEqual, channels[1].Channel.Id)

			})
		})
	})
}

func createChannelAndParticipants(
	admin *models.Account,
	groupName string,
	typeConstant string,
	token string,
	participants ...int64) *models.Channel {
	tc1, err := rest.CreateChannelByGroupNameAndType(
		admin.Id,
		groupName,
		typeConstant,
		token,
	)
	So(err, ShouldBeNil)
	So(tc1, ShouldNotBeNil)

	for _, participant := range participants {
		// add first participant
		channelParticipant1, err := rest.AddChannelParticipant(tc1.Id, token, participant)
		So(err, ShouldBeNil)
		So(channelParticipant1, ShouldNotBeNil)
	}

	return tc1
}
