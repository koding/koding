package models

import (
	"socialapi/workers/common/runner"
	"testing"

	"github.com/koding/bongo"
	. "github.com/smartystreets/goconvey/convey"
)

// createNewChannelWithTest creates a new account
// And inits a channel
func createNewChannelWithTest() *Channel {
	// init account
	creator := createAccountWithTest()

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

func TestChannelNewPrivateMessageChannel(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

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
			account := createAccountWithTest()
			c.CreatorId = account.Id
			So(c.Create(), ShouldBeNil)
			c.Id = 0
			So(c.Create(), ShouldBeNil)
		})

		Convey("calling group channel create twice should return same channel", func() {
			c := NewChannel()
			c.GroupName = "malitest2"
			c.TypeConstant = Channel_TYPE_GROUP
			account := createAccountWithTest()
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
			account := createAccountWithTest()
			c.CreatorId = account.Id
			So(c.Create(), ShouldBeNil)
			c.Id = 0
			So(c.Create(), ShouldBeNil)
		})

		Convey("calling followers channel create twice should return same channel", func() {
			c := NewChannel()
			c.TypeConstant = Channel_TYPE_FOLLOWERS
			account := createAccountWithTest()
			c.CreatorId = account.Id
			So(c.Create(), ShouldBeNil)
			firstChannel := c.Id
			c.Id = 0
			So(c.Create(), ShouldBeNil)
			So(firstChannel, ShouldEqual, c.Id)
		})

	})

}

func TestChannelTableName(t *testing.T) {
	Convey("while testing TableName()", t, func() {
		So(NewChannel().TableName(), ShouldEqual, ChannelTableName)
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

		Convey("uninitialized account can not open channel", func() {
			c := NewChannel()
			c.Id = 123
			c.CreatorId = 312
			canOpen, err := c.CanOpen(0)
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrAccountIdIsNotSet)
			So(canOpen, ShouldBeFalse)
		})

		Convey("participants can open group channel", func() {
			c := createNewChannelWithTest()
			c.TypeConstant = Channel_TYPE_GROUP

			So(c.Create(), ShouldBeNil)

			// create a new account
			account := createAccountWithTest()

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

			account := createAccountWithTest()

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

			account := createAccountWithTest()
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

			account := createAccountWithTest()
			canOpen, err := c.CanOpen(account.Id)
			So(err, ShouldBeNil)
			So(canOpen, ShouldBeTrue)
		})

		Convey("everyone can open topic channel", func() {
			c := createNewChannelWithTest()
			c.TypeConstant = Channel_TYPE_TOPIC

			So(c.Create(), ShouldBeNil)

			account := createAccountWithTest()
			canOpen, err := c.CanOpen(account.Id)
			So(err, ShouldBeNil)
			So(canOpen, ShouldBeTrue)
		})

		Convey("non - participants can not open pinned activity channel", func() {
			c := createNewChannelWithTest()
			c.TypeConstant = Channel_TYPE_PINNED_ACTIVITY

			So(c.Create(), ShouldBeNil)

			account := createAccountWithTest()
			canOpen, err := c.CanOpen(account.Id)
			So(err, ShouldBeNil)
			So(canOpen, ShouldBeFalse)
		})

		Convey("non-participants can not open private message channel", func() {
			c := createNewChannelWithTest()
			c.TypeConstant = Channel_TYPE_PRIVATE_MESSAGE

			So(c.Create(), ShouldBeNil)

			account := createAccountWithTest()
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
			account := createAccountWithTest()
			cp, err := c.AddParticipant(account.Id)
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrCannotAddNewParticipantToPinnedChannel)
			So(cp, ShouldBeNil)
		})

		Convey("we can not add same user twice to channel", func() {
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)
			account := createAccountWithTest()
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
			account := createAccountWithTest()
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
			account := createAccountWithTest()
			err := c.RemoveParticipant(account.Id)
			So(err, ShouldBeNil)
		})

		Convey("participant can leave the channel", func() {
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)
			account := createAccountWithTest()
			_, err := c.AddParticipant(account.Id)
			So(err, ShouldBeNil)

			err = c.RemoveParticipant(account.Id)
			So(err, ShouldBeNil)
		})

		Convey("when we remove already removed account again from the channel, it should not give err", func() {
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)
			account := createAccountWithTest()

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
			_, err := c.AddMessage(123)
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrChannelIdIsNotSet)
		})

		Convey("it should have message id", func() {
			c := NewChannel()
			c.Id = 123
			_, err := c.AddMessage(0)
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrMessageIdIsNotSet)
		})

		Convey("it should return error if message id is not set", func() {
			// fake channel
			c := NewChannel()
			c.Id = 123

			// try to add message
			ch, err := c.AddMessage(0)
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

			ch, err := c.AddMessage(cm.Id)
			So(err, ShouldBeNil)
			So(ch, ShouldNotBeEmpty)
		})

		Convey("it should return error if message is already in the channel", func() {
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)

			cm := createMessageWithTest()
			cm.Body = "five5"
			So(cm.Create(), ShouldBeNil)

			ch, err := c.AddMessage(cm.Id)
			So(err, ShouldBeNil)
			So(ch, ShouldNotBeEmpty)

			// try to add the same message again
			ch, err = c.AddMessage(cm.Id)
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrMessageAlreadyInTheChannel)
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

			_, err := c.AddMessage(cm.Id)
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

			_, err := c.AddMessage(cm.Id)
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
			cml, err := c.AddMessage(cm.Id)
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
			cml, err := c.AddMessage(cm.Id)
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
			cml, err := c.AddMessage(cm.Id)
			So(err, ShouldBeNil)
			So(cml, ShouldNotBeNil)

			// create second message
			cm2 := createMessageWithTest()
			cm2.Body = "lastMessage"
			So(cm2.Create(), ShouldBeNil)

			// add second message to the same channel
			cml2, err := c.AddMessage(cm2.Id)
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
			cml, err := c.AddMessage(cm.Id)
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

	Convey("while controlling participant is in channel", t, func() {

		Convey("participant in the channel should not give error", func() {
			// create channel
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)

			// create account
			acc := createAccountWithTest()
			So(acc.Create(), ShouldBeNil)

			ap, err := c.AddParticipant(acc.Id)
			So(err, ShouldBeNil)
			So(ap, ShouldNotBeNil)

			part, err := c.IsParticipant(acc.Id)
			So(err, ShouldBeNil)
			So(part, ShouldBeTrue)
		})

		Convey("non-participant in the channel should give error", func() {
			// create channel
			c := createNewChannelWithTest()
			So(c.Create(), ShouldBeNil)

			// create account
			acc := createAccountWithTest()
			So(acc.Create(), ShouldBeNil)

			part, err := c.IsParticipant(acc.Id)
			So(err, ShouldBeNil)
			So(part, ShouldBeFalse)
		})
	})
}
