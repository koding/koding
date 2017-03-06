package models

import (
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

			Convey("participants can open group channel", func() {
				acc := CreateAccountWithTest()
				c := CreateTypedChannelWithTest(acc.Id, Channel_TYPE_GROUP)

				AddParticipantsWithTest(c.Id, acc.Id)

				canOpen, err := c.CanOpen(acc.Id)
				So(err, ShouldBeNil)
				So(canOpen, ShouldBeTrue)
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

func TestChannelDelete(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		Convey("when deleting a channel", t, func() {
			Convey("it should delete any participants", func() {
				acc := CreateAccountWithTest()
				c := CreateChannelWithTest(acc.Id)
				// delete the channel
				So(c.Delete(), ShouldBeNil)

				participants, err := c.FetchParticipants(&request.Query{})
				So(err, ShouldBeNil)
				So(len(participants), ShouldEqual, 0)
			})

			Convey("it should delete the channel itself", func() {
				acc := CreateAccountWithTest()
				c := CreateChannelWithTest(acc.Id)

				So(c.Delete(), ShouldBeNil)

				err := NewChannel().ById(c.Id)
				So(err, ShouldEqual, bongo.RecordNotFound)
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
