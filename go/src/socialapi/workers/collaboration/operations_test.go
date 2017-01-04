package collaboration

import (
	"fmt"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"math/rand"
	"socialapi/config"
	socialapimodels "socialapi/models"
	"socialapi/workers/collaboration/models"
	"strconv"
	"testing"
	"time"

	"github.com/koding/bongo"
	"github.com/koding/cache"
	"github.com/koding/runner"
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"

	. "github.com/smartystreets/goconvey/convey"
)

func TestCollaborationOperationsDeleteDriveDoc(t *testing.T) {
	r := runner.New("collaboration-DeleteDriveDoc-tests")
	err := r.Init()
	if err != nil {
		panic(err)
	}

	defer r.Close()

	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	// init with defaults
	mongoCache := cache.NewMongoCacheWithTTL(modelhelper.Mongo.Session)
	defer mongoCache.StopGC()

	handler := New(r.Log, mongoCache, appConfig, r.Kite)

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

	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	// init with defaults
	mongoCache := cache.NewMongoCacheWithTTL(modelhelper.Mongo.Session)
	defer mongoCache.StopGC()

	handler := New(r.Log, mongoCache, appConfig, r.Kite)

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
				OriginId:     bson.NewObjectId(),
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

	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	// init with defaults
	mongoCache := cache.NewMongoCacheWithTTL(modelhelper.Mongo.Session)
	defer mongoCache.StopGC()

	handler := New(r.Log, mongoCache, appConfig, r.Kite)

	Convey("while testing UnshareVM", t, func() {

		Convey("should be able to create the channel and workspace first", func() {

			Convey("should be able to UnshareVM", func() {

				creator, err := socialapimodels.CreateAccountInBothDbs() // init account
				So(err, ShouldBeNil)

				participant1, err := socialapimodels.CreateAccountInBothDbs()
				So(err, ShouldBeNil)

				participant2, err := socialapimodels.CreateAccountInBothDbs()
				So(err, ShouldBeNil)

				m1, m1ws1 := prepareSingleWorkspace(creator, participant1, participant2)

				channelId, err := strconv.ParseInt(m1ws1.ChannelId, 10, 64)
				So(err, ShouldBeNil)

				req1 := &models.Ping{
					AccountId: creator.Id,
					FileId:    fmt.Sprintf("%d", rand.Int63()),
					ChannelId: channelId,
				}

				toBeRemovedUsers, err := handler.findToBeRemovedUsers(req1)
				So(err, ShouldBeNil)
				So(toBeRemovedUsers, ShouldNotBeNil)

				err = handler.UnshareVM(req1, toBeRemovedUsers)
				So(err, ShouldBeNil)

				err = handler.EndPrivateMessage(req1)
				So(err, ShouldBeNil)

				Convey("remove users should not be in the machine", func() {
					mm1, err := modelhelper.GetMachineByUid(m1.Uid)
					So(err, ShouldBeNil)
					So(mm1, ShouldNotBeNil)
					So(len(mm1.Users), ShouldEqual, 1)
					ownerUser, err := modelhelper.GetUserByAccountId(creator.OldId)
					So(err, ShouldBeNil)
					So(mm1.Users[0].Id.Hex(), ShouldEqual, ownerUser.ObjectId.Hex())
				})
			})

			Convey("if participant and owner shares multiple workspaces", func() {

				creator, err := socialapimodels.CreateAccountInBothDbs() // init account
				So(err, ShouldBeNil)

				participant1, err := socialapimodels.CreateAccountInBothDbs()
				So(err, ShouldBeNil)

				participant2, err := socialapimodels.CreateAccountInBothDbs()
				So(err, ShouldBeNil)

				participant3, err := socialapimodels.CreateAccountInBothDbs()
				So(err, ShouldBeNil)

				_, _, m2, m2ws1, m2ws2 := prepareWorkspace(creator, participant1, participant2, participant3)

				Convey("remove from first workspace", func() {
					channelId, err := strconv.ParseInt(m2ws1.ChannelId, 10, 64)
					So(err, ShouldBeNil)

					req := &models.Ping{
						AccountId: creator.Id,
						FileId:    fmt.Sprintf("%d", rand.Int63()),
						ChannelId: channelId,
					}

					toBeRemovedUsers, err := handler.findToBeRemovedUsers(req)
					So(err, ShouldBeNil)
					So(toBeRemovedUsers, ShouldNotBeNil)

					err = handler.UnshareVM(req, toBeRemovedUsers)
					So(err, ShouldBeNil)

					err = handler.EndPrivateMessage(req)
					So(err, ShouldBeNil)

					Convey("participants should still be in the second machine", func() {
						mm2, err := modelhelper.GetMachineByUid(m2.Uid)
						So(err, ShouldBeNil)
						So(mm2, ShouldNotBeNil)
						So(len(mm2.Users), ShouldEqual, 3)

						// participant1 is not in the second WS, so it should be removed from the machine
						ownerUser, err := modelhelper.GetUserByAccountId(creator.OldId)
						So(err, ShouldBeNil)
						So(mm2.Users[0].Id.Hex(), ShouldEqual, ownerUser.ObjectId.Hex())

						participant2User, err := modelhelper.GetUserByAccountId(participant2.OldId)
						So(err, ShouldBeNil)
						So(mm2.Users[1].Id.Hex(), ShouldEqual, participant2User.ObjectId.Hex())

						participant3User, err := modelhelper.GetUserByAccountId(participant3.OldId)
						So(err, ShouldBeNil)
						So(mm2.Users[2].Id.Hex(), ShouldEqual, participant3User.ObjectId.Hex())

						Convey("after removing from second WS", func() {
							// remove from second WS too
							channelId, err := strconv.ParseInt(m2ws2.ChannelId, 10, 64)
							So(err, ShouldBeNil)

							req := &models.Ping{
								AccountId: creator.Id,
								FileId:    fmt.Sprintf("%d", rand.Int63()),
								ChannelId: channelId,
							}

							toBeRemovedUsers, err := handler.findToBeRemovedUsers(req)
							So(err, ShouldBeNil)
							So(toBeRemovedUsers, ShouldNotBeNil)

							err = handler.UnshareVM(req, toBeRemovedUsers)
							So(err, ShouldBeNil)

							err = handler.EndPrivateMessage(req)
							So(err, ShouldBeNil)

							Convey("owner and permanent should still stay", func() {
								mm2, err := modelhelper.GetMachineByUid(m2.Uid)
								So(err, ShouldBeNil)
								So(mm2, ShouldNotBeNil)
								So(len(mm2.Users), ShouldEqual, 2)

								ownerUser, err := modelhelper.GetUserByAccountId(creator.OldId)
								So(err, ShouldBeNil)
								So(mm2.Users[0].Id.Hex(), ShouldEqual, ownerUser.ObjectId.Hex())

								participant1User, err := modelhelper.GetUserByAccountId(participant3.OldId)
								So(err, ShouldBeNil)
								So(mm2.Users[1].Id.Hex(), ShouldEqual, participant1User.ObjectId.Hex())
							})
						})
					})
				})
			})
		})
	})
}

// create 2 machines
// 	first one will have 1 WS
//  	1 owner + 2 participant + 1 permanent
// 	second one will have 2 WS
// 		first ws will have 4 participants
//   		1 owner + 2 participant + 1 permanent
//     	second one
//      	1 owner + 2 participant
//  no matter what we do with user removal, owner and the permanent should stay
//  in the machine
func prepareWorkspace(creator, participant1, participant2, participant3 *socialapimodels.Account) (
	*mongomodels.Machine, // m1
	*mongomodels.Workspace, // m1 ws1
	*mongomodels.Machine, // m2
	*mongomodels.Workspace, // m2 ws1
	*mongomodels.Workspace, // m2 ws2
) {

	m1, m1ws1 := prepareSingleWorkspace(creator, participant1, participant2)

	ownerUser, err := modelhelper.GetUserByAccountId(creator.OldId)
	So(err, ShouldBeNil)

	participant1User, err := modelhelper.GetUserByAccountId(participant1.OldId)
	So(err, ShouldBeNil)

	participant2User, err := modelhelper.GetUserByAccountId(participant2.OldId)
	So(err, ShouldBeNil)

	participant3User, err := modelhelper.GetUserByAccountId(participant3.OldId)
	So(err, ShouldBeNil)

	// sample  machine struct
	m2 := &mongomodels.Machine{
		ObjectId: bson.NewObjectId(),
		Uid:      bson.NewObjectId().Hex(),
		Users: []mongomodels.MachineUser{
			{ // real owner
				Id:    ownerUser.ObjectId,
				Sudo:  true,
				Owner: true,
			},
			{ // secondary owner
				Id:    participant1User.ObjectId,
				Sudo:  false,
				Owner: true,
			},
			{ // random
				Id:    participant2User.ObjectId,
				Sudo:  false,
				Owner: true,
			},
			{ // random
				Id:        participant3User.ObjectId,
				Sudo:      false,
				Owner:     true,
				Permanent: true,
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

	So(modelhelper.CreateMachine(m2), ShouldBeNil)

	c3 := socialapimodels.NewChannel() // init channel
	c3.CreatorId = creator.Id          // set Creator id
	c3.TypeConstant = socialapimodels.Channel_TYPE_COLLABORATION
	So(c3.Create(), ShouldBeNil)

	c3p1, err := c3.AddParticipant(creator.Id)
	So(err, ShouldBeNil)
	So(c3p1, ShouldNotBeNil)

	c3p2, err := c3.AddParticipant(participant1.Id)
	So(err, ShouldBeNil)
	So(c3p2, ShouldNotBeNil)

	c3p3, err := c3.AddParticipant(participant2.Id)
	So(err, ShouldBeNil)
	So(c3p3, ShouldNotBeNil)

	c3p4, err := c3.AddParticipant(participant3.Id)
	So(err, ShouldBeNil)
	So(c3p4, ShouldNotBeNil)

	c4 := socialapimodels.NewChannel() // init channel
	c4.CreatorId = creator.Id          // set Creator id
	c4.TypeConstant = socialapimodels.Channel_TYPE_COLLABORATION
	So(c4.Create(), ShouldBeNil)

	c4p1, err := c4.AddParticipant(creator.Id)
	So(err, ShouldBeNil)
	So(c4p1, ShouldNotBeNil)

	// do not add the 1st user to the second WS
	// c4p2, err := c4.AddParticipant(participant1.Id)
	// So(err, ShouldBeNil)
	// So(c4p2, ShouldNotBeNil)

	c4p3, err := c4.AddParticipant(participant2.Id)
	So(err, ShouldBeNil)
	So(c4p3, ShouldNotBeNil)

	c4p4, err := c4.AddParticipant(participant3.Id)
	So(err, ShouldBeNil)
	So(c4p4, ShouldNotBeNil)

	m2ws1 := &mongomodels.Workspace{
		ObjectId:     bson.NewObjectId(),
		OriginId:     bson.ObjectIdHex(creator.OldId),
		Name:         "My Workspace",
		Slug:         "m2ws1",
		ChannelId:    strconv.FormatInt(c3.Id, 10),
		MachineUID:   m2.Uid,
		MachineLabel: "koding-vm-0",
		Owner:        "cihangir",
		RootPath:     "/home/cihangir",
		IsDefault:    true,
	}

	So(modelhelper.CreateWorkspace(m2ws1), ShouldBeNil)

	m2ws2 := &mongomodels.Workspace{
		ObjectId:     bson.NewObjectId(),
		OriginId:     bson.ObjectIdHex(creator.OldId),
		Name:         "My Workspace",
		Slug:         "m2ws2",
		ChannelId:    strconv.FormatInt(c4.Id, 10),
		MachineUID:   m2.Uid,
		MachineLabel: "koding-vm-0",
		Owner:        "cihangir",
		RootPath:     "/home/cihangir",
		IsDefault:    true,
	}

	So(modelhelper.CreateWorkspace(m2ws2), ShouldBeNil)

	return m1, m1ws1, m2, m2ws1, m2ws2
}

func prepareSingleWorkspace(creator, participant1, participant2 *socialapimodels.Account) (
	*mongomodels.Machine, // m1
	*mongomodels.Workspace, // m1 ws1
) {

	ownerUser, err := modelhelper.GetUserByAccountId(creator.OldId)
	So(err, ShouldBeNil)

	participant1User, err := modelhelper.GetUserByAccountId(participant1.OldId)
	So(err, ShouldBeNil)

	participant2User, err := modelhelper.GetUserByAccountId(participant2.OldId)
	So(err, ShouldBeNil)

	// sample  machine struct
	m1 := &mongomodels.Machine{
		ObjectId: bson.NewObjectId(),
		Uid:      bson.NewObjectId().Hex(),
		Users: []mongomodels.MachineUser{
			{ // real owner
				Id:    ownerUser.ObjectId,
				Sudo:  true,
				Owner: true,
			},
			{ // secondary owner
				Id:        participant1User.ObjectId,
				Sudo:      false,
				Owner:     true,
				Permanent: false,
			},
			{ // random
				Id:        participant2User.ObjectId,
				Sudo:      false,
				Owner:     true,
				Permanent: false,
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

	So(modelhelper.CreateMachine(m1), ShouldBeNil)

	//
	// create the first channel
	//
	c1 := socialapimodels.NewChannel() // init channel
	c1.CreatorId = creator.Id          // set Creator id
	c1.TypeConstant = socialapimodels.Channel_TYPE_COLLABORATION
	So(c1.Create(), ShouldBeNil)

	c1p1, err := c1.AddParticipant(creator.Id)
	So(err, ShouldBeNil)
	So(c1p1, ShouldNotBeNil)

	c1p2, err := c1.AddParticipant(participant1.Id)
	So(err, ShouldBeNil)
	So(c1p2, ShouldNotBeNil)

	c1p3, err := c1.AddParticipant(participant2.Id)
	So(err, ShouldBeNil)
	So(c1p3, ShouldNotBeNil)

	m1ws1 := &mongomodels.Workspace{
		ObjectId:     bson.NewObjectId(),
		OriginId:     bson.ObjectIdHex(creator.OldId),
		Name:         "My Workspace",
		Slug:         "m1ws1",
		ChannelId:    strconv.FormatInt(c1.Id, 10),
		MachineUID:   m1.Uid,
		MachineLabel: "koding-vm-0",
		Owner:        "cihangir",
		RootPath:     "/home/cihangir",
		IsDefault:    true,
	}

	So(modelhelper.CreateWorkspace(m1ws1), ShouldBeNil)

	return m1, m1ws1
}
