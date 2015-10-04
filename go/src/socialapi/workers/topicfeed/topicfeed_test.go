package topicfeed

import (
	"koding/db/mongodb/modelhelper"
	"math/rand"
	"socialapi/config"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/topicfeed"
	"testing"

	"github.com/koding/runner"

	"github.com/koding/bongo"
	. "github.com/smartystreets/goconvey/convey"
)

func TestMarkedAsTroll(t *testing.T) {
	Convey("while extracting topics", t, func() {
		Convey("duplicates should be returned as unique", func() {
			So(len(extractTopics("hi #topic #topic my topic")), ShouldEqual, 1)
		})

		Convey("public should be removed from topics list", func() {
			topics := extractTopics("hi #topic #public my topic")
			So(len(topics), ShouldEqual, 1)
			So(topics[0], ShouldEqual, "topic")
		})

		Convey("duplicate public should be removed from topics list", func() {
			topics := extractTopics("hi #public  #public  my topic")
			So(len(topics), ShouldEqual, 0)
		})
	})
}

func TestIsEligible(t *testing.T) {
	Convey("while testing isEligible", t, func() {
		Convey("initial channel id should be set", func() {
			c := models.NewChannelMessage()
			c.InitialChannelId = 0
			eligible, err := isEligible(c)
			So(err, ShouldBeNil)
			So(eligible, ShouldBeFalse)
		})

		Convey("type_constant should be Post", func() {
			c := models.NewChannelMessage()
			eligible, err := isEligible(c)
			So(err, ShouldBeNil)
			So(eligible, ShouldBeFalse)

			Convey("when it is set to Post, should be eligible", func() {
				c.InitialChannelId = rand.Int63()
				c.TypeConstant = models.ChannelMessage_TYPE_POST
				eligible, err := isEligible(c)
				So(err, ShouldBeNil)
				So(eligible, ShouldBeTrue)
			})
		})
	})
}

func TestMessageSaved(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	// init mongo connection
	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	controller := topicfeed.New(r.Log, appConfig)

	Convey("while testing MessageSaved", t, func() {

		Convey("if message posted to a channel directly", func() {
			account, groupChannel, groupName := models.CreateRandomGroupDataWithChecks()

			topicChannel := models.CreateTypedGroupedChannelWithTest(account.Id, models.Channel_TYPE_TOPIC, groupName)

			// just a random topic name
			topicName := topicChannel.Name
			c := models.NewChannelMessage()
			c.InitialChannelId = topicChannel.Id
			c.AccountId = account.Id
			c.Body = "my test post without a hashTag" + topicName
			c.TypeConstant = models.ChannelMessage_TYPE_POST

			// create with unscoped
			err := bongo.B.Unscoped().Table(c.TableName()).Create(c).Error
			So(err, ShouldBeNil)

			So(controller.MessageSaved(c), ShouldBeNil)

			Convey("should be posted to group channel too", func() {
				m, err := groupChannel.FetchLastMessage()
				So(err, ShouldBeNil)
				So(m, ShouldNotBeNil)
				So(m.Id, ShouldEqual, c.Id)
			})
		})

		Convey("newly created channels of koding group", func() {
			account := models.CreateAccountWithTest()
			groupChannel := models.CreateTypedGroupedChannelWithTest(account.Id, models.Channel_TYPE_GROUP, "koding")

			// just a random topic name
			topicName := models.RandomGroupName()
			c := models.NewChannelMessage()
			c.InitialChannelId = groupChannel.Id
			c.AccountId = account.Id
			c.Body = "my test topic #" + topicName
			c.TypeConstant = models.ChannelMessage_TYPE_POST

			// create with unscoped
			err := bongo.B.Unscoped().Table(c.TableName()).Create(c).Error
			So(err, ShouldBeNil)

			So(controller.MessageSaved(c), ShouldBeNil)

			Convey("should have moderation flag", func() {
				// byname doesnt filter
				channel, err := models.NewChannel().ByName(&request.Query{
					Name:      topicName,
					GroupName: groupChannel.GroupName,
					AccountId: account.Id,
				})
				So(err, ShouldBeNil)
				So(channel, ShouldNotBeNil)
				if appConfig.DisabledFeatures.Moderation {
					So(channel.MetaBits.Is(models.NeedsModeration), ShouldBeFalse)
				} else {
					So(channel.MetaBits.Is(models.NeedsModeration), ShouldBeTrue)
				}
			})
		})

		Convey("for non koding groups", func() {
			account, groupChannel, groupName := models.CreateRandomGroupDataWithChecks()

			Convey("we should not create channels automatically", func() {
				// just a random topic name
				topicName := models.RandomGroupName()
				c := models.NewChannelMessage()
				c.InitialChannelId = groupChannel.Id
				c.AccountId = account.Id
				c.Body = "my test topic #" + topicName
				c.TypeConstant = models.ChannelMessage_TYPE_POST

				// create with unscoped
				err := bongo.B.Unscoped().Table(c.TableName()).Create(c).Error
				So(err, ShouldBeNil)

				So(controller.MessageSaved(c), ShouldBeNil)

				Convey("channel should not exists", func() {
					// byname doesnt filter
					_, err := models.NewChannel().ByName(&request.Query{
						Name:      topicName,
						GroupName: groupChannel.GroupName,
						AccountId: account.Id,
					})
					So(err, ShouldEqual, bongo.RecordNotFound)
				})
			})

			Convey("even if channel exists", func() {
				topicChannel1 := models.CreateTypedGroupedChannelWithTest(account.Id, models.Channel_TYPE_TOPIC, groupName)
				topicChannel2 := models.CreateTypedGroupedChannelWithTest(account.Id, models.Channel_TYPE_TOPIC, groupName)

				// just a random topic name
				c := models.NewChannelMessage()
				c.InitialChannelId = topicChannel1.Id
				c.AccountId = account.Id
				c.Body = "my test topic #" + topicChannel2.Name
				c.TypeConstant = models.ChannelMessage_TYPE_POST

				// create with unscoped
				err := bongo.B.Unscoped().Table(c.TableName()).Create(c).Error
				So(err, ShouldBeNil)

				So(controller.MessageSaved(c), ShouldBeNil)

				Convey("we should not add the message to them", func() {
					m, err := topicChannel2.FetchLastMessage()
					So(err, ShouldBeNil)
					So(m, ShouldBeNil)
				})
			})

			Convey("if message has two hashTags", func() {
				topicChannel := models.CreateTypedGroupedChannelWithTest(account.Id, models.Channel_TYPE_TOPIC, groupName)

				// just a random topic name
				topicName := topicChannel.Name
				c := models.NewChannelMessage()
				c.InitialChannelId = topicChannel.Id
				c.AccountId = account.Id
				c.Body = "my test topic #" + topicName
				c.TypeConstant = models.ChannelMessage_TYPE_POST

				// create with unscoped
				err := bongo.B.Unscoped().Table(c.TableName()).Create(c).Error
				So(err, ShouldBeNil)

				So(controller.MessageSaved(c), ShouldBeNil)

				Convey("we should not add the message to them", func() {
					m, err := topicChannel.FetchLastMessage()
					So(err, ShouldBeNil)
					So(m, ShouldBeNil)
				})
			})
		})
	})
}

func TestFetchTopicChannel(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	appConfig := config.MustRead(r.Conf.Path)
	controller := New(r.Log, appConfig)

	Convey("while testing fetchTopicChannel", t, func() {
		account := models.CreateAccountWithTest()
		groupChannel := models.CreateTypedPublicChannelWithTest(
			account.Id,
			models.Channel_TYPE_GROUP,
		)

		normalChannel := models.NewChannel()
		normalChannel.CreatorId = account.Id
		normalChannel.GroupName = groupChannel.GroupName
		normalChannel.TypeConstant = models.Channel_TYPE_TOPIC
		normalChannel.PrivacyConstant = models.Channel_PRIVACY_PUBLIC
		So(normalChannel.Create(), ShouldBeNil)

		Convey("unlinked channels should be fetched normally", func() {
			c1, err := controller.fetchTopicChannel(normalChannel.GroupName, normalChannel.Name)
			So(err, ShouldBeNil)
			So(c1, ShouldNotBeNil)
			So(c1.Id, ShouldEqual, normalChannel.Id)
		})

		Convey("when we link to another channel", func() {

			rootChannel := models.NewChannel()
			rootChannel.CreatorId = account.Id
			rootChannel.GroupName = groupChannel.GroupName
			rootChannel.TypeConstant = models.Channel_TYPE_TOPIC
			rootChannel.PrivacyConstant = models.Channel_PRIVACY_PUBLIC
			So(rootChannel.Create(), ShouldBeNil)
			cl := &models.ChannelLink{
				RootId: rootChannel.Id,
				LeafId: normalChannel.Id,
			}
			So(cl.Create(), ShouldBeNil)

			// make it linked
			normalChannel.TypeConstant = models.Channel_TYPE_LINKED_TOPIC
			So(normalChannel.Update(), ShouldBeNil)

			Convey("it should fetch the root channel", func() {
				c2, err := controller.fetchTopicChannel(normalChannel.GroupName, normalChannel.Name)
				So(err, ShouldBeNil)
				So(c2, ShouldNotBeNil)
				So(c2.Id, ShouldEqual, rootChannel.Id)
			})
		})
	})
}

func TestMessageUpdated(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	// init mongo connection
	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	controller := topicfeed.New(r.Log, appConfig)

	Convey("while testing MessageUpdated", t, func() {

		Convey("if message is non-koding post", func() {
			account, groupChannel, groupName := models.CreateRandomGroupDataWithChecks()

			topicChannel := models.CreateTypedGroupedChannelWithTest(account.Id, models.Channel_TYPE_TOPIC, groupName)

			topicName := topicChannel.Name
			c := models.NewChannelMessage()
			c.InitialChannelId = groupChannel.Id
			c.AccountId = account.Id
			c.Body = "my test post with a hashTag #" + topicName
			c.TypeConstant = models.ChannelMessage_TYPE_POST

			// create with unscoped
			err := bongo.B.Unscoped().Table(c.TableName()).Create(c).Error
			So(err, ShouldBeNil)

			So(controller.MessageUpdated(c), ShouldBeNil)

			Convey("should not be posted to other channel", func() {
				m, err := topicChannel.FetchLastMessage()
				So(err, ShouldBeNil)
				So(m, ShouldBeNil)
			})
		})
		Convey("if message is a koding post", func() {
			account := models.CreateAccountWithTest()
			groupChannel := models.CreateTypedGroupedChannelWithTest(account.Id, models.Channel_TYPE_GROUP, "koding")

			topicChannel := models.CreateTypedGroupedChannelWithTest(account.Id, models.Channel_TYPE_TOPIC, "koding")

			topicName := topicChannel.Name
			c := models.NewChannelMessage()
			c.InitialChannelId = groupChannel.Id
			c.AccountId = account.Id
			c.Body = "my test post with a hashTag #" + topicName
			c.TypeConstant = models.ChannelMessage_TYPE_POST

			// create with unscoped
			err := bongo.B.Unscoped().Table(c.TableName()).Create(c).Error
			So(err, ShouldBeNil)

			So(controller.MessageUpdated(c), ShouldBeNil)

			Convey("should be posted to other channel", func() {
				m, err := topicChannel.FetchLastMessage()
				So(err, ShouldBeNil)
				So(m, ShouldNotBeNil)
				So(m.Id, ShouldEqual, c.Id)
			})
		})
	})
}

func TestMessageDeleted(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	// init mongo connection
	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	controller := topicfeed.New(r.Log, appConfig)

	Convey("while testing MessageDeleted", t, func() {

		account := models.CreateAccountWithTest()
		groupChannel := models.CreateTypedGroupedChannelWithTest(account.Id, models.Channel_TYPE_GROUP, "koding")
		topicChannel := models.CreateTypedGroupedChannelWithTest(account.Id, models.Channel_TYPE_TOPIC, "koding")

		topicName := topicChannel.Name
		c := models.NewChannelMessage()
		c.InitialChannelId = groupChannel.Id
		c.AccountId = account.Id
		c.Body = "my test post with a hashTag #" + topicName
		c.TypeConstant = models.ChannelMessage_TYPE_POST

		// create with unscoped
		err := bongo.B.Unscoped().Table(c.TableName()).Create(c).Error
		So(err, ShouldBeNil)

		So(controller.MessageSaved(c), ShouldBeNil)
		So(controller.MessageDeleted(c), ShouldBeNil)

		Convey("messages should be deleted from other channels", func() {
			m, err := topicChannel.FetchLastMessage()
			So(err, ShouldBeNil)
			So(m, ShouldBeNil)
		})
	})
}
