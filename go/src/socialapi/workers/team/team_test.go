package team

import (
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"math"
	"socialapi/config"
	"socialapi/models"
	"strconv"

	"gopkg.in/mgo.v2/bson"

	"testing"

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
	})
}
