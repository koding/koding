package collaboration

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"math/rand"
	apimodels "socialapi/models"
	"socialapi/rest"
	"socialapi/workers/collaboration/models"
	"socialapi/workers/common/runner"
	"testing"
	"time"

	"socialapi/workers/collaboration"
	"socialapi/workers/helper"

	. "github.com/smartystreets/goconvey/convey"
	"labix.org/v2/mgo/bson"
)

var (
	AccountOldId = bson.NewObjectId()
)

func TestCollaborationPing(t *testing.T) {
	r := runner.New("collaboration-tests")
	err := r.Init()
	if err != nil {
		panic(err)
	}

	defer r.Close()

	modelhelper.Initialize(r.Conf.Mongo)
	defer modelhelper.Close()

	redisConn := helper.MustInitRedisConn(r.Conf)
	defer redisConn.Close()

	handler := New(r.Log, redisConn)

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

		rand.Seed(time.Now().UnixNano())

		req := &models.Ping{
			AccountId: 1,
			FileId:    fmt.Sprintf("%d", rand.Int63()),
		}

		Convey("reponse should be success", func() {
			err := handler.Ping(req)
			So(err, ShouldBeNil)
		})

		Convey("while testing checkIfKeyIsValid", func() {
			redis := helper.MustGetRedisConn()

			req := req
			req.CreatedAt = time.Now().UTC()

			err := redis.Setex(
				PrepareFileKey(req.FileId),
				collaboration.ExpireSessionKeyDuration, // expire the key after this period
				req.CreatedAt.Unix(),                   // value - unix time
			)

			So(err, ShouldBeNil)

			Convey("while testing checkIfKeyIsValid", func() {
				Convey("valid key should return nil", func() {
					err := handler.checkIfKeyIsValid(req)
					So(err, ShouldBeNil)
				})

				Convey("invalid key should return errSessionInvalid", func() {
					req := req
					// override fileId
					req.FileId = fmt.Sprintf("%d", rand.Int63())
					err := handler.checkIfKeyIsValid(req)
					So(err, ShouldEqual, errSessionInvalid)
				})

				Convey("invalid (non-timestamp) value should return errSessionInvalid", func() {
					req := req
					req.CreatedAt = time.Now().UTC()
					err := redis.Setex(
						PrepareFileKey(req.FileId),
						collaboration.ExpireSessionKeyDuration, // expire the key after this period
						"req.CreatedAt.Unix()",                 // replace timestamp with unix time
					)

					err = handler.checkIfKeyIsValid(req)
					So(err, ShouldEqual, errSessionInvalid)
				})

				Convey("old ping time should return errSessionInvalid", func() {
					req.CreatedAt = time.Now().UTC()
					err := redis.Setex(
						PrepareFileKey(req.FileId),
						collaboration.ExpireSessionKeyDuration, // expire the key after this period
						req.CreatedAt.Add(-terminateSessionDuration),
					)

					err = handler.checkIfKeyIsValid(req)
					So(err, ShouldEqual, errSessionInvalid)
				})

			})

			// err := handler.Ping(p)
			// So(err, ShouldBeNil)
		})
	})
}
