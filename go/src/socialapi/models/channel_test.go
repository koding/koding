package models

import (
<<<<<<< HEAD
	"socialapi/models"
	"socialapi/config"
	"socialapi/request"
	"testing"

	"github.com/koding/bongo"
	"github.com/koding/runner"

	. "github.com/smartystreets/goconvey/convey"
)

// createNewChannelWithTest creates a new account
// And inits a channel
func createNewChannelWithTest() *Channel {
	// init account
	creator := CreateAccountWithTest()

	// init channel
	c := NewChannel()
	// set Creator id
	c.CreatorId = creator.Id
	return c
}

func TestChannelNewChannel(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

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
}

func TestChannelSearch(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	c := NewChannel()

	Convey("moderation needed channels", t, func() {
		account := CreateAccountWithTest()
		groupChannel := CreateTypedPublicChannelWithTest(
			account.Id,
			models.Channel_TYPE_GROUP,
		)

		c.CreatorId = account.Id
		c.GroupName = groupChannel.GroupName
		c.TypeConstant = Channel_TYPE_TOPIC
		c.PrivacyConstant = Channel_PRIVACY_PUBLIC
		c.MetaBits.Mark(NeedsModeration)

		So(c.Create(), ShouldBeNil)
		Convey("should not be in search results", func() {
			channels, err := NewChannel().Search(&request.Query{
				Name:      c.Name,
				GroupName: groupChannel.GroupName,
				AccountId: account.Id,
			})
			So(err, ShouldBeNil)
			So(len(channels), ShouldEqual, 0)
		})

		Convey("after removing needs moderation flag", func() {
			// byname doesnt filter
			channel, err := NewChannel().ByName(&request.Query{
				Name:      c.Name,
				GroupName: groupChannel.GroupName,
				AccountId: account.Id,
			})
			So(err, ShouldBeNil)
			So(channel, ShouldNotBeNil)

			channel.MetaBits.UnMark(NeedsModeration)

			So(channel.Update(), ShouldBeNil)

			Convey("we should be able to search them", func() {
				channels, err := NewChannel().Search(&request.Query{
					Name:      c.Name,
					GroupName: groupChannel.GroupName,
					AccountId: account.Id,
					Privacy:   channel.PrivacyConstant,
				})
				So(err, ShouldBeNil)
				So(len(channels), ShouldEqual, 1)
				So(channels[0].Id, ShouldEqual, channel.Id)
			})
		})
	})
}

func TestChannelNewCollaborationChannel(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

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
}

func TestChannelNewPrivateChannel(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

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
}

func TestChannelNewPrivateMessageChannel(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

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
}

// func createAccount()
func TestChannelCreate(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

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
}

func TestChannelBongoName(t *testing.T) {
	Convey("while testing BongoName()", t, func() {
		So(NewChannel().BongoName(), ShouldEqual, ChannelBongoName)
	})
}

func TestChannelCanOpen(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

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

		Convey("uninitialized account can open group channel", func() {
			c := NewChannel()
			c.Id = 123
			c.CreatorId = 312
			c.TypeConstant = Channel_TYPE_GROUP
			c.GroupName = Channel_KODING_NAME
			canOpen, err := c.CanOpen(0)
			So(err, ShouldBeNil)
			So(canOpen, ShouldBeTrue)
		})

		Convey("uninitialized account can open announcement channel", func() {
			c := NewChannel()
			c.Id = 123
			c.CreatorId = 312
			c.TypeConstant = Channel_TYPE_ANNOUNCEMENT
			canOpen, err := c.CanOpen(0)
			So(err, ShouldBeNil)
			So(canOpen, ShouldBeTrue)
		})

		Convey("participants can open group channel", func() {
			c := createNewChannelWithTest()
			c.TypeConstant = Channel_TYPE_GROUP

			So(c.Create(), ShouldBeNil)

			// create a new account
			account := CreateAccountWithTest()

			cp, err := c.AddParticipant(account.Id)
			So(err, ShouldBeNil)
			So(cp, ShouldNotBeNil)

			canOpen, err := c.CanOpen(account.Id)
			So(err, ShouldBeNil)
			So(canOpen, ShouldBeTrue)
		})

		Convey("participants can open topic channel", func() {
			c := createNewChannelWithTest()
			c.TypeConstant = Channel_TYPE_TOPIC

			So(c.Create(), ShouldBeNil)

			account := CreateAccountWithTest()

			cp, err := c.AddParticipant(account.Id)
			So(err, ShouldBeNil)
			So(cp, ShouldNotBeNil)

			canOpen, err := c.CanOpen(account.Id)
			So(err, ShouldBeNil)
			So(canOpen, ShouldBeTrue)
		})

		// pinned activity channel can only be opened by the creator
		Convey("participants can open pinned activity channel", func() {
			c := createNewChannelWithTest()
			c.TypeConstant = Channel_TYPE_PINNED_ACTIVITY

			So(c.Create(), ShouldBeNil)

			cp, err := c.AddParticipant(c.CreatorId)
			So(err, ShouldBeNil)
			So(cp, ShouldNotBeNil)

			canOpen, err := c.CanOpen(c.CreatorId)
			So(err, ShouldBeNil)
			So(canOpen, ShouldBeTrue)
		})

		Convey("participants can open private message channel", func() {
			c := createNewChannelWithTest()
			c.TypeConstant = Channel_TYPE_PRIVATE_MESSAGE

			So(c.Create(), ShouldBeNil)

			account := CreateAccountWithTest()
			// add participant to the channel
			cp, err := c.AddParticipant(account.Id)
			So(err, ShouldBeNil)
			So(cp, ShouldNotBeNil)

			canOpen, err := c.CanOpen(account.Id)
			So(err, ShouldBeNil)
			So(canOpen, ShouldBeTrue)
		})

		//
		// NON participant tests
		//
		Convey("everyone can open group channel", func() {
			c := createNewChannelWithTest()
			// set required constant to open chanel
			c.TypeConstant = Channel_TYPE_GROUP

			So(c.Create(), ShouldBeNil)

			account := CreateAccountWithTest()
			canOpen, err := c.CanOpen(account.Id)
			So(err, ShouldBeNil)
			So(canOpen, ShouldBeTrue)
		})

		Convey("everyone can open topic channel", func() {
			c := createNewChannelWithTest()
			c.TypeConstant = Channel_TYPE_TOPIC
			c.GroupName = Channel_KODING_NAME
			So(c.Create(), ShouldBeNil)

			account := CreateAccountWithTest()
			canOpen, err := c.CanOpen(account.Id)
			So(err, ShouldBeNil)
			So(canOpen, ShouldBeTrue)
		})

		Convey("non - participants can not open pinned activity channel", func() {
			c := createNewChannelWithTest()
			c.TypeConstant = Channel_TYPE_PINNED_ACTIVITY

			So(c.Create(), ShouldBeNil)

			account := CreateAccountWithTest()
			canOpen, err := c.CanOpen(account.Id)
			So(err, ShouldBeNil)
			So(canOpen, ShouldBeFalse)
		})

		Convey("non-participants can not open private message channel", func() {
			c := createNewChannelWithTest()
			c.TypeConstant = Channel_TYPE_PRIVATE_MESSAGE

			So(c.Create(), ShouldBeNil)

			account := CreateAccountWithTest()
			canOpen, err := c.CanOpen(account.Id)
			So(err, ShouldBeNil)
			So(canOpen, ShouldBeFalse)
		})
	})
}

func TestChannelAddParticipant(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

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
			c := createNewChannelWithTest()
			c.TypeConstant = Channel_TYPE_PINNED_ACTIVITY
			So(c.Create(), ShouldBeNil)
			cp, err := c.AddParticipant(c.CreatorId)
			So(err, ShouldBeNil)
			So(cp, ShouldNotBeNil)
			So(cp.AccountId, ShouldEqual, c.CreatorId)
			So(cp.ChannelId, ShouldEqual, c.Id)
		})

		Convey("we can not add others to the pinned channel", func() {
			c := createNewChannelWithTest()
			c.TypeConstant = Channel_TYPE_PINNED_ACTIVITY
			So(c.Create(), ShouldBeNil)
			account := CreateAccountWithTest()
			cp, err := c.AddParticipant(account.Id)
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrCannotAddNewParticipantToPinnedChannel)
			So(cp, ShouldBeNil)
		})

		Convey("we can not add same user twice to channel", func() {
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)
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
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)
			account := CreateAccountWithTest()
			cp, err := c.AddParticipant(account.Id)
			So(err, ShouldBeNil)
			So(cp, ShouldNotBeNil)

			// force him to leave the channel
			So(cp.Delete(), ShouldBeNil)

			// try to add it again
			cp, err = c.AddParticipant(account.Id)
			So(err, ShouldBeNil)
			So(cp, ShouldNotBeNil)
			So(cp.StatusConstant, ShouldEqual, ChannelParticipant_STATUS_ACTIVE)
		})
	})
}

func TestChannelRemoveParticipant(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("while removing participant from a channel", t, func() {
		Convey("channel should have id", func() {
			c := NewChannel()
			err := c.RemoveParticipant(123)
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrChannelIdIsNotSet)
		})

		Convey("removing a non existent participant from the channel should not give error", func() {
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)
			account := CreateAccountWithTest()
			err := c.RemoveParticipant(account.Id)
			So(err, ShouldBeNil)
		})

		Convey("participant can leave the channel", func() {
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)
			account := CreateAccountWithTest()
			_, err := c.AddParticipant(account.Id)
			So(err, ShouldBeNil)

			err = c.RemoveParticipant(account.Id)
			So(err, ShouldBeNil)
		})

		Convey("when we remove already removed account again from the channel, it should not give err", func() {
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)
			account := CreateAccountWithTest()

			_, err := c.AddParticipant(account.Id)
			So(err, ShouldBeNil)

			err = c.RemoveParticipant(account.Id)
			So(err, ShouldBeNil)
			// try to remove it again
			err = c.RemoveParticipant(account.Id)
			So(err, ShouldBeNil)
		})

	})
}

func TestChannelAddMessage(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

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
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)

			cm := createMessageWithTest()
			cm.Body = "five5"
			So(cm.Create(), ShouldBeNil)
			ch, err := c.AddMessage(cm)
			So(err, ShouldBeNil)
			So(ch, ShouldNotBeEmpty)
		})

		Convey("it should return error if message is already in the channel", func() {
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)

			cm := createMessageWithTest()
			cm.Body = "five5"
			So(cm.Create(), ShouldBeNil)

			ch, err := c.AddMessage(cm)
			So(err, ShouldBeNil)
			So(ch, ShouldNotBeEmpty)

			// try to add the same message again
			ch, err = c.AddMessage(cm)
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrMessageAlreadyInTheChannel)
		})

		Convey("it should return clientRequestId in response when message is created with clientRequestId", func() {
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)

			cm := createMessageWithTest()
			cm.Body = "five5"
			cm.ClientRequestId = "ctf-123456"
			So(cm.Create(), ShouldBeNil)

			ch, err := c.AddMessage(cm)
			So(err, ShouldBeNil)
			So(ch, ShouldNotBeEmpty)
			So(ch.ClientRequestId, ShouldEqual, "ctf-123456")
		})
	})
}

func TestChannelRemoveMessage(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

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
			// init channel
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)

			// init message & content of message
			cm := createMessageWithTest()
			cm.Body = "five5"
			So(cm.Create(), ShouldBeNil)

			_, err := c.AddMessage(cm)
			So(err, ShouldBeNil)

			ch, err := c.RemoveMessage(cm.Id)
			So(err, ShouldBeNil)
			So(ch, ShouldNotBeEmpty)
		})

		Convey("it should return error if message is already removed from the channel", func() {
			// init channel
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)

			// init channel message & set message content
			// then create the message in db
			cm := createMessageWithTest()
			cm.Body = "five5"
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
}

func TestChannelFetchMessageList(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

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
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)

			// 1 is an arbitrary number
			_, err := c.FetchMessageList(1)
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, bongo.RecordNotFound)
		})

		Convey("existing message list should not give error", func() {
			// create channel
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)

			// create message
			cm := createMessageWithTest()
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
}

func TestChannelFetchChannelIdByNameAndGroupName(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

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
			// create channel in db
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)

			// nameTest & groupNameTest are an arbitrary strings
			_, err := c.FetchChannelIdByNameAndGroupName("nameTest", "groupNameTest")
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, bongo.RecordNotFound)
		})

		Convey("Existing name & groupName should not give an error", func() {
			// create channel in db
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)

			// nameTest & groupNameTest are an arbitrary strings
			fcid, err := c.FetchChannelIdByNameAndGroupName(c.Name, c.GroupName)
			So(err, ShouldBeNil)
			So(fcid, ShouldNotBeNil)
			// Id of the FetchChannelIdByNameAndGroupName shoul equal to id which our created channel
			So(fcid, ShouldEqual, c.Id)
		})

	})
}

func TestChannelFetchLastMessage(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("while fetching last message", t, func() {

		Convey("it should have channel id", func() {
			c := NewChannel()
			_, err := c.FetchLastMessage()
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrChannelIdIsNotSet)
		})

		Convey("existing just one message in the channel should not give error", func() {
			// create channel
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)

			// create message
			cm := createMessageWithTest()
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
			// create channel
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)

			// create message
			cm := createMessageWithTest()
			So(cm.Create(), ShouldBeNil)

			// add first message  to the channel
			cml, err := c.AddMessage(cm)
			So(err, ShouldBeNil)
			So(cml, ShouldNotBeNil)

			// create second message
			cm2 := createMessageWithTest()
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
			// create channel in db
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)

			flm, err := c.FetchLastMessage()
			So(err, ShouldBeNil)
			So(flm, ShouldBeNil)
		})

		Convey("empty message id should be nil", func() {
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)

			// create message
			cm := createMessageWithTest()
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
}

func TestChannelIsParticipant(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("while controlling participant is in the channel or not", t, func() {

		Convey("participant in the channel should not give error", func() {
			// create channel
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)

			// create account
			acc := CreateAccountWithTest()
			So(acc.Create(), ShouldBeNil)

			// add the created account to the channel
			ap, err := c.AddParticipant(acc.Id)
			So(err, ShouldBeNil)
			So(ap, ShouldNotBeNil)

			part, err := c.IsParticipant(acc.Id)
			So(err, ShouldBeNil)
			So(part, ShouldBeTrue)
		})

		Convey("non-participant in the channel should not give error", func() {
			// create channel
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)

			// create account
			acc := CreateAccountWithTest()
			So(acc.Create(), ShouldBeNil)

			// account is created but didn't add to the channel
			// it means that participant is not in the channel
			part, err := c.IsParticipant(acc.Id)
			So(err, ShouldBeNil)
			So(part, ShouldBeFalse)
		})
	})
}

func TestChannelFetchParticipant(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

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
			// create channel
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)

			// create account
			acc := CreateAccountWithTest()
			So(acc.Create(), ShouldBeNil)

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
			// create channel
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)

			// create account
			acc := CreateAccountWithTest()
			So(acc.Create(), ShouldBeNil)

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
}

func TestChannelgetAccountId(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

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
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)
			ac, err := c.getAccountId()
			So(err, ShouldBeNil)
			So(c.CreatorId, ShouldEqual, ac)
		})
	})
}

func setupDeleteTest() (*Channel, *ChannelMessage, *ChannelMessage, *ChannelMessageList, *ChannelMessageList) {
	c := createNewChannelWithTest()
	So(c.Create(), ShouldBeNil)
	// create some messages
	cm0 := createMessageWithTest()
	So(cm0.Create(), ShouldBeNil)

	cm1 := createMessageWithTest()
	So(cm1.Create(), ShouldBeNil)

	// add cm0 and cm1:
	cml0, err := c.AddMessage(cm0)
	So(err, ShouldBeNil)
	So(cml0, ShouldNotBeNil)

	cml1, err := c.AddMessage(cm1)
	So(err, ShouldBeNil)
	So(cml1, ShouldNotBeNil)

	return c, cm0, cm1, cml0, cml1
}

func TestChannelDelete(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

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

			// create another channel:
			c1 := createNewChannelWithTest()
			So(c1.Create(), ShouldBeNil)

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
}

func TestFetchPublicChannel(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

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
			err := pc.FetchPublicChannel(c.GroupName)
			So(err, ShouldBeNil)
			So(pc.GroupName, ShouldEqual, c.GroupName)
			So(pc.TypeConstant, ShouldEqual, Channel_TYPE_GROUP)
		})
	})
}

func TestChannelFetchRoot(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("while fetching the root", t, func() {
		acc := models.CreateAccountWithTest()
		So(acc, ShouldNotBeNil)

		Convey("if channel id is not set", func() {
			c := NewChannel()
			_, err := c.FetchRoot()
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrIdIsNotSet)
		})

		Convey("when root doesnt exist", func() {
			leaf := models.CreateTypedGroupedChannelWithTest(
				acc.Id,
				models.Channel_TYPE_TOPIC,
				RandomName(),
			)

			Convey("should return bongo error", func() {
				_, err := leaf.FetchRoot()
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, bongo.RecordNotFound)
			})
		})

		Convey("when root does exist", func() {
			groupName := RandomName()
			root := models.CreateTypedGroupedChannelWithTest(
				acc.Id,
				models.Channel_TYPE_TOPIC,
				groupName,
			)

			leaf := models.CreateTypedGroupedChannelWithTest(
				acc.Id,
				models.Channel_TYPE_TOPIC,
				groupName,
			)

			cl := &ChannelLink{
				RootId: root.Id,
				LeafId: leaf.Id,
			}

			So(cl.Create(), ShouldBeNil)

			Convey("should return root", func() {
				r, err := leaf.FetchRoot()
				So(err, ShouldBeNil)
				So(r, ShouldNotBeNil)
				So(r.Id, ShouldEqual, root.Id)
			})
		})
	})
}

func TestChannelFetchLeaves(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("while fetching the root", t, func() {
		acc := models.CreateAccountWithTest()
		So(acc, ShouldNotBeNil)

		Convey("if channel id is not set", func() {
			c := NewChannel()
			_, err := c.FetchRoot()
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrIdIsNotSet)
		})

		Convey("when leaf doesnt exist", func() {
			root := models.CreateTypedGroupedChannelWithTest(
				acc.Id,
				models.Channel_TYPE_TOPIC,
				RandomName(),
			)

			Convey("should return bongo error", func() {
				leaves, err := root.FetchLeaves()
				So(err, ShouldBeNil)
				So(leaves, ShouldBeNil)
			})
		})

		Convey("when leaves does exist", func() {
			groupName := RandomName()
			root := models.CreateTypedGroupedChannelWithTest(
				acc.Id,
				models.Channel_TYPE_TOPIC,
				groupName,
			)

			leaf1 := models.CreateTypedGroupedChannelWithTest(
				acc.Id,
				models.Channel_TYPE_TOPIC,
				groupName,
			)

			cl := &ChannelLink{
				RootId: root.Id,
				LeafId: leaf1.Id,
			}

			So(cl.Create(), ShouldBeNil)

			leaf2 := models.CreateTypedGroupedChannelWithTest(
				acc.Id,
				models.Channel_TYPE_TOPIC,
				groupName,
			)

			cl = &ChannelLink{
				RootId: root.Id,
				LeafId: leaf2.Id,
			}

			So(cl.Create(), ShouldBeNil)

			Convey("should return its leaves", func() {
				leaves, err := root.FetchLeaves()
				So(err, ShouldBeNil)
				So(leaves, ShouldNotBeNil)
				So(len(leaves), ShouldEqual, 2)
			})
		})
	})
}
