package models

import (
	"fmt"
	"math/rand"
	"socialapi/request"
	"socialapi/workers/common/tests"
	"strconv"
	"testing"
	"time"

	"github.com/koding/bongo"
	"github.com/koding/runner"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelMessageCreate(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("while creating channel message", t, func() {
			Convey("0 length body could not be inserted ", func() {
				cm := NewChannelMessage()
				So(cm.Create(), ShouldNotBeNil)
				So(cm.Create().Error(), ShouldContainSubstring, "message body length should be greater than")
			})

			Convey("type constant should be given", func() {
				cm := CreateMessageWithTest()
				cm.TypeConstant = ""
				So(cm.Create(), ShouldNotBeNil)
				// complete error message is this: pq: invalid input value for enum channel_message_type_constant_enum: \"\"
				// it is trimmed because wercker add schema name and returns api.channel_message_type_constant_enum
				So(cm.Create().Error(), ShouldContainSubstring, "pq: invalid input value for enum")
			})

			Convey("type constant can be post", func() {
				cm := CreateMessageWithTest()
				// remove type Constant
				cm.TypeConstant = ChannelMessage_TYPE_POST

				So(cm.Create(), ShouldBeNil)

				icm := NewChannelMessage()
				err := icm.ById(cm.Id)
				So(err, ShouldBeNil)
				So(icm.Id, ShouldEqual, cm.Id)
				So(icm.TypeConstant, ShouldEqual, ChannelMessage_TYPE_POST)
			})

			Convey("type constant can be reply", func() {
				cm := CreateMessageWithTest()
				// remove type Constant
				cm.TypeConstant = ChannelMessage_TYPE_REPLY

				So(cm.Create(), ShouldBeNil)

				icm := NewChannelMessage()
				err := icm.ById(cm.Id)
				So(err, ShouldBeNil)
				So(icm.Id, ShouldEqual, cm.Id)
				So(icm.TypeConstant, ShouldEqual, ChannelMessage_TYPE_REPLY)
			})
			Convey("type constant can be join", func() {
				cm := CreateMessageWithTest()
				// remove type Constant
				cm.TypeConstant = ChannelMessage_TYPE_JOIN

				So(cm.Create(), ShouldBeNil)

				icm := NewChannelMessage()
				err := icm.ById(cm.Id)
				So(err, ShouldBeNil)
				So(icm.Id, ShouldEqual, cm.Id)
				So(icm.TypeConstant, ShouldEqual, ChannelMessage_TYPE_JOIN)
			})

			Convey("type constant can be leave", func() {
				cm := CreateMessageWithTest()
				// remove type Constant
				cm.TypeConstant = ChannelMessage_TYPE_LEAVE

				So(cm.Create(), ShouldBeNil)

				icm := NewChannelMessage()
				err := icm.ById(cm.Id)
				So(err, ShouldBeNil)
				So(icm.Id, ShouldEqual, cm.Id)
				So(icm.TypeConstant, ShouldEqual, ChannelMessage_TYPE_LEAVE)
			})

			Convey("type constant can be activity", func() {
				cm := CreateMessageWithTest()

				cm.TypeConstant = ChannelMessage_TYPE_SYSTEM

				So(cm.Create(), ShouldEqual, ErrSystemTypeIsNotSet)

				cm.SetPayload("systemType", "invite")

				So(cm.Create(), ShouldBeNil)

				icm := NewChannelMessage()
				err := icm.ById(cm.Id)
				So(err, ShouldBeNil)
				So(icm.Id, ShouldEqual, cm.Id)
				So(icm.TypeConstant, ShouldEqual, ChannelMessage_TYPE_SYSTEM)
			})

			Convey("type constant can be privatemessage", func() {
				cm := CreateMessageWithTest()
				// remove type Constant
				cm.TypeConstant = ChannelMessage_TYPE_PRIVATE_MESSAGE

				So(cm.Create(), ShouldBeNil)

				icm := NewChannelMessage()
				err := icm.ById(cm.Id)
				So(err, ShouldBeNil)
				So(icm.Id, ShouldEqual, cm.Id)
				So(icm.TypeConstant, ShouldEqual, ChannelMessage_TYPE_PRIVATE_MESSAGE)
			})

			Convey("5 length body could be inserted ", func() {
				cm := CreateMessageWithTest()
				// set body
				cm.Body = "5five"

				// try to create the message
				So(cm.Create(), ShouldBeNil)
			})

			Convey("message should have slug after inserting ", func() {
				// create message
				cm := CreateMessageWithTest()
				// be sure that our message doesnt have slug
				So(cm.Id, ShouldBeZeroValue)
				So(cm.Slug, ShouldBeZeroValue)
				// try to create the message
				So(cm.Create(), ShouldBeNil)
				So(cm.Id, ShouldNotEqual, 0)

				// fetch created message
				icm := NewChannelMessage()
				err := icm.ById(cm.Id)
				So(err, ShouldBeNil)
				So(icm.Id, ShouldNotEqual, 0)
				So(icm.Slug, ShouldNotEqual, "")
			})
		})
	})
}

func TestChannelMessageUpdate(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("while updating channel message", t, func() {
			Convey("0 length body could not be updated ", func() {
				cm := CreateMessageWithTest()
				So(cm.Create(), ShouldBeNil)

				// clear message body
				cm.Body = ""
				So(cm.Update(), ShouldNotBeEmpty)
				So(cm.Update().Error(), ShouldContainSubstring, "message body length should be greater than")
			})

			Convey("valid length body can be updated", func() {
				// create message in the db
				cm := CreateMessageWithTest()
				So(cm.Create(), ShouldBeNil)

				// update the db
				body := "my updated text"

				// clear message body
				cm.Body = body
				So(cm.Update(), ShouldBeEmpty)

				// fetch createed/updated message from db
				icm := NewChannelMessage()
				err := icm.ById(cm.Id)
				So(err, ShouldBeNil)
				So(icm.Body, ShouldEqual, body)
			})

			Convey("meta bits can not be updated", nil)

			Convey("token can not  be updated ", func() {
				// create message in the db
				cm := CreateMessageWithTest()
				So(cm.Create(), ShouldBeNil)

				// update the db
				token := NewToken(time.Now()).String()

				// clear message body
				cm.Token = token

				err := cm.Update()
				So(err, ShouldBeNil)

				// fetch created/updated message from db
				icm := NewChannelMessage()
				err = icm.ById(cm.Id)
				So(err, ShouldBeNil)
				So(icm.Token, ShouldNotEqual, token)
			})

			Convey("slug can not be updated", func() {
				// message is created in db
				cm := CreateMessageWithTest()
				So(cm.Slug, ShouldBeZeroValue)
				So(cm.Create(), ShouldBeNil)
				So(cm.Slug, ShouldNotEqual, "")

				// invoke a new slug
				slug := "another-test-for-slug"
				cm.Slug = slug

				// update the message
				// updating channel message will assign defaults
				err := cm.Update()
				So(err, ShouldBeNil)

				icm := NewChannelMessage()
				err = icm.ById(cm.Id)
				So(err, ShouldBeNil)
				So(icm.Slug, ShouldNotEqual, slug)
			})

			Convey("typeConstant can not be updated", func() {
				// message is created in db
				cm := CreateMessageWithTest()
				So(cm.Create(), ShouldBeNil)
				So(cm.TypeConstant, ShouldNotEqual, "")

				cm.TypeConstant = ChannelMessage_TYPE_JOIN

				// update the message
				// updating channel message will assign defaults
				err := cm.Update()
				So(err, ShouldBeNil)

				icm := NewChannelMessage()
				err = icm.ById(cm.Id)
				So(err, ShouldBeNil)
				So(icm.TypeConstant, ShouldNotEqual, ChannelMessage_TYPE_JOIN)
			})

			Convey("AccountId can not be updated", func() {
				// message is created in db
				cm := CreateMessageWithTest()
				So(cm.Create(), ShouldBeNil)
				So(cm.AccountId, ShouldNotEqual, 0)

				accId := cm.AccountId + 1
				cm.AccountId = accId

				// update the message
				// updating channel message will assign defaults
				err := cm.Update()
				So(err, ShouldBeNil)

				icm := NewChannelMessage()
				err = icm.ById(cm.Id)
				So(err, ShouldBeNil)
				So(icm.AccountId, ShouldNotEqual, accId)
			})

			Convey("InitialChannelId can not be updated", func() {
				// message is created in db
				cm := CreateMessageWithTest()
				So(cm.Create(), ShouldBeNil)
				So(cm.InitialChannelId, ShouldNotEqual, 0)

				cId := cm.InitialChannelId + 1
				cm.InitialChannelId = cId

				// update the message
				// updating channel message will assign defaults
				err := cm.Update()
				So(err, ShouldBeNil)

				icm := NewChannelMessage()
				err = icm.ById(cm.Id)
				So(err, ShouldBeNil)
				So(icm.InitialChannelId, ShouldNotEqual, cId)
			})

			Convey("CreatedAt can not be updated", func() {
				// message is created in db
				cm := CreateMessageWithTest()
				So(cm.Create(), ShouldBeNil)
				So(cm.CreatedAt, ShouldNotBeEmpty)

				timeNow := time.Now()
				cm.CreatedAt = timeNow

				// update the message
				// updating channel message will assign defaults
				err := cm.Update()
				So(err, ShouldBeNil)

				icm := NewChannelMessage()
				err = icm.ById(cm.Id)
				So(err, ShouldBeNil)
				So(icm.CreatedAt, ShouldNotEqual, timeNow)
			})

			Convey("Join/Leave message can not be updated", func() {
				// message is created in db
				cm := CreateMessageWithTest()
				cm.TypeConstant = ChannelMessage_TYPE_JOIN

				So(cm.Create(), ShouldBeNil)
				So(cm.CreatedAt, ShouldNotBeEmpty)

				cm.Body = "join me"
				err := cm.Update()
				So(err, ShouldEqual, ErrChannelMessageUpdatedNotAllowed)

				cm = CreateMessageWithTest()
				cm.TypeConstant = ChannelMessage_TYPE_LEAVE

				So(cm.Create(), ShouldBeNil)
				So(cm.CreatedAt, ShouldNotBeEmpty)

				cm.Body = "leave me"
				err = cm.Update()
				So(err, ShouldEqual, ErrChannelMessageUpdatedNotAllowed)
			})
		})
	})
}

func TestChannelMessageGetBongoName(t *testing.T) {
	Convey("while testing BongoName()", t, func() {
		So(NewChannelMessage().BongoName(), ShouldEqual, ChannelMessageBongoName)
	})
}

func TestChannelMessageGetAccountId(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("while getting account id ", t, func() {
			Convey("it should have channel id", func() {
				cm := NewChannelMessage()

				_, err := cm.getAccountId()
				So(err, ShouldNotBeNil)
				So(err.Error(), ShouldContainSubstring, "couldnt find accountId from content")
			})

			Convey("it should have error if account is not set", func() {
				cm := NewChannelMessage()
				cm.Id = 13531

				_, err := cm.getAccountId()
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, bongo.RecordNotFound)
			})

			Convey("it should not have error if channel & account are exist", func() {
				cm := NewChannelMessage()
				cm.Id = 2454
				cm.AccountId = 4353

				gid, err := cm.getAccountId()
				So(err, ShouldBeNil)
				So(gid, ShouldEqual, cm.AccountId)
			})
		})
	})
}

func TestChannelMessageBodyLenCheck(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("while checking body length", t, func() {
			Convey("it should have error if body length is zero", func() {
				cm := CreateMessageWithTest()
				cm.Body = ""

				err := bodyLenCheck(cm.Body)
				So(err, ShouldNotBeNil)
				So(err.Error(), ShouldContainSubstring, "message body length should be greater than")
			})

			Convey("it should not have error if length of body is greater than zero ", func() {
				cm := CreateMessageWithTest()
				cm.Body = "message"

				err := bodyLenCheck(cm.Body)
				So(err, ShouldBeNil)
			})
		})
	})
}

func TestChannelMessageBuildEmptyMessageContainer(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("while building empty message container", t, func() {
			Convey("it should have channel message id", func() {
				c := NewChannelMessage()

				_, err := c.BuildEmptyMessageContainer()
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrChannelMessageIdIsNotSet)
			})

			Convey("it should not have error if chanel is exist", func() {
				// create message
				c := CreateMessageWithTest()
				So(c.Create(), ShouldBeNil)

				bem, err := c.BuildEmptyMessageContainer()
				So(err, ShouldBeNil)
				So(bem.Message, ShouldEqual, c)
			})
			Convey("it should not return error when account is not set", func() {
				// create message
				c := CreateMessageWithTest()
				So(c.Create(), ShouldBeNil)

				cm := NewChannelMessage()
				cm.Id = c.Id

				bem, err := cm.BuildEmptyMessageContainer()
				So(err, ShouldBeNil)
				So(bem.Message, ShouldEqual, cm)
			})
		})
	})
}

func TestChannelMessageFetchLatestMessages(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("while fetching latest messages of a channel with three participants and four messages", t, func() {
			channel, accounts := CreateChannelWithParticipants()
			cm1 := CreateMessage(channel.Id, accounts[0].Id, ChannelMessage_TYPE_PRIVATE_MESSAGE)
			cm2 := CreateMessage(channel.Id, accounts[1].Id, ChannelMessage_TYPE_PRIVATE_MESSAGE)
			cm3 := CreateMessage(channel.Id, accounts[0].Id, ChannelMessage_TYPE_PRIVATE_MESSAGE)
			cm4 := CreateMessage(channel.Id, accounts[0].Id, ChannelMessage_TYPE_PRIVATE_MESSAGE)

			query := request.NewQuery()
			query.Limit = 3
			query.AddSortField("CreatedAt", request.ORDER_DESC)
			query.Type = ChannelMessage_TYPE_PRIVATE_MESSAGE

			Convey("first user should see last three messages when no parameters are set", func() {
				c := NewChannelMessage()
				cms, err := c.FetchMessagesByChannelId(channel.Id, query)
				So(err, ShouldBeNil)
				So(len(cms), ShouldEqual, 3)
				So(cms[2].Id, ShouldEqual, cm2.Id)
			})

			Convey("first user should see one message when their account id is excluded", func() {
				query.ExcludeField("AccountId", cm1.AccountId)
				c := NewChannelMessage()
				cms, err := c.FetchMessagesByChannelId(channel.Id, query)
				So(err, ShouldBeNil)
				So(len(cms), ShouldEqual, 1)
				So(cms[0].Id, ShouldEqual, cm2.Id)
			})

			Convey("second user should see two messages starting with their own message", func() {
				c := NewChannelMessage()
				query.ExcludeField("AccountId", cm2.AccountId)
				query.From = cm2.CreatedAt

				cms, err := c.FetchMessagesByChannelId(channel.Id, query)
				So(err, ShouldBeNil)
				So(len(cms), ShouldEqual, 2)
				So(cms[0].Id, ShouldEqual, cm4.Id)
				So(cms[1].Id, ShouldEqual, cm3.Id)
			})

			Convey("third user should see three messages when all parameters are set", func() {
				c := NewChannelMessage()
				query.ExcludeField("AccountId", accounts[2].Id)
				query.From = cm1.CreatedAt

				cms, err := c.FetchMessagesByChannelId(channel.Id, query)
				So(err, ShouldBeNil)
				So(len(cms), ShouldEqual, 3)
				So(cms[0].Id, ShouldEqual, cm4.Id)
				So(cms[1].Id, ShouldEqual, cm3.Id)
				So(cms[2].Id, ShouldEqual, cm2.Id)
			})
		})
	})
}

func TestChannelMessageFetchMessageCount(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("while fetching message count since the given time", t, func() {
			channel, accounts := CreateChannelWithParticipants()
			cm1 := CreateMessage(channel.Id, accounts[0].Id, ChannelMessage_TYPE_PRIVATE_MESSAGE)
			CreateMessage(channel.Id, accounts[1].Id, ChannelMessage_TYPE_PRIVATE_MESSAGE)
			CreateMessage(channel.Id, accounts[0].Id, ChannelMessage_TYPE_PRIVATE_MESSAGE)
			CreateMessage(channel.Id, accounts[0].Id, ChannelMessage_TYPE_PRIVATE_MESSAGE)

			query := request.NewQuery()
			query.Type = ChannelMessage_TYPE_PRIVATE_MESSAGE
			query.GroupChannelId = channel.Id
			query.From = cm1.CreatedAt

			Convey("first user should see 4 messages when their account is not excluded", func() {
				c := NewChannelMessage()
				count, err := c.FetchTotalMessageCount(query)
				So(err, ShouldBeNil)
				So(count, ShouldEqual, 4)
			})

			Convey("second user should see 3 messages then their account is excluded", func() {
				c := NewChannelMessage()
				query.ExcludeField("AccountId", accounts[1].Id)
				count, err := c.FetchTotalMessageCount(query)
				So(err, ShouldBeNil)
				So(count, ShouldEqual, 3)
			})
		})
	})
}

func TestChannelMessageFetchParentChannel(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("we should be able to fetch message's parent channel", t, func() {
			var accountId int64
			accountId = 3

			channel := NewChannel()
			channel.CreatorId = accountId

			Convey("When channel type is not topic, fetch the initial channel of the message as parent", func() {
				channel.TypeConstant = Channel_TYPE_PRIVATE_MESSAGE
				err := channel.Create()
				So(err, ShouldBeNil)
				cm := CreateMessage(channel.Id, accountId, Channel_TYPE_PRIVATE_MESSAGE)
				parentChannel, err := cm.FetchParentChannel()
				So(err, ShouldBeNil)
				So(parentChannel.Id, ShouldEqual, channel.Id)
			})

			Convey("When channel type is topic, group channel must be fetched", func() {
				rand.Seed(time.Now().UnixNano())
				groupName := "groupie-" + strconv.Itoa(rand.Intn(10e9))

				channel.TypeConstant = Channel_TYPE_TOPIC
				channel.GroupName = groupName
				err := channel.Create()
				So(err, ShouldBeNil)

				groupChannel := NewChannel()
				groupChannel.GroupName = groupName
				groupChannel.TypeConstant = Channel_TYPE_GROUP
				groupChannel.CreatorId = 4
				err = groupChannel.Create()
				So(err, ShouldBeNil)

				cm := CreateMessage(channel.Id, accountId, ChannelMessage_TYPE_POST)
				parentChannel, err := cm.FetchParentChannel()
				So(err, ShouldBeNil)
				So(parentChannel.Id, ShouldEqual, groupChannel.Id)
			})
		})
	})
}

func TestChannelMessageAddReply(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {

		Convey("while adding reply message", t, func() {

			Convey("channel message should have an id", func() {
				chm := NewChannelMessage()
				cm, err := chm.AddReply(chm)
				So(err, ShouldNotBeNil)
				So(err, ShouldEqual, ErrChannelMessageIdIsNotSet)
				So(cm, ShouldBeNil)
			})

			Convey("channel message id should equal to reply message id ", func() {
				c := CreateMessageWithTest()
				So(c.Create(), ShouldBeNil)
				c2 := CreateMessageWithTest()
				So(c2.Create(), ShouldBeNil)
				cm, err := c.AddReply(c2)
				So(err, ShouldBeNil)
				So(cm.MessageId, ShouldEqual, c.Id)
			})
		})
	})
}

func TestChannelMessagePayload(t *testing.T) {
	Convey("while accessing payload ", t, func() {

		Convey("channel message payload update operations should be functional", func() {
			cm := NewChannelMessage()
			cm.SetPayload("hey", "hov")
			So(*cm.Payload["hey"], ShouldEqual, "hov")

			cm.SetPayload("hey", "hovva")
			So(*cm.Payload["hey"], ShouldEqual, "hovva")
		})

		Convey("channel message payload fetch operations should be functional", func() {
			cm := NewChannelMessage()
			val := cm.GetPayload("hey")
			So(val, ShouldBeNil)

			cm.SetPayload("hey", "hov")
			val = cm.GetPayload("hey")
			So(*val, ShouldEqual, "hov")

			val = cm.GetPayload("heya")
			So(val, ShouldBeNil)
		})

	})
}

func TestChannelMesssageMentionRegex(t *testing.T) {
	Convey("while getting user name with regular expression ", t, func() {

		Convey("mentioned name can contain only numbers in body message", func() {
			user := "@123456"
			body := fmt.Sprintf("Hi my name is %s only numbers!!", user)
			name := mentionRegex.FindAllStringSubmatch(body, -1)

			So(name, ShouldNotBeNil)
			So(name[0], ShouldNotBeNil)
			So(len(name[0]), ShouldBeGreaterThan, 0)
			So(len(name), ShouldBeGreaterThan, 0)
			So(name[0][0], ShouldEqual, user)
		})

		Convey("mentioned name can be at the end of the line", func() {
			user := "@mehmetali"
			body := fmt.Sprintf("Hi my name is %s", user)
			name := mentionRegex.FindAllStringSubmatch(body, -1)

			So(name, ShouldNotBeNil)
			So(name[0], ShouldNotBeNil)
			So(len(name[0]), ShouldBeGreaterThan, 0)
			So(len(name), ShouldBeGreaterThan, 0)
			So(name[0][0], ShouldEqual, user)
		})

		Convey("mentioned name can be at the beginning of the line", func() {
			user := "@mehmetali"
			body := fmt.Sprintf("%s Hi my name is ", user)
			name := mentionRegex.FindAllStringSubmatch(body, -1)

			So(name, ShouldNotBeNil)
			So(name[0], ShouldNotBeNil)
			So(len(name[0]), ShouldBeGreaterThan, 0)
			So(len(name), ShouldBeGreaterThan, 0)
			So(name[0][0], ShouldEqual, user)
		})

		Convey("mentioned name can be any word or number", func() {
			user := "@mehmetali123"
			body := fmt.Sprintf("Hi my name is %s ", user)
			name := mentionRegex.FindAllStringSubmatch(body, -1)

			So(name, ShouldNotBeNil)
			So(name[0], ShouldNotBeNil)
			So(len(name[0]), ShouldBeGreaterThan, 0)
			So(len(name), ShouldBeGreaterThan, 0)
			So(name[0][0], ShouldEqual, user)
		})

		Convey("mentioned name can be any number word ", func() {
			user := "@123mehmetali"
			body := fmt.Sprintf("Hi my name is %s ", user)
			name := mentionRegex.FindAllStringSubmatch(body, -1)

			So(name, ShouldNotBeNil)
			So(name[0], ShouldNotBeNil)
			So(len(name[0]), ShouldBeGreaterThan, 0)
			So(len(name), ShouldBeGreaterThan, 0)
			So(name[0][0], ShouldEqual, user)
		})

		Convey("mentioned name can be any word or symbol ", func() {
			user := "@mehmet-ali"
			body := fmt.Sprintf("Hi my name is %s ", user)
			name := mentionRegex.FindAllStringSubmatch(body, -1)

			So(name, ShouldNotBeNil)
			So(name[0], ShouldNotBeNil)
			So(len(name[0]), ShouldBeGreaterThan, 0)
			So(len(name), ShouldBeGreaterThan, 0)
			So(name[0][0], ShouldEqual, user)
		})

		Convey("mentioned name can be any word & symbol & number ", func() {
			user := "@mehmet-ali1"
			body := fmt.Sprintf("Hi my name is %s ", user)
			name := mentionRegex.FindAllStringSubmatch(body, -1)

			So(name, ShouldNotBeNil)
			So(name[0], ShouldNotBeNil)
			So(len(name[0]), ShouldBeGreaterThan, 0)
			So(len(name), ShouldBeGreaterThan, 0)
			So(name[0][0], ShouldEqual, user)
		})

		Convey("mentioned name can contain dot", func() {
			user := "@mehmet.ali1"
			body := fmt.Sprintf("Hi my name is %s ", user)
			name := mentionRegex.FindAllStringSubmatch(body, -1)

			So(name, ShouldNotBeNil)
			So(name[0], ShouldNotBeNil)
			So(len(name[0]), ShouldBeGreaterThan, 0)
			So(len(name), ShouldBeGreaterThan, 0)
			So(name[0][0], ShouldEqual, user)
		})

		Convey("mentioned name can contain underscore", func() {
			user := "@mehmet_ali1"
			body := fmt.Sprintf("Hi my name is %s ", user)
			name := mentionRegex.FindAllStringSubmatch(body, -1)

			So(name, ShouldNotBeNil)
			So(name[0], ShouldNotBeNil)
			So(len(name[0]), ShouldBeGreaterThan, 0)
			So(len(name), ShouldBeGreaterThan, 0)
			So(name[0][0], ShouldEqual, user)
		})

		Convey("mentioned name can contain combination numbers&symbols", func() {
			user := "@mehmet1-1ali1"
			body := fmt.Sprintf("Hi my name is %s ", user)
			name := mentionRegex.FindAllStringSubmatch(body, -1)

			So(name, ShouldNotBeNil)
			So(name[0], ShouldNotBeNil)
			So(len(name[0]), ShouldBeGreaterThan, 0)
			So(len(name), ShouldBeGreaterThan, 0)
			So(name[0][0], ShouldEqual, user)
		})

		Convey("mentioned names can be more than 1 in the body", func() {
			user := "@mehmet1-1ali1"
			user2 := "@testerMehmetAli"
			body := fmt.Sprintf("Hi my name is %s and %s ", user, user2)
			name := mentionRegex.FindAllStringSubmatch(body, -1)

			So(name, ShouldNotBeNil)
			So(name[0], ShouldNotBeNil)
			So(len(name[0]), ShouldBeGreaterThan, 1)
			So(len(name), ShouldBeGreaterThan, 1)
			So(name[0][0], ShouldEqual, user)
			So(name[1][0], ShouldEqual, user2)
		})

	})
}
