package collaboration

import (
	"fmt"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"math/rand"
	socialapimodels "socialapi/models"
	"socialapi/workers/collaboration/models"
	"socialapi/workers/common/runner"
	"socialapi/workers/helper"
	"strconv"

	"github.com/koding/bongo"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
)

func TestCollaborationOperationsDeleteDriveDoc(t *testing.T) {
	r := runner.New("collaboration-DeleteDriveDoc-tests")
	err := r.Init()
	if err != nil {
		panic(err)
	}

	defer r.Close()

	modelhelper.Initialize(r.Conf.Mongo)
	defer modelhelper.Close()

	redisConn := helper.MustInitRedisConn(r.Conf)
	defer redisConn.Close()

	handler := New(r.Log, redisConn, r.Conf, r.Kite)

	Convey("while testing DeleteDriveDoc", t, func() {
		req := &models.Ping{
			AccountId: 1,
			FileId:    fmt.Sprintf("%d", rand.Int63()),
		}
		Convey("should be able to create the file", func() {
			f, err := createTestFile(handler)
			So(err, ShouldBeNil)
			req.FileId = f.Id

			Convey("should be able to delete the created file", func() {
				err = handler.DeleteDriveDoc(req)
				So(err, ShouldBeNil)
			})

			Convey("if file id is nil response should be nil", func() {
				req := req
				req.FileId = ""
				err = handler.DeleteDriveDoc(req)
				So(err, ShouldBeNil)
			})
		})
	})
}

func TestCollaborationOperationsEndPrivateMessage(t *testing.T) {
	r := runner.New("collaboration-EndPrivateMessage-tests")
	err := r.Init()
	if err != nil {
		panic(err)
	}

	defer r.Close()

	modelhelper.Initialize(r.Conf.Mongo)
	defer modelhelper.Close()

	redisConn := helper.MustInitRedisConn(r.Conf)
	defer redisConn.Close()

	handler := New(r.Log, redisConn, r.Conf, r.Kite)

	Convey("while testing EndPrivateMessage", t, func() {
		req := &models.Ping{
			AccountId: 1,
			FileId:    fmt.Sprintf("%d", rand.Int63()),
		}
		Convey("should be able to create the channel first", func() {
			creator := socialapimodels.CreateAccountWithTest() // init account
			c := socialapimodels.NewChannel()                  // init channel
			c.CreatorId = creator.Id                           // set Creator id
			c.TypeConstant = socialapimodels.Channel_TYPE_COLLABORATION
			So(c.Create(), ShouldBeNil)
			cp, err := c.AddParticipant(creator.Id)
			So(err, ShouldBeNil)
			So(cp, ShouldNotBeNil)

			req.AccountId = c.CreatorId // set real account id
			req.ChannelId = c.Id        // set real channel id

			ws := &mongomodels.Workspace{
				ObjectId:     bson.NewObjectId(),
				Name:         "My Workspace",
				Slug:         "my-workspace",
				ChannelId:    strconv.FormatInt(req.ChannelId, 10),
				MachineUID:   bson.NewObjectId().Hex(),
				MachineLabel: "koding-vm-0",
				Owner:        "cihangir",
				RootPath:     "/home/cihangir",
				IsDefault:    true,
			}

			So(modelhelper.CreateWorkspace(ws), ShouldBeNil)

			Convey("should be able to delete channel", func() {
				err = handler.EndPrivateMessage(req)
				So(err, ShouldBeNil)
				Convey("deleted channel should not be exist", func() {
					channel := socialapimodels.NewChannel()
					err := channel.ById(req.ChannelId)
					So(err, ShouldEqual, bongo.RecordNotFound)
				})
				Convey("channel id in workspace should not be exist", func() {
					ws2, err := modelhelper.GetWorkspaceByChannelId(
						strconv.FormatInt(req.ChannelId, 10),
					)
					So(err, ShouldEqual, mgo.ErrNotFound)
					So(ws2, ShouldEqual, nil)
				})
			})

			Convey("if not a participant, should not be able to delete channel", func() {
				req.AccountId = 1
				err = handler.EndPrivateMessage(req)
				So(err, ShouldBeNil)
				Convey("channel should exist", func() {
					channel := socialapimodels.NewChannel()
					err := channel.ById(req.ChannelId)
					So(err, ShouldBeNil)
				})
			})

			Convey("if channel doesnt exists, should success", func() {
				req.ChannelId = 1
				err = handler.EndPrivateMessage(req)
				So(err, ShouldBeNil)
				Convey("channel should not exist", func() {
					channel := socialapimodels.NewChannel()
					err := channel.ById(req.ChannelId)
					So(err, ShouldEqual, bongo.RecordNotFound)
				})
			})
		})
	})
}

func TestCollaborationOperationsUnshareVM(t *testing.T) {
	r := runner.New("collaboration-UnshareVM-tests")
	err := r.Init()
	if err != nil {
		panic(err)
	}

	defer r.Close()

	modelhelper.Initialize(r.Conf.Mongo)
	defer modelhelper.Close()

	redisConn := helper.MustInitRedisConn(r.Conf)
	defer redisConn.Close()

	handler := New(r.Log, redisConn, r.Conf, r.Kite)

	Convey("while testing UnshareVM", t, func() {
		req := &models.Ping{
			AccountId: 1,
			FileId:    fmt.Sprintf("%d", rand.Int63()),
		}
		Convey("should be able to create the channel and workspace first", func() {
			creator := socialapimodels.CreateAccountWithTest() // init account
			c := socialapimodels.NewChannel()                  // init channel
			c.CreatorId = creator.Id                           // set Creator id
			c.TypeConstant = socialapimodels.Channel_TYPE_COLLABORATION
			So(c.Create(), ShouldBeNil)
			cp, err := c.AddParticipant(creator.Id)
			So(err, ShouldBeNil)
			So(cp, ShouldNotBeNil)

			req.AccountId = c.CreatorId // set real account id
			req.ChannelId = c.Id        // set real channel id

			// sample  machine struct
			m := &mongomodels.Machine{
				ObjectId: bson.NewObjectId(),
				Uid:      bson.NewObjectId().Hex(),
				Users: []mongomodels.MachineUser{

					mongomodels.MachineUser{ // real owner
						Id:    bson.ObjectIdHex(creator.OldId),
						Sudo:  true,
						Owner: true,
					},
					mongomodels.MachineUser{ // secondary owner
						Id:    bson.NewObjectId(),
						Sudo:  false,
						Owner: true,
					},
				},
				CreatedAt: time.Now().UTC(),
				Status: mongomodels.MachineStatus{
					State:      "running",
					ModifiedAt: time.Now().UTC(),
				},
				Assignee:    mongomodels.MachineAssignee{},
				UserDeleted: false,
			}

			So(modelhelper.CreateMachine(m), ShouldBeNil)

			ws := &mongomodels.Workspace{
				ObjectId:     bson.NewObjectId(),
				Name:         "My Workspace",
				Slug:         "my-workspace",
				ChannelId:    strconv.FormatInt(req.ChannelId, 10),
				MachineUID:   m.Uid,
				MachineLabel: "koding-vm-0",
				Owner:        "cihangir",
				RootPath:     "/home/cihangir",
				IsDefault:    true,
			}

			So(modelhelper.CreateWorkspace(ws), ShouldBeNil)

			Convey("should be able to UnshareVM", func() {
				err = handler.UnshareVM(req)
				So(err, ShouldBeNil)
				Convey("remove users should not be in the machine", func() {
					m2, err := modelhelper.GetMachineByUid(m.Uid)
					So(err, ShouldBeNil)
					So(m2, ShouldNotBeNil)
					So(len(m2.Users), ShouldEqual, 1)
					So(m2.Users[0].Id.Hex(), ShouldEqual, creator.OldId)
				})
			})
		})
	})
}
