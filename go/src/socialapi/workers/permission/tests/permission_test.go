package permission

import (
	"koding/db/mongodb/modelhelper"

	"testing"

	"github.com/koding/runner"

	"labix.org/v2/mgo/bson"

	. "github.com/smartystreets/goconvey/convey"
)

var (
	AccountOldId  = bson.NewObjectId()
	AccountOldId2 = bson.NewObjectId()
)

func TestPermissionCreate(t *testing.T) {
	r := runner.New("permissiontest")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	modelhelper.Initialize(r.Conf.Mongo)
	defer modelhelper.Close()

	Convey("while creating channel permissions", t, func() {
		// Convey("First Create Users", func() {
		// 	owner := models.NewAccount()
		// 	owner.OldId = AccountOldId.Hex()
		// 	owner, err := rest.CreateAccount(owner)
		// 	So(err, ShouldBeNil)
		// 	So(owner, ShouldNotBeNil)

		// 	ownerSession, err := models.FetchOrCreateSession(owner.Nick)
		// 	So(err, ShouldBeNil)
		// 	So(ownerSession, ShouldNotBeNil)

		// 	nonOwnerAccount := models.NewAccount()
		// 	nonOwnerAccount.OldId = AccountOldId2.Hex()
		// 	nonOwnerAccount, err = rest.CreateAccount(nonOwnerAccount)
		// 	So(err, ShouldBeNil)
		// 	So(nonOwnerAccount, ShouldNotBeNil)

		// 	Convey("owner should create the channel", func() {
		// 		channel1, err := rest.CreateChannelByGroupNameAndType(owner.Id, "testgroup", models.Channel_TYPE_PRIVATE_MESSAGE)
		// 		So(err, ShouldBeNil)
		// 		So(channel1, ShouldNotBeNil)

		// 		perm := &models.Permission{
		// 			Name:           models.REQUEST_NAME_MESSAGE_UPDATE,
		// 			ChannelId:      channel1.Id,
		// 			RoleConstant:   models.Permission_ROLE_MODERATOR,
		// 			StatusConstant: models.Permission_STATUS_ALLOWED,
		// 		}

		// 		Convey("owner should create the permission for channel", func() {
		// 			permRes, err := rest.CreatePermission(perm, ownerSession.ClientId)
		// 			So(err, ShouldBeNil)
		// 			So(permRes, ShouldNotBeNil)

		// 			Convey("owner should be able update the permission", func() {
		// 				permRes.RoleConstant = models.Permission_ROLE_GUEST
		// 				permRes, err := rest.UpdatePermission(perm, ownerSession.ClientId)
		// 				So(err, ShouldBeNil)
		// 				So(permRes, ShouldNotBeNil)

		// 				So(permRes.RoleConstant, ShouldEqual, models.Permission_ROLE_GUEST)
		// 			})
		// 		})
		// 	})
		// })
	})
}
