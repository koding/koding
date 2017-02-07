package models

import (
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/request"
	"socialapi/workers/common/tests"
	"testing"

	"github.com/koding/bongo"
	"github.com/koding/runner"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelNewChannel(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		c := NewChannel()

		Convey("given a NewChannel", t, func() {

			Convey("it should have Name as set", func() {
				So(c.Name, ShouldNotBeBlank)
			})

			Convey("it should have GroupName as set", func() {
				So(c.GroupName, ShouldNotBeBlank)
			})

			Convey("it should have TypeConstant as set", func() {
				So(c.TypeConstant, ShouldEqual, Channel_TYPE_DEFAULT)
			})

			Convey("it should have PrivacyConstant as set", func() {
				So(c.PrivacyConstant, ShouldEqual, Channel_PRIVACY_PRIVATE)
			})
		})
	})
}

func TestChannelNewCollaborationChannel(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		var creatorId int64 = 123
		groupName := "testGroup"
		c := NewPrivateChannel(creatorId, groupName, Channel_TYPE_DEFAULT)

		Convey("given a NewPrivateMessageChannel", t, func() {
			Convey("it should have group name", func() {
				So(c.GroupName, ShouldEqual, groupName)
			})

			Convey("it should have creator id", func() {
				So(c.CreatorId, ShouldEqual, creatorId)
			})

			Convey("it should have a name", func() {
				So(c.Name, ShouldNotBeBlank)
			})

			Convey("it should have the give type constant", func() {
				So(c.TypeConstant, ShouldEqual, Channel_TYPE_DEFAULT)
			})

			Convey("it should have privacy constant", func() {
				So(c.PrivacyConstant, ShouldEqual, Channel_PRIVACY_PRIVATE)
			})

			Convey("it should not have purpose", func() {
				So(c.Purpose, ShouldBeBlank)
			})
		})
	})
}

func TestChannelNewPrivateChannel(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		var creatorId int64 = 123
		groupName := "testGroup"
		c := NewCollaborationChannel(creatorId, groupName)

		Convey("given a NewPrivateMessageChannel", t, func() {
			Convey("it should have group name", func() {
				So(c.GroupName, ShouldEqual, groupName)
			})

			Convey("it should have creator id", func() {
				So(c.CreatorId, ShouldEqual, creatorId)
			})

			Convey("it should have a name", func() {
				So(c.Name, ShouldNotBeBlank)
			})

			Convey("it should have type constant", func() {
				So(c.TypeConstant, ShouldEqual, Channel_TYPE_COLLABORATION)
			})

			Convey("it should have privacy constant", func() {
				So(c.PrivacyConstant, ShouldEqual, Channel_PRIVACY_PRIVATE)
			})

			Convey("it should have purpose", func() {
				So(c.Purpose, ShouldBeBlank)
			})
		})
	})
}

func TestChannelNewPrivateMessageChannel(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		// read config once
		config.MustRead(r.Conf.Path)

		var creatorId int64 = 123
		groupName := "testGroup"
		c := NewPrivateMessageChannel(creatorId, groupName)

		Convey("given a NewPrivateMessageChannel", t, func() {
			Convey("it should have group name", func() {
				So(c.GroupName, ShouldEqual, groupName)
			})

			Convey("it should have creator id", func() {
				So(c.CreatorId, ShouldEqual, creatorId)
			})

			Convey("it should have a name", func() {
				So(c.Name, ShouldNotBeBlank)
			})

			Convey("it should have type constant", func() {
				So(c.TypeConstant, ShouldEqual, Channel_TYPE_PRIVATE_MESSAGE)
			})

			Convey("it should have privacy constant", func() {
				So(c.PrivacyConstant, ShouldEqual, Channel_PRIVACY_PRIVATE)
			})

			Convey("it should have purpose", func() {
				So(c.Purpose, ShouldBeBlank)
			})
		})
	})
}

// func createAccount()
func TestChannelCreate(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		Convey("while creating channel", t, func() {
			Convey("channel name should not be empty", func() {
				// NewChannel sets the default values for channel
				c := NewChannel()
				c.Name = ""
				So(c.Create().Error(), ShouldContainSubstring, "Validation failed")
			})

			Convey("channel groupName should not be empty", func() {
				// NewChannel sets the default values for channel
				c := NewChannel()
				c.GroupName = ""
				So(c.Create().Error(), ShouldContainSubstring, "Validation failed")
			})

			Convey("channel typeConstant should not be empty", func() {
				// NewChannel sets the default values for channel
				c := NewChannel()
				c.TypeConstant = ""
				So(c.Create().Error(), ShouldContainSubstring, "Validation failed")
			})

			Convey("channel should have creator id", func() {
				// NewChannel sets the default values for channel
				c := NewChannel()
				c.CreatorId = 0
				So(c.Create().Error(), ShouldContainSubstring, "Validation failed")
			})

			Convey("channel name should not contain whitespace in the middle", func() {
				c := NewChannel()
				c.CreatorId = 1
				c.Name = "name channel"

				So(c.Create().Error(), ShouldContainSubstring, "has empty space")
			})

			Convey("channel name should not contain leading whitespace", func() {
				c := NewChannel()
				c.CreatorId = 1
				c.Name = " namechannel"
				So(c.Create().Error(), ShouldContainSubstring, "has empty space")
			})

			Convey("channel name should not contain trailing whitespace", func() {
				c := NewChannel()
				c.CreatorId = 1
				c.Name = "namechannel "
				So(c.Create().Error(), ShouldContainSubstring, "has empty space")
			})

			Convey("calling group channel create twice should not return error", func() {
				c := NewChannel()
				c.GroupName = "malitest"
				c.TypeConstant = Channel_TYPE_GROUP
				account := CreateAccountWithTest()
				c.CreatorId = account.Id
				So(c.Create(), ShouldBeNil)
				c.Id = 0
				So(c.Create(), ShouldBeNil)
			})

			Convey("calling group channel create twice should return same channel", func() {
				c := NewChannel()
				c.GroupName = "malitest2"
				c.TypeConstant = Channel_TYPE_GROUP
				account := CreateAccountWithTest()
				c.CreatorId = account.Id
				So(c.Create(), ShouldBeNil)
				firstChannel := c.Id
				c.Id = 0
				So(c.Create(), ShouldBeNil)
				So(firstChannel, ShouldEqual, c.Id)
			})

			Convey("calling followers channel create twice should not return error", func() {
				c := NewChannel()
				c.TypeConstant = Channel_TYPE_FOLLOWERS
				account := CreateAccountWithTest()
				c.CreatorId = account.Id
				So(c.Create(), ShouldBeNil)
				c.Id = 0
				So(c.Create(), ShouldBeNil)
			})

			Convey("calling followers channel create twice should return same channel", func() {
				c := NewChannel()
				c.TypeConstant = Channel_TYPE_FOLLOWERS
				account := CreateAccountWithTest()
				c.CreatorId = account.Id
				So(c.Create(), ShouldBeNil)
				firstChannel := c.Id
				c.Id = 0
				So(c.Create(), ShouldBeNil)
				So(firstChannel, ShouldEqual, c.Id)
			})
		})
	})
}

func TestChannelBongoName(t *testing.T) {
	Convey("while testing BongoName()", t, func() {
		So(NewChannel().BongoName(), ShouldEqual, ChannelBongoName)
	})
}

func TestChannelCanOpen(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		Convey("while testing channel permissions", t, func() {
			Convey("can not open uninitialized channel", func() {
				c := NewChannel()
				canOpen, err := c.CanOpen(1231)
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrChannelIdIsNotSet)
				So(canOpen, ShouldBeFalse)
			})

			Convey("channel should have creator id while testing CanOpen channel", func() {
				c := NewChannel()
				c.Id = 123
				canOpen, err := c.CanOpen(0)
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrCreatorIdIsNotSet)
				So(canOpen, ShouldBeFalse)
			})

			Convey("uninitialized account can open koding's group channel", func() {
				c := NewChannel()
				c.Id = 123
				c.CreatorId = 312
				c.TypeConstant = Channel_TYPE_GROUP
				c.GroupName = Channel_KODING_NAME
				canOpen, err := c.CanOpen(0)
				So(err, ShouldBeNil)
				So(canOpen, ShouldBeTrue)
			})

			Convey("uninitialized account can open koding's announcement channel", func() {
				c := NewChannel()
				c.Id = 123
				c.CreatorId = 312
				c.TypeConstant = Channel_TYPE_ANNOUNCEMENT
				canOpen, err := c.CanOpen(0)
				So(err, ShouldBeNil)
				So(canOpen, ShouldBeTrue)
			})

			Convey("participants can open group channel", func() {
				acc := CreateAccountWithTest()
				c := CreateTypedChannelWithTest(acc.Id, Channel_TYPE_GROUP)

				AddParticipantsWithTest(c.Id, acc.Id)

				canOpen, err := c.CanOpen(acc.Id)
				So(err, ShouldBeNil)
				So(canOpen, ShouldBeTrue)
			})

			Convey("participants can open topic channel", func() {
				acc := CreateAccountWithTest()
				c := CreateTypedChannelWithTest(acc.Id, Channel_TYPE_TOPIC)

				AddParticipantsWithTest(c.Id, acc.Id)

				canOpen, err := c.CanOpen(acc.Id)
				So(err, ShouldBeNil)
				So(canOpen, ShouldBeTrue)
			})

			// pinned activity channel can only be opened by the creator
			Convey("participants can open pinned activity channel", func() {
				acc := CreateAccountWithTest()
				c := CreateTypedChannelWithTest(acc.Id, Channel_TYPE_PINNED_ACTIVITY)

				AddParticipantsWithTest(c.Id, acc.Id)

				canOpen, err := c.CanOpen(acc.Id)
				So(err, ShouldBeNil)
				So(canOpen, ShouldBeTrue)
			})

			Convey("participants can open private message channel", func() {
				acc := CreateAccountWithTest()
				c := CreateTypedChannelWithTest(acc.Id, Channel_TYPE_PRIVATE_MESSAGE)

				AddParticipantsWithTest(c.Id, acc.Id)

				canOpen, err := c.CanOpen(acc.Id)
				So(err, ShouldBeNil)
				So(canOpen, ShouldBeTrue)
			})

			//
			// NON participant tests
			//
			Convey("everyone can open koding group channel", func() {
				acc := CreateAccountWithTest()
				c := CreateTypedGroupedChannelWithTest(acc.Id, Channel_TYPE_TOPIC, Channel_KODING_NAME)

				// even if it is not a member of koding, because of guests
				// AddParticipantsWithTest(c.Id, acc.Id)

				canOpen, err := c.CanOpen(acc.Id)
				So(err, ShouldBeNil)
				So(canOpen, ShouldBeTrue)
			})

			Convey("everyone can open koding's topic channel", func() {
				acc := CreateAccountWithTest()

				c := CreateTypedGroupedChannelWithTest(acc.Id, Channel_TYPE_TOPIC, Channel_KODING_NAME)

				acc2 := CreateAccountWithTest()
				canOpen, err := c.CanOpen(acc2.Id)
				So(err, ShouldBeNil)
				So(canOpen, ShouldBeTrue)
			})

			Convey("non - participants can not open pinned activity channel", func() {
				acc := CreateAccountWithTest()
				c := CreateTypedChannelWithTest(acc.Id, Channel_TYPE_PINNED_ACTIVITY)

				account := CreateAccountWithTest()
				canOpen, err := c.CanOpen(account.Id)
				So(err, ShouldBeNil)
				So(canOpen, ShouldBeFalse)
			})

			Convey("non-participants can not open private message channel", func() {
				acc := CreateAccountWithTest()
				c := CreateTypedChannelWithTest(acc.Id, Channel_TYPE_PRIVATE_MESSAGE)

				account := CreateAccountWithTest()
				canOpen, err := c.CanOpen(account.Id)
				So(err, ShouldBeNil)
				So(canOpen, ShouldBeFalse)
			})
		})
	})
}

func TestChannelCanOpenNonKoding(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		Convey("while testing channel permissions for non koding groups", t, func() {
			Convey("uninitialized account can open other group channel", func() {
				c := NewChannel()
				c.Id = 123
				c.CreatorId = 312
				c.TypeConstant = Channel_TYPE_GROUP
				c.GroupName = RandomGroupName()

				canOpen, _ := c.CanOpen(0)
				So(canOpen, ShouldBeFalse)
			})

			Convey("uninitialized account can not open other group's announcement channel", func() {
				c := NewChannel()
				c.Id = 123
				c.CreatorId = 312
				c.TypeConstant = Channel_TYPE_ANNOUNCEMENT
				c.GroupName = RandomGroupName()

				canOpen, _ := c.CanOpen(0)
				So(canOpen, ShouldBeFalse)
			})

			Convey("non participants can not open other group's group channel", func() {
				// create a new account
				owner := CreateAccountWithTest()
				account := CreateAccountWithTest()

				// create group channel
				c := NewChannel()
				c.CreatorId = owner.Id
				c.TypeConstant = Channel_TYPE_GROUP
				c.GroupName = RandomGroupName()
				So(c.Create(), ShouldBeNil)

				canOpen, _ := c.CanOpen(account.Id)
				So(canOpen, ShouldBeFalse)
			})

			Convey("non participants can not open other group's topic channel", func() {
				// create a new account
				owner := CreateAccountWithTest()
				account := CreateAccountWithTest()

				// create group channel
				c := NewChannel()
				c.CreatorId = owner.Id
				c.TypeConstant = Channel_TYPE_TOPIC
				c.GroupName = RandomGroupName()
				So(c.Create(), ShouldBeNil)

				canOpen, _ := c.CanOpen(account.Id)
				So(canOpen, ShouldBeFalse)
			})

			Convey("group members can open group channel", func() {
				// create a new account
				owner := CreateAccountWithTest()
				account := CreateAccountWithTest()

				// create group channel
				c := NewChannel()
				c.CreatorId = owner.Id
				c.TypeConstant = Channel_TYPE_GROUP
				c.GroupName = RandomGroupName()
				So(c.Create(), ShouldBeNil)

				// add new participant
				_, err := c.AddParticipant(account.Id)
				So(err, ShouldBeNil)

				canOpen, _ := c.CanOpen(account.Id)
				So(canOpen, ShouldBeTrue)
			})
		})
	})
}

func TestChannelAddParticipant(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		Convey("while testing adding participant to a channel", t, func() {

			Convey("channel should have id", func() {
				c := NewChannel()
				cp, err := c.AddParticipant(1231)
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrChannelIdIsNotSet)
				So(cp, ShouldBeNil)
			})

			Convey("channel should creator id", func() {
				c := NewChannel()
				c.Id = 123
				cp, err := c.AddParticipant(1231)
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrCreatorIdIsNotSet)
				So(cp, ShouldBeNil)
			})

			Convey("we can add creator to the pinned channel", func() {
				acc := CreateAccountWithTest()
				c := CreateTypedChannelWithTest(acc.Id, Channel_TYPE_PINNED_ACTIVITY)

				cp, err := c.AddParticipant(c.CreatorId)
				So(err, ShouldBeNil)
				So(cp, ShouldNotBeNil)
				So(cp.AccountId, ShouldEqual, c.CreatorId)
				So(cp.ChannelId, ShouldEqual, c.Id)
			})

			Convey("we can not add others to the pinned channel", func() {
				acc := CreateAccountWithTest()
				c := CreateTypedChannelWithTest(acc.Id, Channel_TYPE_PINNED_ACTIVITY)

				account := CreateAccountWithTest()
				cp, err := c.AddParticipant(account.Id)
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrCannotAddNewParticipantToPinnedChannel)
				So(cp, ShouldBeNil)
			})

			Convey("we can not add same user twice to channel", func() {
				acc := CreateAccountWithTest()
				c := CreateChannelWithTest(acc.Id)

				account := CreateAccountWithTest()
				cp, err := c.AddParticipant(account.Id)
				So(err, ShouldBeNil)
				So(cp, ShouldNotBeNil)
				// try to add it again
				cp, err = c.AddParticipant(account.Id)
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrAccountIsAlreadyInTheChannel)
				So(cp, ShouldBeNil)
			})

			Convey("we can add same user again after leaving the channel", func() {
				acc := CreateAccountWithTest()
				c := CreateChannelWithTest(acc.Id)
				cp, err := c.AddParticipant(acc.Id)
				So(err, ShouldBeNil)
				So(cp, ShouldNotBeNil)

				// force him to leave the channel
				So(cp.Delete(), ShouldBeNil)

				// try to add it again
				cp, err = c.AddParticipant(acc.Id)
				So(err, ShouldBeNil)
				So(cp, ShouldNotBeNil)
				So(cp.StatusConstant, ShouldEqual, ChannelParticipant_STATUS_ACTIVE)
			})
			Convey("we should not be able to add participants into linked channel", func() {
				account := CreateAccountWithTest()
				c := CreateTypedPublicChannelWithTest(
					account.Id,
					Channel_TYPE_LINKED_TOPIC,
				)

				cp, err := c.AddParticipant(account.Id)
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrChannelIsLinked)
				So(cp, ShouldBeNil)
			})
		})
	})
}

func TestChannelRemoveParticipant(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		Convey("while removing participant from a channel", t, func() {
			Convey("channel should have id", func() {
				c := NewChannel()
				err := c.removeParticipation(ChannelParticipant_STATUS_LEFT, 123)
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrChannelIdIsNotSet)
			})

			Convey("removing a non existent participant from the channel should not give error", func() {
				acc := CreateAccountWithTest()
				c := CreateChannelWithTest(acc.Id)

				err := c.removeParticipation(ChannelParticipant_STATUS_LEFT, acc.Id)
				So(err, ShouldBeNil)
			})

			Convey("participant can leave the channel", func() {
				acc := CreateAccountWithTest()
				c := CreateChannelWithTest(acc.Id)
				AddParticipantsWithTest(c.Id, acc.Id)

				err := c.removeParticipation(ChannelParticipant_STATUS_LEFT, acc.Id)
				So(err, ShouldBeNil)
			})

			Convey("when we remove already removed account again from the channel, it should not give err", func() {
				acc := CreateAccountWithTest()
				c := CreateChannelWithTest(acc.Id)
				AddParticipantsWithTest(c.Id, acc.Id)

				err := c.removeParticipation(ChannelParticipant_STATUS_LEFT, acc.Id)
				So(err, ShouldBeNil)
				// try to remove it again
				err = c.removeParticipation(ChannelParticipant_STATUS_LEFT, acc.Id)
				So(err, ShouldBeNil)
			})
		})
	})
}

func TestChannelAddMessage(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		Convey("while adding a message to a channel", t, func() {

			Convey("it should have channel id", func() {
				c := NewChannel()
				cm := NewChannelMessage()
				cm.Id = 123
				_, err := c.AddMessage(cm)
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrChannelIdIsNotSet)
			})

			Convey("it should have message id", func() {
				c := NewChannel()
				c.Id = 123
				_, err := c.AddMessage(NewChannelMessage())
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrMessageIdIsNotSet)
			})

			Convey("it should return error if message id is not set", func() {
				// fake channel
				c := NewChannel()
				c.Id = 123

				// try to add message
				ch, err := c.AddMessage(NewChannelMessage())
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrMessageIdIsNotSet)
				So(ch, ShouldBeNil)
			})

			Convey("adding message to a channel should be successful", func() {
				acc := CreateAccountWithTest()
				c := CreateChannelWithTest(acc.Id)

				cm := CreateMessageWithTest()
				cm.Body = "five5"
				So(cm.Create(), ShouldBeNil)
				ch, err := c.AddMessage(cm)
				So(err, ShouldBeNil)
				So(ch, ShouldNotBeEmpty)
			})

			Convey("it should return error if message is already in the channel", func() {
				acc := CreateAccountWithTest()
				c := CreateChannelWithTest(acc.Id)
				cm := CreateMessageWithTest()
				So(cm.Create(), ShouldBeNil)

				ch, err := c.AddMessage(cm)
				So(err, ShouldBeNil)
				So(ch, ShouldNotBeEmpty)

				// try to add the same message again
				ch, err = c.AddMessage(cm)
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrMessageAlreadyInTheChannel)
				So(ch, ShouldBeNil)
			})

			Convey("it should return clientRequestId in response when message is created with clientRequestId", func() {
				acc := CreateAccountWithTest()
				c := CreateChannelWithTest(acc.Id)

				cm := CreateMessageWithTest()
				cm.ClientRequestId = "ctf-123456"
				So(cm.Create(), ShouldBeNil)

				ch, err := c.AddMessage(cm)
				So(err, ShouldBeNil)
				So(ch, ShouldNotBeEmpty)
				So(ch.ClientRequestId, ShouldEqual, "ctf-123456")
			})
		})
	})
}

func TestChannelRemoveMessage(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		Convey("while removing a message from the channel", t, func() {

			Convey("it should have channel id", func() {
				c := NewChannel()
				_, err := c.RemoveMessage(123)
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrChannelIdIsNotSet)
			})

			Convey("it should have message id", func() {
				c := NewChannel()
				c.Id = 123
				_, err := c.RemoveMessage(0)
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrMessageIdIsNotSet)
			})

			Convey("removing message from the channel should ne successful", func() {
				acc := CreateAccountWithTest()

				c := CreateChannelWithTest(acc.Id)
				cm := CreateMessageWithTest()
				So(cm.Create(), ShouldBeNil)

				_, err := c.AddMessage(cm)
				So(err, ShouldBeNil)

				ch, err := c.RemoveMessage(cm.Id)
				So(err, ShouldBeNil)
				So(ch, ShouldNotBeEmpty)
			})

			Convey("it should return error if message is already removed from the channel", func() {
				acc := CreateAccountWithTest()

				c := CreateChannelWithTest(acc.Id)
				cm := CreateMessageWithTest()
				So(cm.Create(), ShouldBeNil)

				_, err := c.AddMessage(cm)
				So(err, ShouldBeNil)

				ch, err := c.RemoveMessage(cm.Id)
				So(err, ShouldBeNil)
				So(ch, ShouldNotBeEmpty)

				// try to remove the same message again
				ch, err = c.RemoveMessage(cm.Id)
				So(err, ShouldNotBeNil)
				So(ch, ShouldBeNil)
			})
		})
	})
}

func TestChannelFetchMessageList(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		Convey("while fetching channel message list", t, func() {
			Convey("it should have channel id", func() {
				c := NewChannel()
				_, err := c.FetchMessageList(123)
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrChannelIdIsNotSet)
			})

			Convey("it should have message id", func() {
				c := NewChannel()
				c.Id = 123
				_, err := c.FetchMessageList(0)
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrMessageIdIsNotSet)
			})

			Convey("non-existing message list should give error", func() {
				acc := CreateAccountWithTest()
				c := CreateChannelWithTest(acc.Id)

				// 1 is an arbitrary number
				_, err := c.FetchMessageList(1)
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, bongo.RecordNotFound)
			})

			Convey("existing message list should not give error", func() {
				acc := CreateAccountWithTest()
				c := CreateChannelWithTest(acc.Id)

				// create message
				cm := CreateMessageWithTest()
				So(cm.Create(), ShouldBeNil)

				// add message to the channel
				cml, err := c.AddMessage(cm)
				So(err, ShouldBeNil)
				So(cml, ShouldNotBeNil)

				// try to fetch persisted message
				cml2, err := c.FetchMessageList(cm.Id)
				So(err, ShouldBeNil)
				So(cml2, ShouldNotBeNil)
				So(cml2.MessageId, ShouldEqual, cm.Id)
			})
		})
	})
}

func TestChannelFetchChannelIdByNameAndGroupName(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		Convey("while fetching channel id by name & group name", t, func() {

			Convey("it should have a name", func() {
				c := NewChannel()
				fcid, err := c.FetchChannelIdByNameAndGroupName("", "groupName")
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrNameIsNotSet)
				So(fcid, ShouldEqual, 0)
			})

			Convey("it should have a group name", func() {
				c := NewChannel()
				fcid, err := c.FetchChannelIdByNameAndGroupName("name", "")
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrGroupNameIsNotSet)
				So(fcid, ShouldEqual, 0)
			})

			Convey("non-existing name & groupName should give error", func() {
				acc := CreateAccountWithTest()
				c := CreateChannelWithTest(acc.Id)

				// nameTest & groupNameTest are an arbitrary strings
				_, err := c.FetchChannelIdByNameAndGroupName("nameTest", "groupNameTest")
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, bongo.RecordNotFound)
			})

			Convey("Existing name & groupName should not give an error", func() {
				acc := CreateAccountWithTest()
				c := CreateChannelWithTest(acc.Id)

				// nameTest & groupNameTest are an arbitrary strings
				fcid, err := c.FetchChannelIdByNameAndGroupName(c.Name, c.GroupName)
				So(err, ShouldBeNil)
				So(fcid, ShouldNotBeNil)
				// Id of the FetchChannelIdByNameAndGroupName shoul equal to id which our created channel
				So(fcid, ShouldEqual, c.Id)
			})
		})
	})
}

func TestChannelFetchLastMessage(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		Convey("while fetching last message", t, func() {

			Convey("it should have channel id", func() {
				c := NewChannel()
				_, err := c.FetchLastMessage()
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrChannelIdIsNotSet)
			})

			Convey("existing just one message in the channel should not give error", func() {
				acc := CreateAccountWithTest()
				c := CreateChannelWithTest(acc.Id)

				// create message
				cm := CreateMessageWithTest()
				So(cm.Create(), ShouldBeNil)

				// add message to the channel
				cml, err := c.AddMessage(cm)
				So(err, ShouldBeNil)
				So(cml, ShouldNotBeNil)

				// try to fetch persisted message
				flm, err := c.FetchLastMessage()
				So(err, ShouldBeNil)
				So(flm, ShouldNotBeNil)
				So(flm.Body, ShouldEqual, cm.Body)
			})

			Convey("existing two message in the channel should give last message", func() {
				acc := CreateAccountWithTest()
				c := CreateChannelWithTest(acc.Id)

				// create message
				cm := CreateMessageWithTest()
				So(cm.Create(), ShouldBeNil)

				// add first message  to the channel
				cml, err := c.AddMessage(cm)
				So(err, ShouldBeNil)
				So(cml, ShouldNotBeNil)

				// create second message
				cm2 := CreateMessageWithTest()
				cm2.Body = "lastMessage"
				So(cm2.Create(), ShouldBeNil)

				// add second message to the same channel
				cml2, err := c.AddMessage(cm2)
				So(err, ShouldBeNil)
				So(cml2, ShouldNotBeNil)

				// try to fetch last message
				flm, err := c.FetchLastMessage()
				So(err, ShouldBeNil)
				So(flm, ShouldNotBeNil)
				So(flm.Body, ShouldEqual, cm2.Body)
			})

			Convey("non-existing message in channel should be nil", func() {
				acc := CreateAccountWithTest()
				c := CreateChannelWithTest(acc.Id)

				flm, err := c.FetchLastMessage()
				So(err, ShouldBeNil)
				So(flm, ShouldBeNil)
			})

			Convey("empty message id should be nil", func() {
				acc := CreateAccountWithTest()
				c := CreateChannelWithTest(acc.Id)

				// create message
				cm := CreateMessageWithTest()
				So(cm.Create(), ShouldBeNil)

				// add message  to channel
				cml, err := c.AddMessage(cm)
				So(err, ShouldBeNil)
				So(cml, ShouldNotBeNil)

				// after adding message, remove same massage
				// and message id in the channel should be nil
				ch, err := c.RemoveMessage(cm.Id)
				So(err, ShouldBeNil)
				So(ch, ShouldNotBeEmpty)

				flm, err := c.FetchLastMessage()
				So(err, ShouldBeNil)
				So(flm, ShouldBeNil)
			})
		})
	})
}

func TestChannelIsParticipant(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		Convey("while controlling participant is in the channel or not", t, func() {

			Convey("participant in the channel should not give error", func() {
				acc := CreateAccountWithTest()
				c := CreateChannelWithTest(acc.Id)

				// add the created account to the channel
				ap, err := c.AddParticipant(acc.Id)
				So(err, ShouldBeNil)
				So(ap, ShouldNotBeNil)

				part, err := c.IsParticipant(acc.Id)
				So(err, ShouldBeNil)
				So(part, ShouldBeTrue)
			})

			Convey("non-participant in the channel should not give error", func() {
				acc := CreateAccountWithTest()
				c := CreateChannelWithTest(acc.Id)

				// account is created but didn't add to the channel
				// it means that participant is not in the channel
				part, err := c.IsParticipant(acc.Id)
				So(err, ShouldBeNil)
				So(part, ShouldBeFalse)
			})
		})
	})
}

func TestChannelFetchParticipant(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		Convey("while fetching the participants from the channel", t, func() {

			Convey("it should have channel id", func() {
				c := NewChannel()
				_, err := c.FetchParticipant(123)
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrIdIsNotSet)
			})

			Convey("it should have account id", func() {
				c := NewChannel()
				c.Id = 123
				_, err := c.FetchParticipant(0)
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrAccountIdIsNotSet)
			})

			Convey("participant in the channel should not give error", func() {
				acc := CreateAccountWithTest()
				c := CreateChannelWithTest(acc.Id)

				// add account to the channel
				ap, err := c.AddParticipant(acc.Id)
				So(err, ShouldBeNil)
				So(ap, ShouldNotBeNil)

				fp, err := c.FetchParticipant(acc.Id)
				So(err, ShouldBeNil)
				So(fp, ShouldNotBeNil)
				So(fp.AccountId, ShouldEqual, acc.Id)
				So(fp.ChannelId, ShouldEqual, c.Id)
			})

			Convey("non-participant in the channel's status should be left after removing from channel ", func() {
				acc := CreateAccountWithTest()
				c := CreateChannelWithTest(acc.Id)

				// add account to the channel
				ap, err := c.AddParticipant(acc.Id)
				So(err, ShouldBeNil)
				So(ap, ShouldNotBeNil)
				//
				// remove participant from the channel
				err = c.RemoveParticipant(acc.Id)
				So(err, ShouldBeNil)

				// after adding and removing the user to/from channel
				// status constant should be LEFT from the channel
				// not deleted! frmo the channel
				fp, err := c.FetchParticipant(acc.Id)
				So(err, ShouldBeNil)
				So(fp, ShouldNotBeNil)
				So(fp.StatusConstant, ShouldEqual, ChannelParticipant_STATUS_LEFT)
			})
		})
	})
}

func TestChannelgetAccountId(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		Convey("while getting account id", t, func() {

			Convey("it should have channel id", func() {
				c := NewChannel()
				_, err := c.getAccountId()
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrChannelIdIsNotSet)
			})

			Convey("it should have creator id", func() {
				c := NewChannel()
				c.CreatorId = 123
				ac, err := c.getAccountId()
				So(err, ShouldBeNil)
				So(c.CreatorId, ShouldEqual, ac)
			})

			Convey("it should get id of creator", func() {
				acc := CreateAccountWithTest()
				c := CreateChannelWithTest(acc.Id)
				ac, err := c.getAccountId()
				So(err, ShouldBeNil)
				So(c.CreatorId, ShouldEqual, ac)
			})
		})
	})
}

func setupDeleteTest() (*Channel, *ChannelMessage, *ChannelMessage, *ChannelMessageList, *ChannelMessageList) {
	acc := CreateAccountWithTest()
	c := CreateChannelWithTest(acc.Id)

	// create some messages
	cm0 := CreateMessage(c.Id, acc.Id, ChannelMessage_TYPE_POST)
	cm1 := CreateMessage(c.Id, acc.Id, ChannelMessage_TYPE_POST)

	cml0, err := c.EnsureMessage(cm0, true)
	So(err, ShouldBeNil)

	cml1, err := c.EnsureMessage(cm1, true)
	So(err, ShouldBeNil)

	return c, cm0, cm1, cml0, cml1
}

func TestChannelDelete(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		Convey("when deleting a channel", t, func() {
			Convey("it should delete all messages of the channel", func() {
				c, cm0, cm1, _, _ := setupDeleteTest()

				// delete the channel
				So(c.Delete(), ShouldBeNil)

				// verify that the channel messages are deleted:
				err := NewChannelMessage().ById(cm0.Id)
				So(err, ShouldEqual, bongo.RecordNotFound)

				err = NewChannelMessage().ById(cm1.Id)
				So(err, ShouldEqual, bongo.RecordNotFound)

			})
			Convey("it should delete any associated ChannelMessageList records", func() {
				c, _, _, cml0, cml1 := setupDeleteTest()

				// delete the channel
				So(c.Delete(), ShouldBeNil)

				// verify that the channel message lists are deleted:
				err := NewChannelMessageList().ById(cml0.Id)
				So(err, ShouldEqual, bongo.RecordNotFound)

				err = NewChannelMessageList().ById(cml1.Id)
				So(err, ShouldEqual, bongo.RecordNotFound)
			})

			Convey("it should delete any participants", func() {
				c, _, _, _, _ := setupDeleteTest()

				// delete the channel
				So(c.Delete(), ShouldBeNil)

				participants, err := c.FetchParticipants(&request.Query{})
				So(err, ShouldBeNil)
				So(len(participants), ShouldEqual, 0)
			})

			Convey("it should delete the channel itself", func() {
				c, _, _, _, _ := setupDeleteTest()

				So(c.Delete(), ShouldBeNil)

				err := NewChannel().ById(c.Id)
				So(err, ShouldEqual, bongo.RecordNotFound)
			})
			Convey("it should not delete messages that are cross-indexed", func() {
				c0, cm0, cm1, _, _ := setupDeleteTest()

				acc := CreateAccountWithTest()
				c1 := CreateChannelWithTest(acc.Id)

				// only add the second message to the second channel:
				cml0, err := c1.AddMessage(cm1)
				So(err, ShouldBeNil)
				So(cml0, ShouldNotBeNil)

				// delete the first channel:
				So(c0.Delete(), ShouldBeNil)

				// verify that the first message is deleted:
				err = NewChannelMessage().ById(cm0.Id)
				So(err, ShouldEqual, bongo.RecordNotFound)

				// verify that the second message is not deleted:
				err = NewChannelMessage().ById(cm1.Id)
				So(err, ShouldBeNil)
			})
		})
	})
}

func TestFetchGroupChannel(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		Convey("when fetching a public channel", t, func() {
			creator := CreateAccountWithTest()

			c := NewChannel()
			c.TypeConstant = Channel_TYPE_GROUP
			c.GroupName = "test_group_" + RandomName()
			c.Name = "public"
			c.CreatorId = creator.Id
			err := c.Create()
			So(err, ShouldBeNil)
			Convey("it should return a public channel with given group name", func() {
				pc := NewChannel()
				err := pc.FetchGroupChannel(c.GroupName)
				So(err, ShouldBeNil)
				So(pc.GroupName, ShouldEqual, c.GroupName)
				So(pc.TypeConstant, ShouldEqual, Channel_TYPE_GROUP)
			})
		})
	})
}

func TestChannelByParticipants(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		appConfig := config.MustRead(r.Conf.Path)
		modelhelper.Initialize(appConfig.Mongo)
		defer modelhelper.Close()

		Convey("while fetching channels by their participants", t, func() {
			_, _, groupName := CreateRandomGroupDataWithChecks()

			Convey("group name should be set in query", func() {
				q := request.NewQuery()
				q.GroupName = ""

				c := NewChannel()
				_, err := c.ByParticipants([]int64{}, q)
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrGroupNameIsNotSet)
			})

			Convey("at least one participant should be passed", func() {
				q := request.NewQuery()
				q.GroupName = groupName

				c := NewChannel()
				_, err := c.ByParticipants([]int64{}, q)
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrChannelParticipantIsNotSet)
			})

			acc1 := CreateAccountWithTest()
			acc2 := CreateAccountWithTest()
			acc3 := CreateAccountWithTest()

			tc1 := CreateTypedGroupedChannelWithTest(
				acc1.Id,
				Channel_TYPE_TOPIC,
				groupName,
			)
			AddParticipantsWithTest(tc1.Id, acc1.Id, acc2.Id, acc3.Id)

			tc2 := CreateTypedGroupedChannelWithTest(
				acc1.Id,
				Channel_TYPE_TOPIC,
				groupName,
			)
			AddParticipantsWithTest(tc2.Id, acc1.Id, acc2.Id, acc3.Id)

			Convey("ordering should be working by channel created_at", func() {
				q := request.NewQuery()
				q.GroupName = groupName
				q.Type = Channel_TYPE_TOPIC

				c := NewChannel()
				channels, err := c.ByParticipants([]int64{acc1.Id, acc2.Id, acc3.Id}, q)
				So(err, ShouldBeNil)
				So(len(channels), ShouldEqual, 2)
				So(channels[0].Id, ShouldEqual, tc1.Id)
				So(channels[1].Id, ShouldEqual, tc2.Id)
			})

			Convey("skip options should be working", func() {
				q := request.NewQuery()
				q.GroupName = groupName
				q.Type = Channel_TYPE_TOPIC
				q.Skip = 1

				c := NewChannel()
				channels, err := c.ByParticipants([]int64{acc1.Id, acc2.Id, acc3.Id}, q)
				So(err, ShouldBeNil)
				So(len(channels), ShouldEqual, 1)
				So(channels[0].Id, ShouldEqual, tc2.Id)
			})

			Convey("limit options should be working", func() {
				q := request.NewQuery()
				q.GroupName = groupName
				q.Type = Channel_TYPE_TOPIC
				q.Limit = 1

				c := NewChannel()
				channels, err := c.ByParticipants([]int64{acc1.Id, acc2.Id, acc3.Id}, q)
				So(err, ShouldBeNil)
				So(len(channels), ShouldEqual, 1)
				So(channels[0].Id, ShouldEqual, tc1.Id)
			})

			Convey("type option should be working", func() {
				pc1 := CreateTypedGroupedChannelWithTest(
					acc1.Id,
					Channel_TYPE_PRIVATE_MESSAGE,
					groupName,
				)
				AddParticipantsWithTest(pc1.Id, acc1.Id, acc2.Id, acc3.Id)

				q := request.NewQuery()
				q.GroupName = groupName
				q.Type = Channel_TYPE_PRIVATE_MESSAGE

				c := NewChannel()
				channels, err := c.ByParticipants([]int64{acc1.Id, acc2.Id, acc3.Id}, q)
				So(err, ShouldBeNil)
				So(len(channels), ShouldEqual, 1)
				So(channels[0].Id, ShouldEqual, pc1.Id)
			})

			Convey("all channels should be active", func() {
				// delete the second channel
				So(tc2.Delete(), ShouldBeNil)

				q := request.NewQuery()
				q.GroupName = groupName
				q.Type = Channel_TYPE_TOPIC

				c := NewChannel()
				channels, err := c.ByParticipants([]int64{acc1.Id, acc2.Id, acc3.Id}, q)
				So(err, ShouldBeNil)
				So(len(channels), ShouldEqual, 1)
				So(channels[0].Id, ShouldEqual, tc1.Id)
			})

			Convey("all members should be active", func() {
				// delete the second participant from second channel
				So(tc2.RemoveParticipant(acc2.Id), ShouldBeNil)

				q := request.NewQuery()
				q.GroupName = groupName
				q.Type = Channel_TYPE_TOPIC

				c := NewChannel()
				channels, err := c.ByParticipants([]int64{acc1.Id, acc2.Id, acc3.Id}, q)
				So(err, ShouldBeNil)
				So(len(channels), ShouldEqual, 1)
				So(channels[0].Id, ShouldEqual, tc1.Id)
			})

			Convey("if the members are also in other groups", func() {
				Convey("group context should be working", func() {
					_, _, groupName := CreateRandomGroupDataWithChecks()

					tc1 := CreateTypedGroupedChannelWithTest(
						acc1.Id,
						Channel_TYPE_TOPIC,
						groupName,
					)
					AddParticipantsWithTest(tc1.Id, acc1.Id, acc2.Id, acc3.Id)

					tc2 := CreateTypedGroupedChannelWithTest(
						acc1.Id,
						Channel_TYPE_TOPIC,
						groupName,
					)
					AddParticipantsWithTest(tc2.Id, acc1.Id, acc2.Id, acc3.Id)

					q := request.NewQuery()
					q.GroupName = groupName
					q.Type = Channel_TYPE_TOPIC

					c := NewChannel()
					channels, err := c.ByParticipants([]int64{acc1.Id, acc2.Id, acc3.Id}, q)
					So(err, ShouldBeNil)
					So(len(channels), ShouldEqual, 2)
					So(channels[0].GroupName, ShouldEqual, groupName)
				})
			})
		})
	})
}
