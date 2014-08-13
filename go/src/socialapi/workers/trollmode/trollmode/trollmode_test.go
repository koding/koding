package trollmode

import (
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"math"
	"math/rand"
	"socialapi/models"
	"socialapi/request"
	"socialapi/rest"
	"socialapi/workers/common/runner"
	"socialapi/workers/common/tests"
	"strconv"
	"testing"
	"time"

	"github.com/koding/bongo"
	. "github.com/smartystreets/goconvey/convey"
	"labix.org/v2/mgo/bson"
)

func CreatePrivateMessageUser() {
	acc, err := modelhelper.GetAccount("sinan")
	if err == nil {
		return
	}

	if err != modelhelper.ErrNotFound {
		panic(err)
	}

	acc = new(mongomodels.Account)
	acc.Id = bson.NewObjectId()
	acc.Profile.Nickname = "sinan"

	modelhelper.CreateAccount(acc)
}

func TestMarkedAsTroll(t *testing.T) {
	r := runner.New("TrollMode-Test")
	err := r.Init()
	if err != nil {
		panic(err)
	}

	defer r.Close()

	modelhelper.Initialize(r.Conf.Mongo)
	defer modelhelper.Close()
	CreatePrivateMessageUser()
	// disable logs
	// r.Log.SetLevel(logging.CRITICAL)

	Convey("given a controller", t, func() {

		// cretae admin user
		adminUser := models.NewAccount()
		adminUser.OldId = bson.NewObjectId().Hex()
		adminUser, err = rest.CreateAccount(adminUser)
		tests.ResultedWithNoErrorCheck(adminUser, err)

		// create troll user
		trollUser := models.NewAccount()
		trollUser.OldId = bson.NewObjectId().Hex()
		trollUser, err := rest.CreateAccount(trollUser)
		tests.ResultedWithNoErrorCheck(trollUser, err)
		trollUser.IsTroll = true

		// mark user as troll
		res := rest.MarkAsTroll(trollUser)
		So(res, ShouldBeNil)

		// create normal user
		normalUser := models.NewAccount()
		normalUser.OldId = bson.NewObjectId().Hex()
		normalUser, err = rest.CreateAccount(normalUser)
		tests.ResultedWithNoErrorCheck(normalUser, err)

		// create groupName
		rand.Seed(time.Now().UnixNano())
		groupName := "testgroup" + strconv.FormatInt(rand.Int63(), 10)
		groupChannel, err := rest.CreateChannelByGroupNameAndType(
			adminUser.Id,
			groupName,
			models.Channel_TYPE_GROUP,
		)
		tests.ResultedWithNoErrorCheck(groupChannel, err)

		controller := NewController(r.Log)

		Convey("err should be nil", func() {
			So(err, ShouldBeNil)
		})

		Convey("controller should be set", func() {
			So(controller, ShouldNotBeNil)
		})

		Convey("should return nil when given nil account", func() {
			So(controller.MarkedAsTroll(nil), ShouldBeNil)
		})

		Convey("should return nil when account id given 0", func() {
			So(controller.MarkedAsTroll(models.NewAccount()), ShouldBeNil)
		})

		Convey("non existing account should not give error", func() {
			a := models.NewAccount()
			a.Id = math.MaxInt64
			So(controller.MarkedAsTroll(a), ShouldBeNil)
		})

		Convey("non existing account should not give error", func() {
			a := models.NewAccount()
			a.Id = math.MaxInt64
			So(controller.MarkedAsTroll(a), ShouldBeNil)
		})

		/////////////////////////  marking all content ////////////////////////
		// mark channel
		Convey("private channels of a troll should be marked as exempt", func() {
			// fetch from api, because we need to test system from there
			privatemessageChannelId1, err := createPrivateMessageChannel(trollUser.Id, groupName)
			So(err, ShouldBeNil)
			So(privatemessageChannelId1, ShouldBeGreaterThan, 0)

			privatemessageChannelId2, err := createPrivateMessageChannel(trollUser.Id, groupName)
			So(err, ShouldBeNil)
			So(privatemessageChannelId2, ShouldBeGreaterThan, 0)

			So(controller.markChannels(trollUser, models.Safe), ShouldBeNil)

			// fetch channel from db
			c1 := models.NewChannel()
			err = c1.ById(privatemessageChannelId1)
			So(err, ShouldBeNil)
			So(c1.Id, ShouldEqual, privatemessageChannelId1)
			// check here
			So(c1.MetaBits.Is(models.Troll), ShouldBeTrue)

			// fetch channel from db
			c2 := models.NewChannel()
			err = c2.ById(privatemessageChannelId2)
			So(err, ShouldBeNil)
			So(c2.Id, ShouldEqual, privatemessageChannelId2)

			// check here
			So(c2.MetaBits.Is(models.Troll), ShouldBeTrue)
		})

		// mark channel
		Convey("public channels of a troll should not be marked as exempt", nil)

		// mark channel_participant
		Convey("participations of a troll should not be marked as exempt", func() {
			// fetch from api, because we need to test system from there
			privatemessageChannelId1, err := createPrivateMessageChannel(trollUser.Id, groupName)
			So(err, ShouldBeNil)
			So(privatemessageChannelId1, ShouldBeGreaterThan, 0)

			privatemessageChannelId2, err := createPrivateMessageChannel(trollUser.Id, groupName)
			So(err, ShouldBeNil)
			So(privatemessageChannelId2, ShouldBeGreaterThan, 0)

			So(controller.markParticipations(trollUser, models.Safe), ShouldBeNil)

			var participations []models.ChannelParticipant

			query := &bongo.Query{
				Selector: map[string]interface{}{
					"account_id": trollUser.Id,
				},
			}

			err = models.NewChannelParticipant().Some(&participations, query)
			So(err, ShouldBeNil)
			for _, participation := range participations {
				So(participation.MetaBits.Is(models.Troll), ShouldBeTrue)
			}
		})

		// mark channel_message_list
		Convey("massages that are in all channels that are created by troll, should be marked as exempt", func() {

			post, err := rest.CreatePost(groupChannel.Id, trollUser.Id)
			tests.ResultedWithNoErrorCheck(post, err)

			So(controller.markMessageLists(post, models.Safe), ShouldBeNil)

			cml := models.NewChannelMessageList()
			q := &bongo.Query{
				Selector: map[string]interface{}{
					"message_id": post.Id,
				},
			}

			var messages []models.ChannelMessageList
			err = cml.Some(&messages, q)
			So(err, ShouldBeNil)

			// message should be in one channel
			So(len(messages), ShouldBeGreaterThan, 0)

			for _, message := range messages {
				So(message.MetaBits.Is(models.Troll), ShouldBeTrue)
			}
		})

		// mark channel_message
		Convey("messages of a troll should be marked as exempt", func() {
			post1, err := rest.CreatePost(groupChannel.Id, trollUser.Id)
			tests.ResultedWithNoErrorCheck(post1, err)

			post2, err := rest.CreatePost(groupChannel.Id, trollUser.Id)
			tests.ResultedWithNoErrorCheck(post2, err)

			So(controller.markMessages(trollUser, models.Safe), ShouldBeNil)

			cm := models.NewChannelMessage()
			q := &bongo.Query{
				Selector: map[string]interface{}{
					"account_id": trollUser.Id,
				},
			}

			var messages []models.ChannelMessage
			err = cm.Some(&messages, q)
			So(err, ShouldBeNil)

			for _, message := range messages {
				So(message.MetaBits.Is(models.Troll), ShouldBeTrue)
			}
		})

		// mark interactions
		Convey("interactions of a troll should be marked as exempt", func() {
			post1, err := rest.CreatePost(groupChannel.Id, trollUser.Id)
			tests.ResultedWithNoErrorCheck(post1, err)

			err = rest.AddInteraction("like", post1.Id, trollUser.Id)
			So(err, ShouldBeNil)

			So(controller.markInteractions(trollUser, models.Safe), ShouldBeNil)

			cm := models.NewInteraction()
			q := &bongo.Query{
				Selector: map[string]interface{}{
					"account_id": trollUser.Id,
				},
			}

			var interactions []models.Interaction
			err = cm.Some(&interactions, q)
			So(err, ShouldBeNil)

			for _, interaction := range interactions {
				So(interaction.MetaBits.Is(models.Troll), ShouldBeTrue)
			}
		})

		// mark message_reply
		Convey("replies of a troll should be marked as exempt", func() {
			// create post
			post, err := rest.CreatePost(groupChannel.Id, trollUser.Id)
			tests.ResultedWithNoErrorCheck(post, err)

			// create reply
			reply, err := rest.AddReply(post.Id, post.AccountId, groupChannel.Id)
			So(err, ShouldBeNil)
			So(reply, ShouldNotBeNil)
			So(reply.AccountId, ShouldEqual, post.AccountId)

			So(controller.markMessageReplies(reply, models.Safe), ShouldBeNil)

			mr := models.NewMessageReply()
			q := &bongo.Query{
				Selector: map[string]interface{}{
					"reply_id": reply.Id,
				},
			}

			var mrs []models.MessageReply
			err = mr.Some(&mrs, q)
			So(err, ShouldBeNil)

			So(len(mrs), ShouldBeGreaterThan, 0)

			for _, mr := range mrs {
				So(mr.MetaBits.Is(models.Troll), ShouldBeTrue)
			}
		})

		//////////////// after marking, when troll adds new content/////////////

		// update channel data while creating
		Convey("when a troll creates a channel, meta_bits should be set", func() {
			privatemessageChannelId1, err := createPrivateMessageChannel(trollUser.Id, groupName)
			So(err, ShouldBeNil)
			So(privatemessageChannelId1, ShouldBeGreaterThan, 0)

			// fetch channel from db
			c1 := models.NewChannel()
			err = c1.ById(privatemessageChannelId1)
			So(err, ShouldBeNil)
			So(c1.Id, ShouldEqual, privatemessageChannelId1)

			So(c1.MetaBits.Is(models.Troll), ShouldBeTrue)
		})

		// update channel_participant data while creating
		Convey("when a troll is added to a channel as participant, meta_bits should be set", func() {
			privatemessageChannelId, err := createPrivateMessageChannel(trollUser.Id, groupName)
			So(err, ShouldBeNil)
			So(privatemessageChannelId, ShouldBeGreaterThan, 0)

			// fetch channel from db
			cp := models.NewChannelParticipant()
			cp.AccountId = trollUser.Id
			cp.ChannelId = privatemessageChannelId

			So(cp.FetchParticipant(), ShouldBeNil)
			So(cp.AccountId, ShouldEqual, trollUser.Id)

			So(cp.MetaBits.Is(models.Troll), ShouldBeTrue)
		})

		// update channel_message_list data while creating
		Convey("when a troll content is added to a channel, meta_bits should be set", func() {
			privatemessageChannelId, err := createPrivateMessageChannel(normalUser.Id, groupName)
			So(err, ShouldBeNil)
			So(privatemessageChannelId, ShouldBeGreaterThan, 0)

			// add a message from a troll user
			post, err := rest.CreatePost(privatemessageChannelId, trollUser.Id)
			So(err, ShouldBeNil)
			So(post, ShouldNotBeNil)

			// fetch last message
			c := models.NewChannel()
			c.Id = privatemessageChannelId
			ml, err := c.FetchMessageList(post.Id)
			tests.ResultedWithNoErrorCheck(ml, err)

			So(ml.MetaBits.Is(models.Troll), ShouldBeTrue)

		})

		// update channel_message data while creating
		Convey("when a troll posts a status update, meta_bits should be set", func() {
			privatemessageChannelId, err := createPrivateMessageChannel(normalUser.Id, groupName)
			So(err, ShouldBeNil)
			So(privatemessageChannelId, ShouldBeGreaterThan, 0)

			// add a message from a troll user
			post, err := rest.CreatePost(privatemessageChannelId, trollUser.Id)
			So(err, ShouldBeNil)
			So(post, ShouldNotBeNil)

			// fetch last message
			c := models.NewChannel()
			c.Id = privatemessageChannelId
			lastMessage, err := c.FetchLastMessage()
			tests.ResultedWithNoErrorCheck(lastMessage, err)

			So(lastMessage.MetaBits.Is(models.Troll), ShouldBeTrue)

		})

		// update channel_message data while creating
		Convey("when a troll replies to a status update, meta_bits should be set", func() {
			// create post form a normal user
			post, err := rest.CreatePost(groupChannel.Id, normalUser.Id)
			tests.ResultedWithNoErrorCheck(post, err)

			// create reply
			reply, err := rest.AddReply(post.Id, trollUser.Id, groupChannel.Id)
			So(err, ShouldBeNil)
			So(reply, ShouldNotBeNil)
			So(reply.AccountId, ShouldEqual, trollUser.Id)

			So(controller.markMessageReplies(reply, models.Safe), ShouldBeNil)

			m := models.NewChannelMessage()
			So(m.ById(reply.Id), ShouldBeNil)
			So(m, ShouldNotBeNil)

			So(m.MetaBits.Is(models.Troll), ShouldBeTrue)

		})

		// update message_reply data while creating
		Convey("when a troll replies to a status update, meta_bits should be set", func() {
			// create post form a normal user
			post, err := rest.CreatePost(groupChannel.Id, normalUser.Id)
			tests.ResultedWithNoErrorCheck(post, err)

			// create reply
			reply, err := rest.AddReply(post.Id, trollUser.Id, groupChannel.Id)
			So(err, ShouldBeNil)
			So(reply, ShouldNotBeNil)
			So(reply.AccountId, ShouldEqual, trollUser.Id)

			So(controller.markMessageReplies(reply, models.Safe), ShouldBeNil)

			// check for reply's meta bit
			mr := models.NewMessageReply()
			q := &bongo.Query{
				Selector: map[string]interface{}{
					"reply_id": reply.Id,
				},
			}

			var mrs []models.MessageReply
			err = mr.Some(&mrs, q)
			So(err, ShouldBeNil)

			So(len(mrs), ShouldBeGreaterThan, 0)
			So(mrs[0].MetaBits.Is(models.Troll), ShouldBeTrue)

		})

		// update interaction data while creating
		Convey("when a troll likes a status update, meta_bits should be set", func() {
			// create post form a normal user
			post, err := rest.CreatePost(groupChannel.Id, normalUser.Id)
			tests.ResultedWithNoErrorCheck(post, err)

			// add like
			So(rest.AddInteraction("like", post.Id, trollUser.Id), ShouldBeNil)

			// fetch likes
			i := models.NewInteraction()
			q := &bongo.Query{
				Selector: map[string]interface{}{
					"account_id": trollUser.Id,
				},
			}

			var interactions []models.Interaction
			So(i.Some(&interactions, q), ShouldBeNil)

			for _, interaction := range interactions {
				So(interaction.MetaBits.Is(models.Troll), ShouldBeTrue)
			}

		})

		// ///////////////////////////// while querying ///////////////////////////

		// channel
		Convey("when a troll creates a private channel, normal user should not be able to see it", func() {
			privatemessageChannelId, err := createPrivateMessageChannel(trollUser.Id, groupName)
			So(err, ShouldBeNil)
			So(privatemessageChannelId, ShouldBeGreaterThan, 0)

			// fetch participants of this channel
			c := models.NewChannel()
			c.Id = privatemessageChannelId
			participants, err := c.FetchParticipantIds(&request.Query{ShowExempt: true})
			tests.ResultedWithNoErrorCheck(participants, err)
			So(len(participants), ShouldEqual, 2)

			var sinan int64
			for _, participant := range participants {
				if participant != trollUser.Id {
					sinan = participant
					break
				}
			}

			// make sure we found sinan in participant list
			So(sinan, ShouldBeGreaterThan, 0)

			history, err := rest.GetHistory(
				privatemessageChannelId,
				&request.Query{
					AccountId: sinan,
				},
			)

			So(err, ShouldNotBeNil)
			So(history, ShouldBeNil)
		})

		// channel
		Convey("when a troll creates a private channel, normal user should not be able to see it with `ShowExempt` flag", func() {
			privatemessageChannelId, err := createPrivateMessageChannel(trollUser.Id, groupName)
			So(err, ShouldBeNil)
			So(privatemessageChannelId, ShouldBeGreaterThan, 0)

			// fetch participants of this channel
			c := models.NewChannel()
			c.Id = privatemessageChannelId
			participants, err := c.FetchParticipantIds(&request.Query{ShowExempt: true})
			tests.ResultedWithNoErrorCheck(participants, err)
			So(len(participants), ShouldEqual, 2)

			var sinan int64
			for _, participant := range participants {
				if participant != trollUser.Id {
					sinan = participant
					break
				}
			}

			// make sure we found sinan in participant list
			So(sinan, ShouldBeGreaterThan, 0)

			history, err := rest.GetHistory(
				privatemessageChannelId,
				&request.Query{
					AccountId:  sinan,
					ShowExempt: true,
				},
			)
			So(err, ShouldBeNil)
			So(history, ShouldNotBeNil)
		})

		// channel_participant
		Convey("when a troll joins a channel, they should not be in the participant list for normal users", func() {
			privatemessageChannelId, err := createPrivateMessageChannel(trollUser.Id, groupName)
			So(err, ShouldBeNil)
			So(privatemessageChannelId, ShouldBeGreaterThan, 0)

			// fetch participants of this channel
			c := models.NewChannel()
			c.Id = privatemessageChannelId
			participants, err := c.FetchParticipantIds(&request.Query{})
			tests.ResultedWithNoErrorCheck(participants, err)
			So(len(participants), ShouldEqual, 1)

			var trollExists bool
			for _, participant := range participants {
				if participant == trollUser.Id {
					trollExists = true
					break
				}
			}

			So(trollExists, ShouldBeFalse)
		})

		// channel_participant
		Convey("when a troll joins a channel, they should not be in the participant list for troll users", func() {
			privatemessageChannelId, err := createPrivateMessageChannel(trollUser.Id, groupName)
			So(err, ShouldBeNil)
			So(privatemessageChannelId, ShouldBeGreaterThan, 0)

			// fetch participants of this channel
			c := models.NewChannel()
			c.Id = privatemessageChannelId
			participants, err := c.FetchParticipantIds(&request.Query{ShowExempt: true})
			tests.ResultedWithNoErrorCheck(participants, err)
			So(len(participants), ShouldEqual, 2)

			var sinan int64
			for _, participant := range participants {
				if participant != trollUser.Id {
					sinan = participant
					break
				}
			}

			// make sure we found sinan in participant list
			So(sinan, ShouldNotEqual, 0)
		})

		// channel_message_list
		Convey("when an exempt content is added to a channel, they should not be listed in regarding channel", func() {
			privatemessageChannelId, err := createPrivateMessageChannel(normalUser.Id, groupName)
			So(err, ShouldBeNil)
			So(privatemessageChannelId, ShouldBeGreaterThan, 0)

			// create post form a troll user
			post, err := rest.CreatePost(privatemessageChannelId, trollUser.Id)
			tests.ResultedWithNoErrorCheck(post, err)

			history, err := rest.GetHistory(
				privatemessageChannelId,
				&request.Query{
					AccountId: normalUser.Id,
				},
			)

			So(err, ShouldBeNil)
			So(history, ShouldNotBeNil)
			So(history.MessageList, ShouldNotBeNil)
			So(len(history.MessageList), ShouldEqual, 1)

		})

		// channel_message_list
		Convey("when an exempt content is added to a channel, they should be listed in regarding channel for troll users", func() {
			privatemessageChannelId, err := createPrivateMessageChannel(trollUser.Id, groupName)
			So(err, ShouldBeNil)
			So(privatemessageChannelId, ShouldBeGreaterThan, 0)

			// create post form a troll user
			post, err := rest.CreatePost(privatemessageChannelId, normalUser.Id)
			tests.ResultedWithNoErrorCheck(post, err)

			history, err := rest.GetHistory(
				privatemessageChannelId,
				&request.Query{
					AccountId:  trollUser.Id,
					ShowExempt: true,
				},
			)

			So(err, ShouldBeNil)
			So(history, ShouldNotBeNil)
			So(history.MessageList, ShouldNotBeNil)
			So(len(history.MessageList), ShouldEqual, 2)
		})

		// channel_message
		Convey("when a troll posts a status update normal user shouldnt be able to see it", func() {
			// first post
			post1, err := rest.CreatePost(groupChannel.Id, trollUser.Id)
			tests.ResultedWithNoErrorCheck(post1, err)

			// second post
			post2, err := rest.CreatePost(groupChannel.Id, trollUser.Id)
			tests.ResultedWithNoErrorCheck(post2, err)

			// mark user as troll
			So(controller.MarkedAsTroll(trollUser), ShouldBeNil)

			// try to get post with normal user
			post11, err := rest.GetPost(post1.Id, normalUser.Id, groupChannel.GroupName)
			So(err, ShouldNotBeNil)
			So(post11, ShouldBeNil)
		})

		// interaction
		Convey("when a troll likes a status update, like count should not be incremented", func() {
			// create a post from a normal user
			post1, err := rest.CreatePost(groupChannel.Id, normalUser.Id)
			tests.ResultedWithNoErrorCheck(post1, err)

			// add like from normal user
			err = rest.AddInteraction("like", post1.Id, adminUser.Id)
			So(err, ShouldBeNil)

			// add like from normal user
			err = rest.AddInteraction("like", post1.Id, normalUser.Id)
			So(err, ShouldBeNil)

			// add like from troll user
			err = rest.AddInteraction("like", post1.Id, trollUser.Id)
			So(err, ShouldBeNil)

			history, err := rest.GetPostWithRelatedData(
				post1.Id,
				&request.Query{
					AccountId: normalUser.Id,
					GroupName: groupChannel.GroupName,
				},
			)

			// interactions should be set
			So(history.Message, ShouldNotBeNil)
			So(history.Interactions, ShouldNotBeNil)
			So(history.Interactions["like"], ShouldNotBeNil)
			likes := history.Interactions["like"]

			// `normal user` liked it
			So(likes.IsInteracted, ShouldBeTrue)

			// remove troll user from preview list
			So(len(likes.ActorsPreview), ShouldEqual, 2)

			// remove troll user from preview list
			So(likes.ActorsCount, ShouldEqual, 2)

		})

		addPosts := func() *models.ChannelMessage {
			post, err := rest.CreatePost(groupChannel.Id, normalUser.Id)
			tests.ResultedWithNoErrorCheck(post, err)

			users := []int64{adminUser.Id, normalUser.Id, trollUser.Id}

			// add interactions
			for _, userId := range users {
				// add like from troll user
				err = rest.AddInteraction("like", post.Id, userId)
				So(err, ShouldBeNil)
			}

			// add replies
			for _, userId := range users {
				// create reply
				reply, err := rest.AddReply(post.Id, userId, groupChannel.Id)
				So(err, ShouldBeNil)
				So(reply, ShouldNotBeNil)
				So(reply.AccountId, ShouldEqual, userId)
			}

			return post
		}

		// interaction
		Convey("when a troll likes a status update, like count should be incremented for troll users", func() {
			// create a post from a normal user
			post1 := addPosts()

			history, err := rest.GetPostWithRelatedData(
				post1.Id,
				&request.Query{
					AccountId:  trollUser.Id,
					GroupName:  groupChannel.GroupName,
					ShowExempt: true,
				},
			)

			So(err, ShouldBeNil)
			// interactions should be set
			So(history.Message, ShouldNotBeNil)
			So(history.Interactions, ShouldNotBeNil)
			So(history.Interactions["like"], ShouldNotBeNil)
			likes := history.Interactions["like"]

			// `normal user` liked it
			So(likes.IsInteracted, ShouldBeTrue)

			// remove troll user from preview list
			So(likes.ActorsCount, ShouldEqual, 3)
		})

		// interaction
		Convey("when a troll likes a status update, they should not be in the liker list", func() {
			// create a post from a normal user
			post1 := addPosts()

			history, err := rest.GetPostWithRelatedData(
				post1.Id,
				&request.Query{
					AccountId:  trollUser.Id,
					GroupName:  groupChannel.GroupName,
					ShowExempt: true,
				},
			)

			So(err, ShouldBeNil)

			// interactions should be set
			So(history.Message, ShouldNotBeNil)
			So(history.Interactions, ShouldNotBeNil)
			So(history.Interactions["like"], ShouldNotBeNil)
			likes := history.Interactions["like"]

			// `normal user` liked it
			So(likes.IsInteracted, ShouldBeTrue)

			// remove troll user from preview list
			So(len(likes.ActorsPreview), ShouldEqual, 3)
		})

		// message_reply
		Convey("when a troll replies to a status update, they should not be in the reply list for normal users", func() {
			post1 := addPosts()

			history, err := rest.GetPostWithRelatedData(
				post1.Id,
				&request.Query{
					AccountId:  normalUser.Id,
					GroupName:  groupChannel.GroupName,
					ShowExempt: false,
				},
			)
			So(err, ShouldBeNil)

			So(history.Replies, ShouldNotBeNil)

			// remove troll user's reply
			So(len(history.Replies), ShouldEqual, 2)

			// none of the replies' author should be troll user
			for _, reply := range history.Replies {
				So(reply.Message, ShouldNotBeNil)
				So(reply.Message.AccountId, ShouldNotEqual, 0)
				So(reply.Message.AccountId, ShouldNotEqual, trollUser.Id)
			}

			// `normal user` liked it
			So(history.RepliesCount, ShouldEqual, 2)
		})

		// message_reply
		Convey("when a troll replies to a status update, they should be in the reply list for troll users", func() {
			post1 := addPosts()

			history, err := rest.GetPostWithRelatedData(
				post1.Id,
				&request.Query{
					AccountId:  trollUser.Id,
					GroupName:  groupChannel.GroupName,
					ShowExempt: true,
				},
			)
			So(err, ShouldBeNil)

			So(history.Replies, ShouldNotBeNil)

			// remove troll user's reply
			So(len(history.Replies), ShouldEqual, 3)

			// `normal user` liked it
			So(history.RepliesCount, ShouldEqual, 3)
		})

		// private messsage
		Convey("listing private messages should work for troll users", func() {
			privatemessageChannelId, err := createPrivateMessageChannel(trollUser.Id, groupName)
			So(err, ShouldBeNil)
			So(privatemessageChannelId, ShouldBeGreaterThan, 0)

			channelContainers, err := rest.GetPrivateMessages(
				&request.Query{
					GroupName:  groupName,
					AccountId:  trollUser.Id,
					ShowExempt: true,
				},
			)

			So(err, ShouldBeNil)
			So(channelContainers, ShouldNotBeNil)

			found := false
			for _, container := range channelContainers {
				So(container.Channel, ShouldNotBeNil)
				So(container.Channel.Id, ShouldNotEqual, 0)
				if container.Channel.Id == privatemessageChannelId {
					found = true
				}
			}

			So(found, ShouldBeTrue)
		})

		// private messsage
		Convey("listing private messages should work for normal users", func() {
			privatemessageChannelId, err := createPrivateMessageChannel(trollUser.Id, groupName)
			So(err, ShouldBeNil)
			So(privatemessageChannelId, ShouldBeGreaterThan, 0)

			// fetch participants of this channel
			c := models.NewChannel()
			c.Id = privatemessageChannelId
			participants, err := c.FetchParticipantIds(
				&request.Query{
					GroupName:  groupName,
					ShowExempt: true,
				},
			)
			tests.ResultedWithNoErrorCheck(participants, err)
			So(len(participants), ShouldEqual, 2)

			var otherUser int64
			for _, participant := range participants {
				if participant != trollUser.Id {
					otherUser = participant
					break
				}
			}

			So(otherUser, ShouldNotEqual, 0)

			channelContainers, err := rest.GetPrivateMessages(
				&request.Query{
					AccountId:  trollUser.Id,
					ShowExempt: true,
				},
			)

			So(err, ShouldBeNil)
			So(channelContainers, ShouldNotBeNil)

			found := false
			for _, container := range channelContainers {
				So(container.Channel, ShouldNotBeNil)
				So(container.Channel.Id, ShouldNotEqual, 0)
				if container.Channel.Id == privatemessageChannelId {
					found = true
				}
			}

			So(found, ShouldBeFalse)
		})

		Convey("public  channel messages should be filtered", nil)
		Convey("topic   channel messages should be filtered", nil)
		Convey("private channel messages should be filtered", nil)
		Convey("pinned  channel messages should be filtered", nil)

	})
}

func createPrivateMessageChannel(accountId int64, groupName string) (int64, error) {
	// create first private channel
	cmc, err := rest.SendPrivateMessage(
		accountId,
		"this is a body for private message @sinan",
		groupName,
		[]string{"sinan"},
	)
	if err != nil {
		return 0, err
	}

	return cmc.Channel.Id, nil
}
