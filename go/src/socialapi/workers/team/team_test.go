package team

import (
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"math"
	"socialapi/config"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/moderation/topic"
	"strconv"

	"gopkg.in/mgo.v2/bson"

	"testing"
	"time"

	"github.com/koding/bongo"
	"github.com/koding/runner"

	. "github.com/smartystreets/goconvey/convey"
)

func TestTeam(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	appConfig := config.MustRead(r.Conf.Path)

	// init mongo connection
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	handler := NewController(r.Log, appConfig)

	Convey("given a group", t, func() {
		// create admin
		admin, err := models.CreateAccountInBothDbsWithNick("sinan")
		So(err, ShouldBeNil)
		So(admin, ShouldNotBeNil)

		acc1, err := models.CreateAccountInBothDbs()
		So(err, ShouldBeNil)
		So(acc1, ShouldNotBeNil)

		// create another account
		acc2, err := models.CreateAccountInBothDbs()
		So(err, ShouldBeNil)
		So(acc2, ShouldNotBeNil)

		groupName := models.RandomGroupName()

		groupChannel := models.CreateTypedGroupedChannelWithTest(admin.Id, models.Channel_TYPE_GROUP, groupName)
		So(groupChannel, ShouldNotBeNil)

		defaultChannel1 := models.CreateTypedGroupedChannelWithTest(admin.Id, models.Channel_TYPE_TOPIC, groupName)
		So(defaultChannel1, ShouldNotBeNil)

		defaultChannel2 := models.CreateTypedGroupedChannelWithTest(admin.Id, models.Channel_TYPE_TOPIC, groupName)
		So(defaultChannel2, ShouldNotBeNil)

		group := &mongomodels.Group{
			Id:                 bson.NewObjectId(),
			Body:               groupName,
			Title:              groupName,
			Slug:               groupName,
			Privacy:            "private",
			Visibility:         "hidden",
			SocialApiChannelId: strconv.FormatInt(groupChannel.Id, 10),
			DefaultChannels: []string{
				strconv.FormatInt(defaultChannel1.Id, 10),
				strconv.FormatInt(defaultChannel2.Id, 10),
			},
		}

		err = modelhelper.CreateGroup(group)
		So(err, ShouldBeNil)

		Convey("should success if channel is not in db", func() {
			cp := &models.ChannelParticipant{
				AccountId: acc1.Id,
				ChannelId: math.MaxInt64,
			}
			err := handler.HandleParticipant(cp)
			So(err, ShouldBeNil)
		})

		Convey("should success if channel is not a group channel", func() {
			cp := &models.ChannelParticipant{
				AccountId: acc1.Id,
				ChannelId: defaultChannel1.Id,
			}
			err := handler.HandleParticipant(cp)
			So(err, ShouldBeNil)
		})

		Convey("should success if group is not in mongo", func() {
			groupName := models.RandomGroupName()

			groupChan := models.CreateTypedGroupedChannelWithTest(admin.Id, models.Channel_TYPE_GROUP, groupName)
			So(groupChan, ShouldNotBeNil)

			cp := &models.ChannelParticipant{
				AccountId: acc1.Id,
				ChannelId: groupChan.Id,
			}
			err := handler.HandleParticipant(cp)
			So(err, ShouldBeNil)
		})

		Convey("new participant should be in default channels", func() {
			cp := &models.ChannelParticipant{
				AccountId:      acc1.Id,
				ChannelId:      groupChannel.Id,
				StatusConstant: models.ChannelParticipant_STATUS_ACTIVE,
			}
			err := handler.HandleParticipant(cp)
			So(err, ShouldBeNil)

			isParticipant, err := defaultChannel1.IsParticipant(acc1.Id)
			So(err, ShouldBeNil)
			So(isParticipant, ShouldBeTrue)

			isParticipant, err = defaultChannel2.IsParticipant(acc1.Id)
			So(err, ShouldBeNil)
			So(isParticipant, ShouldBeTrue)

			Convey("after leaving group channel", func() {
				cp := &models.ChannelParticipant{
					AccountId:      acc1.Id,
					ChannelId:      groupChannel.Id,
					StatusConstant: models.ChannelParticipant_STATUS_LEFT,
				}
				err := handler.HandleParticipant(cp)
				So(err, ShouldBeNil)

				Convey("should be removed from default channels", func() {
					isParticipant, err := defaultChannel1.IsParticipant(acc1.Id)
					So(err, ShouldBeNil)
					So(isParticipant, ShouldBeFalse)

					isParticipant, err = defaultChannel2.IsParticipant(acc1.Id)
					So(err, ShouldBeNil)
					So(isParticipant, ShouldBeFalse)
				})

				Convey("should be removed from all channels", func() {
					ids, err := cp.FetchAllParticipatedChannelIdsInGroup(cp.AccountId, groupChannel.GroupName)
					So(err, ShouldBeNil)
					So(len(ids), ShouldEqual, 0)
				})
			})

			Convey("after being blocked", func() {
				cp := &models.ChannelParticipant{
					AccountId:      acc1.Id,
					ChannelId:      groupChannel.Id,
					StatusConstant: models.ChannelParticipant_STATUS_BLOCKED,
				}
				err := handler.HandleParticipant(cp)
				So(err, ShouldBeNil)

				Convey("should be removed from default channels", func() {
					isParticipant, err := defaultChannel1.IsParticipant(acc1.Id)
					So(err, ShouldBeNil)
					So(isParticipant, ShouldBeFalse)

					isParticipant, err = defaultChannel2.IsParticipant(acc1.Id)
					So(err, ShouldBeNil)
					So(isParticipant, ShouldBeFalse)
				})
			})
		})

		Convey("should success if default channels is not available anymore", func() {
			// delete the channel
			So(defaultChannel1.Delete(), ShouldBeNil)

			cp := &models.ChannelParticipant{
				AccountId:      acc1.Id,
				ChannelId:      groupChannel.Id,
				StatusConstant: models.ChannelParticipant_STATUS_ACTIVE,
			}
			err := handler.HandleParticipant(cp)
			So(err, ShouldBeNil)
		})

		Convey("should success if default channels is liked to another", func() {
			// create topic moderation controller
			linker := topic.NewController(r.Log, appConfig)
			cl := &models.ChannelLink{
				RootId: defaultChannel1.Id,
				LeafId: defaultChannel2.Id,
			}

			So(cl.Create(), ShouldBeNil)

			So(linker.Create(cl), ShouldBeNil)

			cp := &models.ChannelParticipant{
				AccountId:      acc1.Id,
				ChannelId:      groupChannel.Id,
				StatusConstant: models.ChannelParticipant_STATUS_ACTIVE,
			}

			err = handler.HandleParticipant(cp)
			So(err, ShouldBeNil)

			isParticipant, err := defaultChannel1.IsParticipant(acc1.Id)
			So(err, ShouldBeNil)
			So(isParticipant, ShouldBeTrue)

			isParticipant, err = defaultChannel2.IsParticipant(acc1.Id)
			So(err, ShouldBeNil)
			So(isParticipant, ShouldBeFalse)
		})
	})
}

func TestDeleteGroupChannel(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	appConfig := config.MustRead(r.Conf.Path)

	// init mongo connection
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	handler := NewController(r.Log, appConfig)

	Convey("when deleting a group channel", t, func() {
		account, groupChannel, groupName := models.CreateRandomGroupDataWithChecks()

		Convey("it should create channel, message and dependencies", func() {
			channel1 := models.CreateTypedGroupedChannelWithTest(account.Id, models.Channel_TYPE_TOPIC, groupName)
			channel2 := models.CreateTypedGroupedChannelWithTest(account.Id, models.Channel_TYPE_TOPIC, groupName)

			message1 := models.CreateMessage(channel1.Id, account.Id, models.ChannelMessage_TYPE_POST)
			message2 := models.CreateMessage(channel2.Id, account.Id, models.ChannelMessage_TYPE_POST)

			int1, err := models.AddInteractionWithTest(models.Interaction_TYPE_LIKE, message1.Id, account.Id)
			So(int1, ShouldNotBeNil)
			So(err, ShouldBeNil)

			int2, err := models.AddInteractionWithTest(models.Interaction_TYPE_LIKE, message2.Id, account.Id)
			So(int2, ShouldNotBeNil)
			So(err, ShouldBeNil)

			msg1 := models.CreateMessageWithTest()
			So(msg1.Create(), ShouldBeNil)

			cm, err := message1.AddReply(msg1)
			So(err, ShouldBeNil)
			So(cm.MessageId, ShouldEqual, message1.Id)
			Convey("it should fetch replies and interactions", func() {
				cml1, err := channel1.FetchMessageList(message1.Id)
				So(err, ShouldBeNil)
				So(cml1, ShouldNotBeNil)
				So(cml1.MessageId, ShouldEqual, message1.Id)

				query := request.NewQuery()
				query.AccountId = account.Id
				query.Type = models.Interaction_TYPE_LIKE
				messages, err := models.NewInteraction().ListLikedMessages(query, channel1.Id)
				So(err, ShouldBeNil)
				So(messages, ShouldNotBeNil)

				icm := models.NewChannelMessage()
				err = icm.ById(msg1.Id)
				So(err, ShouldBeNil)

			})
			Convey("after deleting group channel", func() {
				err = groupChannel.Delete()
				So(err, ShouldBeNil)
				err = handler.HandleChannel(groupChannel)
				So(err, ShouldBeNil)
				Convey("it should not fetch replies and interactions", func() {
					time.Sleep(1 * time.Second)
					_, err := channel1.FetchMessageList(message1.Id)
					So(err, ShouldNotBeNil)
					So(err, ShouldEqual, bongo.RecordNotFound)

					query := request.NewQuery()
					query.AccountId = account.Id
					query.Type = models.Interaction_TYPE_LIKE
					messages, err := models.NewInteraction().ListLikedMessages(query, channel1.Id)
					So(err, ShouldBeNil)
					So(messages, ShouldBeNil)

					icm := models.NewChannelMessage()
					err = icm.ById(message1.Id)
					So(err, ShouldNotBeNil)
					So(err, ShouldEqual, bongo.RecordNotFound)
				})
			})
		})
	})

}
