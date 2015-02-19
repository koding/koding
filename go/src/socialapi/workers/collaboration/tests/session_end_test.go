package collaboration

import (
	"koding/db/mongodb/modelhelper"
	apimodels "socialapi/models"
	"socialapi/rest"
	"socialapi/workers/collaboration/models"
	"socialapi/workers/common/runner"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
	"labix.org/v2/mgo/bson"
)

var (
	AccountOldId = bson.NewObjectId()
)

func TestCollaborationSesionEnd(t *testing.T) {
	r := runner.New("collaboration-tests")
	err := r.Init()
	if err != nil {
		panic(err)
	}

	defer r.Close()

	modelhelper.Initialize(r.Conf.Mongo)
	defer modelhelper.Close()

	Convey("while testing collaboration session end", t, func() {

		Convey("we should be able to create a doc on google drive", func() {
			Convey("we should be able to delete a created doc", func() {
				Convey("deleting an already deleted doc should not give error", func() {
				})
			})
		})

		Convey("trying to delete a non-existing doc should not give error", func() {
		})
	})

	Convey("while pinging collaboration", t, func() {
		// owner
		owner := apimodels.NewAccount()
		owner.OldId = AccountOldId.Hex()
		owner, err := rest.CreateAccount(owner)
		So(err, ShouldBeNil)
		So(owner, ShouldNotBeNil)

		ownerSession, err := apimodels.FetchOrCreateSession(owner.Nick)
		So(err, ShouldBeNil)
		So(ownerSession, ShouldNotBeNil)

		Convey("reponse should be success", func() {
			p := &models.Ping{
				AccountId: 1,
				FileId:    "hello",
			}

			res, err := rest.CollaborationPing(p, ownerSession.ClientId)
			So(err, ShouldBeNil)
			So(res, ShouldNotBeNil)
		})
	})
}
