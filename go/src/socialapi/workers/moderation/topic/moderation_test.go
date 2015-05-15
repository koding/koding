package topic

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"math"

	"socialapi/config"
	"socialapi/models"
	"socialapi/request"
	"socialapi/rest"
	"testing"

	"github.com/koding/runner"

	"github.com/koding/bongo"
	. "github.com/smartystreets/goconvey/convey"
)

func TestProcess(t *testing.T) {
	r := runner.New("test-moderation-blacklist")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	Convey("given a controller", t, func() {

		controller := NewController(r.Log, appConfig)

		Convey("controller should be set", func() {
			So(controller, ShouldNotBeNil)
		})

		Convey("should return nil when given nil channel link request", func() {
			So(controller.process(nil), ShouldBeNil)
		})

		Convey("should return nil when channel id given 0", func() {
			So(controller.process(models.NewChannelLink()), ShouldBeNil)
		})

		Convey("non existing channel should not give error", func() {
			a := models.NewChannelLink()
			a.Id = math.MaxInt64
			So(controller.process(a), ShouldBeNil)
		})

		acc1 := models.CreateAccountWithTest()
		acc2 := models.CreateAccountWithTest()

		Convey("should process 0 participated channels with no messages", func() {
			cl := models.CreateChannelLinkWithTest(acc1.Id, acc2.Id)
			So(controller.process(cl), ShouldBeNil)

			Convey("leaf node should not have any participants", func() {
				cp := models.NewChannelParticipant()
				cp.ChannelId = cl.LeafId
				cpc, err := cp.FetchParticipantCount()

				So(err, ShouldBeNil)
				So(cpc, ShouldEqual, 0)
			})

			Convey("root node should have 0 participants", func() {
				cp := models.NewChannelParticipant()
				cp.ChannelId = cl.RootId
				cpc, err := cp.FetchParticipantCount()

				So(err, ShouldBeNil)
				So(cpc, ShouldEqual, 0)
			})
		})

		Convey("should process 0 participated channels with messages", func() {
			groupName := models.RandomGroupName()

			root := models.CreateTypedGroupedChannelWithTest(acc1.Id, models.Channel_TYPE_TOPIC, groupName)
			leaf := models.CreateTypedGroupedChannelWithTest(acc2.Id, models.Channel_TYPE_TOPIC, groupName)
			// add participants with tests
			// models.AddParticipants(leaf.Id, acc1.Id, acc2.Id)

			// create a message to the regarding leaf channel
			models.CreateMessage(leaf.Id, acc1.Id, models.ChannelMessage_TYPE_POST)
			models.CreateMessage(leaf.Id, acc1.Id, models.ChannelMessage_TYPE_POST)
			models.CreateMessage(leaf.Id, acc1.Id, models.ChannelMessage_TYPE_POST)

			cl := &models.ChannelLink{
				RootId: root.Id,
				LeafId: leaf.Id,
			}

			So(controller.process(cl), ShouldBeNil)

			Convey("leaf node should not have any participants", func() {
				cp := models.NewChannelParticipant()
				cp.ChannelId = leaf.Id
				cpc, err := cp.FetchParticipantCount()

				So(err, ShouldBeNil)
				So(cpc, ShouldEqual, 0)

			})

			Convey("root node should not have any participants", func() {
				cp := models.NewChannelParticipant()
				cp.ChannelId = root.Id
				cpc, err := cp.FetchParticipantCount()

				So(err, ShouldBeNil)
				So(cpc, ShouldEqual, 0)
			})
		})

		Convey("should process participated channels with no messages", func() {
			groupName := models.RandomGroupName()

			root := models.CreateTypedGroupedChannelWithTest(acc1.Id, models.Channel_TYPE_TOPIC, groupName)
			leaf := models.CreateTypedGroupedChannelWithTest(acc2.Id, models.Channel_TYPE_TOPIC, groupName)
			// add participants with tests
			models.AddParticipants(leaf.Id, acc1.Id, acc2.Id)

			cp := models.NewChannelParticipant()
			cp.ChannelId = leaf.Id
			cpc, err := cp.FetchParticipantCount()
			So(err, ShouldBeNil)
			So(cpc, ShouldEqual, 2)

			cl := &models.ChannelLink{
				RootId: root.Id,
				LeafId: leaf.Id,
			}

			So(controller.process(cl), ShouldBeNil)

			Convey("leaf node should not have any participants", func() {
				cp := models.NewChannelParticipant()
				cp.ChannelId = leaf.Id
				cpc, err := cp.FetchParticipantCount()

				So(err, ShouldBeNil)
				So(cpc, ShouldEqual, 0)
			})

			Convey("root node should have 2 participants", func() {
				cp := models.NewChannelParticipant()
				cp.ChannelId = root.Id
				cpc, err := cp.FetchParticipantCount()

				So(err, ShouldBeNil)
				So(cpc, ShouldEqual, 2)
			})
		})

		Convey("should process participated channels with messages", func() {
			groupName := models.RandomGroupName()
			root := models.CreateTypedGroupedChannelWithTest(acc1.Id, models.Channel_TYPE_TOPIC, groupName)
			leaf := models.CreateTypedGroupedChannelWithTest(acc2.Id, models.Channel_TYPE_TOPIC, groupName)
			// add participants with tests
			models.AddParticipants(leaf.Id, acc1.Id, acc2.Id)

			// create messages to the regarding leaf channel
			models.CreateMessage(leaf.Id, acc1.Id, models.ChannelMessage_TYPE_POST)
			models.CreateMessage(leaf.Id, acc1.Id, models.ChannelMessage_TYPE_POST)
			models.CreateMessage(leaf.Id, acc1.Id, models.ChannelMessage_TYPE_POST)

			cl := &models.ChannelLink{
				RootId: root.Id,
				LeafId: leaf.Id,
			}
			So(controller.process(cl), ShouldBeNil)

			Convey("leaf node should not have any participants", func() {
				cp := models.NewChannelParticipant()
				cp.ChannelId = leaf.Id
				cpc, err := cp.FetchParticipantCount()

				So(err, ShouldBeNil)
				So(cpc, ShouldEqual, 0)
			})

			Convey("root node should have 2 participants", func() {
				cp := models.NewChannelParticipant()
				cp.ChannelId = root.Id
				cpc, err := cp.FetchParticipantCount()

				So(err, ShouldBeNil)
				So(cpc, ShouldEqual, 2)
			})
		})

		Convey("should process messages that are in multiple channels - when origin is linked channel", func() {
			groupName := models.RandomGroupName()

			root := models.CreateTypedGroupedChannelWithTest(acc1.Id, models.Channel_TYPE_TOPIC, groupName)
			leaf := models.CreateTypedGroupedChannelWithTest(acc2.Id, models.Channel_TYPE_TOPIC, groupName)
			// add participants with tests
			models.AddParticipants(leaf.Id, acc1.Id, acc2.Id)

			otherChannel := models.CreateTypedGroupedChannelWithTest(acc1.Id, models.Channel_TYPE_TOPIC, groupName)
			// add participants with tests
			models.AddParticipants(otherChannel.Id, acc1.Id, acc2.Id)

			// add same messages to the otherChannel
			body := fmt.Sprintf("#%s and #%s are my topics", leaf.Name, otherChannel.Name)

			// create messages to the regarding leaf channel
			cm1 := models.CreateMessageWithBody(leaf.Id, acc1.Id, models.ChannelMessage_TYPE_POST, body)
			cm2 := models.CreateMessageWithBody(leaf.Id, acc1.Id, models.ChannelMessage_TYPE_POST, body)
			cm3 := models.CreateMessageWithBody(leaf.Id, acc1.Id, models.ChannelMessage_TYPE_POST, body)

			_, err := otherChannel.EnsureMessage(cm1, true)
			// ignore ErrMessageAlreadyInTheChannel error
			if err != models.ErrMessageAlreadyInTheChannel {
				So(err, ShouldBeNil)
			}

			_, err = otherChannel.EnsureMessage(cm2, true)
			// ignore ErrMessageAlreadyInTheChannel error
			if err != models.ErrMessageAlreadyInTheChannel {
				So(err, ShouldBeNil)
			}

			_, err = otherChannel.EnsureMessage(cm3, true)
			// ignore ErrMessageAlreadyInTheChannel error
			if err != models.ErrMessageAlreadyInTheChannel {
				So(err, ShouldBeNil)
			}

			// make sure we added messages to the otherChannel
			cmlc, err := models.NewChannelMessageList().Count(otherChannel.Id)
			So(err, ShouldBeNil)
			So(cmlc, ShouldEqual, 3)

			cl := &models.ChannelLink{
				RootId: root.Id,
				LeafId: leaf.Id,
			}

			// So(cl.Create(), ShouldBeNil)

			// do the switch
			So(controller.process(cl), ShouldBeNil)

			Convey("leaf node should not have any messages", func() {
				//check leaf channel
				cmlc, err = models.NewChannelMessageList().Count(leaf.Id)
				So(err, ShouldBeNil)
				So(cmlc, ShouldEqual, 0)
			})

			Convey("root node should have 3 messages", func() {
				// check root channel
				cmlc, err = models.NewChannelMessageList().Count(root.Id)
				So(err, ShouldBeNil)
				So(cmlc, ShouldEqual, 3)
			})

			Convey("otherChannel should have 3 messages", func() {
				// check other channel
				cmlc, err = models.NewChannelMessageList().Count(otherChannel.Id)
				So(err, ShouldBeNil)
				So(cmlc, ShouldEqual, 3)
			})
		})

		Convey("should process messages that are initiated in leaf channels", func() {
			groupName := models.RandomGroupName()

			root := models.CreateTypedGroupedChannelWithTest(acc1.Id, models.Channel_TYPE_TOPIC, groupName)
			leaf := models.CreateTypedGroupedChannelWithTest(acc2.Id, models.Channel_TYPE_TOPIC, groupName)
			// add participants with tests
			models.AddParticipants(leaf.Id, acc1.Id, acc2.Id)

			otherChannel := models.CreateTypedGroupedChannelWithTest(acc1.Id, models.Channel_TYPE_TOPIC, groupName)
			// add participants with tests
			models.AddParticipants(otherChannel.Id, acc1.Id, acc2.Id)

			body := fmt.Sprintf("#%s and #%s are my topics", leaf.Name, otherChannel.Name)

			// create messages to the regarding leaf channel
			cm1 := models.CreateMessageWithBody(leaf.Id, acc1.Id, models.ChannelMessage_TYPE_POST, body)
			cm2 := models.CreateMessageWithBody(leaf.Id, acc1.Id, models.ChannelMessage_TYPE_POST, body)
			cm3 := models.CreateMessageWithBody(leaf.Id, acc1.Id, models.ChannelMessage_TYPE_POST, body)

			_, err := otherChannel.EnsureMessage(cm1, true)
			So(err, ShouldBeNil)

			_, err = otherChannel.EnsureMessage(cm2, true)
			So(err, ShouldBeNil)

			_, err = otherChannel.EnsureMessage(cm3, true)
			So(err, ShouldBeNil)

			// just to be sure that messages will not belong to leaf node anymore
			updatedBody := fmt.Sprintf("#%s are my topics", otherChannel.Name)
			cm1.Body = updatedBody
			So(cm1.Update(), ShouldBeNil)

			cm2.Body = updatedBody
			So(cm2.Update(), ShouldBeNil)

			cm3.Body = updatedBody
			So(cm3.Update(), ShouldBeNil)

			cl := &models.ChannelLink{
				RootId: root.Id,
				LeafId: leaf.Id,
			}

			So(cl.Create(), ShouldBeNil)

			// do the switch
			So(controller.process(cl), ShouldBeNil)

			//check leaf channel

			var messages []models.ChannelMessage
			err = bongo.B.DB.
				Model(models.ChannelMessage{}).
				Unscoped().
				Where("initial_channel_id = ?", leaf.Id).
				Find(&messages).Error

			So(err, ShouldEqual, bongo.RecordNotFound)
			So(len(messages), ShouldEqual, 0)
		})

		Convey("make sure message order still same", func() {
			groupName := models.RandomGroupName()

			rootChannel := models.CreateTypedGroupedChannelWithTest(acc1.Id, models.Channel_TYPE_TOPIC, groupName)
			leafChannel := models.CreateTypedGroupedChannelWithTest(acc2.Id, models.Channel_TYPE_TOPIC, groupName)
			// add participants with tests
			models.AddParticipants(leafChannel.Id, acc1.Id, acc2.Id)

			leafChannel, err := models.Cache.Channel.ById(leafChannel.Id)
			So(err, ShouldBeNil)

			otherChannel := models.CreateChannelWithTest(acc1.Id)
			// add participants with tests
			models.AddParticipants(otherChannel.Id, acc1.Id, acc2.Id)
			// add same messages to the otherChannel

			body := "hey yo! #" + leafChannel.Name
			// add 3 message for each channel one by one
			cm1Leaf := models.CreateMessageWithBody(leafChannel.Id, acc1.Id, models.ChannelMessage_TYPE_POST, body)
			cm1Root := models.CreateMessageWithBody(rootChannel.Id, acc1.Id, models.ChannelMessage_TYPE_POST, body)
			cm2Leaf := models.CreateMessageWithBody(leafChannel.Id, acc1.Id, models.ChannelMessage_TYPE_POST, body)
			cm2Root := models.CreateMessageWithBody(rootChannel.Id, acc1.Id, models.ChannelMessage_TYPE_POST, body)
			cm3Leaf := models.CreateMessageWithBody(leafChannel.Id, acc1.Id, models.ChannelMessage_TYPE_POST, body)
			cm3Root := models.CreateMessageWithBody(rootChannel.Id, acc1.Id, models.ChannelMessage_TYPE_POST, body)

			cl := &models.ChannelLink{
				RootId: rootChannel.Id,
				LeafId: leafChannel.Id,
			}

			// do the switch
			So(controller.process(cl), ShouldBeNil)

			//
			// fetch the history
			//
			ses, err := models.FetchOrCreateSession(acc1.Nick, groupName)
			So(err, ShouldBeNil)
			So(ses, ShouldNotBeNil)

			history, err := rest.GetHistory(
				rootChannel.Id,
				&request.Query{
					AccountId: acc1.Id,
				},
				ses.ClientId,
			)
			So(err, ShouldBeNil)
			So(history, ShouldNotBeNil)
			So(len(history.MessageList), ShouldEqual, 6)

			// History returns messages in reversed order
			// That is why we are checking with the following indexes
			So(history.MessageList[5].Message.Id, ShouldEqual, cm1Leaf.Id)
			So(history.MessageList[3].Message.Id, ShouldEqual, cm2Leaf.Id)
			So(history.MessageList[1].Message.Id, ShouldEqual, cm3Leaf.Id)

			So(history.MessageList[4].Message.Id, ShouldEqual, cm1Root.Id)
			So(history.MessageList[2].Message.Id, ShouldEqual, cm2Root.Id)
			So(history.MessageList[0].Message.Id, ShouldEqual, cm3Root.Id)
		})

		Convey("make sure messages got deleted if delete option is passed", func() {
			groupName := models.RandomGroupName()

			rootChannel := models.CreateTypedGroupedChannelWithTest(acc1.Id, models.Channel_TYPE_TOPIC, groupName)
			leafChannel := models.CreateTypedGroupedChannelWithTest(acc2.Id, models.Channel_TYPE_TOPIC, groupName)
			// add participants with tests
			models.AddParticipants(rootChannel.Id, acc1.Id, acc2.Id)
			models.AddParticipants(leafChannel.Id, acc1.Id, acc2.Id)

			otherChannel := models.CreateTypedGroupedChannelWithTest(acc1.Id, models.Channel_TYPE_TOPIC, groupName)
			// add participants with tests
			models.AddParticipants(otherChannel.Id, acc1.Id, acc2.Id)

			// add same messages to the otherChannel
			body := fmt.Sprintf("hey yo! #%s #%s"+leafChannel.Name, rootChannel.Name)

			// add 3 message for each channel one by one
			models.CreateMessageWithBody(leafChannel.Id, acc1.Id, models.ChannelMessage_TYPE_POST, body)
			cm1Root := models.CreateMessageWithBody(rootChannel.Id, acc1.Id, models.ChannelMessage_TYPE_POST, body)
			models.CreateMessageWithBody(leafChannel.Id, acc1.Id, models.ChannelMessage_TYPE_POST, body)
			cm2Root := models.CreateMessageWithBody(rootChannel.Id, acc1.Id, models.ChannelMessage_TYPE_POST, body)
			models.CreateMessageWithBody(leafChannel.Id, acc1.Id, models.ChannelMessage_TYPE_POST, body)
			cm3Root := models.CreateMessageWithBody(rootChannel.Id, acc1.Id, models.ChannelMessage_TYPE_POST, body)

			cl := &models.ChannelLink{
				RootId:         rootChannel.Id,
				LeafId:         leafChannel.Id,
				DeleteMessages: true,
			}

			// do the switch
			So(controller.process(cl), ShouldBeNil)

			//
			// fetch the history
			//
			ses, err := models.FetchOrCreateSession(acc1.Nick, groupName)
			So(err, ShouldBeNil)
			So(ses, ShouldNotBeNil)

			history, err := rest.GetHistory(
				rootChannel.Id,
				&request.Query{
					AccountId: acc1.Id,
				},
				ses.ClientId,
			)
			So(err, ShouldBeNil)
			So(history, ShouldNotBeNil)
			So(len(history.MessageList), ShouldEqual, 3)

			// History returns messages in reversed order
			// That is why we are checking with the following indexes
			So(history.MessageList[2].Message.Id, ShouldEqual, cm1Root.Id)
			So(history.MessageList[1].Message.Id, ShouldEqual, cm2Root.Id)
			So(history.MessageList[0].Message.Id, ShouldEqual, cm3Root.Id)

			Convey("make sure to remove participants", func() {
				ids, err := leafChannel.FetchParticipantIds(&request.Query{})
				So(err, ShouldBeNil)
				So(len(ids), ShouldEqual, 0)

				ids, err = rootChannel.FetchParticipantIds(&request.Query{})
				So(err, ShouldBeNil)
				So(len(ids), ShouldEqual, 2)
			})
		})

		Convey("make sure messages dont have hashtag in them when we merge to group channel", func() {
			groupName := models.RandomGroupName()

			rootChannel := models.CreateTypedGroupedChannelWithTest(
				acc1.Id,
				models.Channel_TYPE_GROUP,
				groupName,
			)
			leafChannel := models.CreateTypedGroupedChannelWithTest(
				acc2.Id,
				models.Channel_TYPE_TOPIC,
				groupName,
			)

			cl := &models.ChannelLink{
				RootId: rootChannel.Id,
				LeafId: leafChannel.Id,
			}

			So(cl.Create(), ShouldBeNil)

			models.AddParticipants(rootChannel.Id, acc1.Id, acc2.Id)
			models.AddParticipants(leafChannel.Id, acc1.Id, acc2.Id)
			leafChannel, err := models.Cache.Channel.ById(leafChannel.Id)
			So(err, ShouldBeNil)

			body := "hey yo! #" + leafChannel.Name
			// add 3 message for each channel one by one
			models.CreateMessageWithBody(leafChannel.Id, acc1.Id, models.ChannelMessage_TYPE_POST, body)
			models.CreateMessageWithBody(rootChannel.Id, acc1.Id, models.ChannelMessage_TYPE_POST, body)
			models.CreateMessageWithBody(leafChannel.Id, acc1.Id, models.ChannelMessage_TYPE_POST, body)
			models.CreateMessageWithBody(rootChannel.Id, acc1.Id, models.ChannelMessage_TYPE_POST, body)
			models.CreateMessageWithBody(leafChannel.Id, acc1.Id, models.ChannelMessage_TYPE_POST, body)
			models.CreateMessageWithBody(rootChannel.Id, acc1.Id, models.ChannelMessage_TYPE_POST, body)

			// do the switch
			So(controller.process(cl), ShouldBeNil)

			//
			// fetch the history
			//
			ses, err := models.FetchOrCreateSession(acc1.Nick, groupName)
			So(err, ShouldBeNil)
			So(ses, ShouldNotBeNil)

			history, err := rest.GetHistory(
				rootChannel.Id,
				&request.Query{
					AccountId: acc1.Id,
				},
				ses.ClientId,
			)
			So(err, ShouldBeNil)
			So(history, ShouldNotBeNil)
			So(len(history.MessageList), ShouldEqual, 6)

			// History returns messages in reversed order
			// That is why we are checking with the following indexes
			So(history.MessageList[5].Message.Body, ShouldNotContainSubstring, "#"+leafChannel.Name)
			So(history.MessageList[3].Message.Body, ShouldNotContainSubstring, "#"+leafChannel.Name)
			So(history.MessageList[1].Message.Body, ShouldNotContainSubstring, "#"+leafChannel.Name)
		})

	})
}

func TestProcessWithNewTag(t *testing.T) {
	Convey("process with tag", t, func() {
		root := "#hi"
		leaf := "#say"
		body := "my leaf " + leaf + " and new root " + root + " topic"

		Convey("should replace leaf with root", func() {
			So(processWithNewTag(body, leaf, root), ShouldNotContainSubstring, leaf)
		})

		Convey("should not contain multiple root", func() {

			Convey("if they are consecutive at the end", func() {
				end := root + " " + root
				body = body + " " + end

				So(processWithNewTag(body, leaf, root), ShouldNotEndWith, end)
			})

			Convey("if they are consecutive at the beginning", func() {
				head := root + " " + root
				body = head + " " + body

				So(processWithNewTag(body, leaf, root), ShouldNotStartWith, head)
			})
			Convey("if they are consecutive in the middle", func() {
				middle := root + " " + root
				body = "hey " + middle + " say"

				So(processWithNewTag(body, leaf, root), ShouldNotContainSubstring, middle)
				So(processWithNewTag(body, leaf, root), ShouldContainSubstring, root)
			})
			Convey("if it has strange structure", func() {
				body := "#hi #hi #hi my hi topic #hi #hi #hi i like #hi all hi's #hi #hi"
				res := "#hi my hi topic #hi i like #hi all hi's #hi"
				So(processWithNewTag(body, "#hi2", "#hi"), ShouldEqual, res)
			})
		})
	})
}
