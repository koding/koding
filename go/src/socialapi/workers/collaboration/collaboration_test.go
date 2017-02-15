package collaboration

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"math/rand"
	"socialapi/config"
	apimodels "socialapi/models"
	"socialapi/rest"
	"socialapi/workers/collaboration/models"
	"strconv"
	"testing"
	"time"

	"github.com/koding/cache"
	"github.com/koding/runner"

	. "github.com/smartystreets/goconvey/convey"
	"gopkg.in/mgo.v2/bson"
)

var (
	AccountOldId = bson.NewObjectId()
)

func TestCollaboration(t *testing.T) {
	r := runner.New("collaboration-tests")
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

	Convey("while pinging collaboration", t, func() {
		// owner
		owner := apimodels.NewAccount()
		owner.OldId = AccountOldId.Hex()
		owner, err := rest.CreateAccount(owner)
		So(err, ShouldBeNil)
		So(owner, ShouldNotBeNil)

		groupName := apimodels.RandomGroupName()

		ownerSession, err := modelhelper.FetchOrCreateSession(owner.Nick, groupName)
		So(err, ShouldBeNil)
		So(ownerSession, ShouldNotBeNil)

		rand.Seed(time.Now().UnixNano())

		req := &models.Ping{
			AccountId: 1,
			FileId:    fmt.Sprintf("%d", rand.Int63()),
		}

		Convey("while testing Ping", func() {
			Convey("response should be success with valid ping", func() {
				err = handler.Ping(req)
				So(err, ShouldBeNil)
			})

			Convey("response should be success with invalid FileId", func() {
				req.FileId = ""
				err = handler.Ping(req)
				So(err, ShouldBeNil)
			})

			Convey("response should be success with invalid AccountId", func() {
				req.AccountId = 0
				err = handler.Ping(req)
				So(err, ShouldBeNil)
			})

			Convey("response should be success with invalid session", func() {
				req := req
				// prepare an invalid session here
				req.CreatedAt = time.Now().UTC()

				err = mongoCache.SetEx(PrepareFileKey(req.FileId), ExpireSessionKeyDuration, req.CreatedAt.Add(-terminateSessionDuration))

				err = handler.Ping(req)
				So(err, ShouldBeNil)
			})

			Convey("after sleep time", func() {
				req := req

				Convey("expired session should get invalidSessoin", func() {
					st := sleepTime
					sleepTime = time.Millisecond * 110

					tsd := terminateSessionDuration
					terminateSessionDuration = 100

					// set durations back to the original value
					defer func() {
						sleepTime = st
						terminateSessionDuration = tsd
					}()

					req.CreatedAt = time.Now().UTC()
					// prepare a valid key
					err = mongoCache.SetEx(
						PrepareFileKey(req.FileId),
						terminateSessionDuration, // expire the key after this period
						req.CreatedAt.Unix())

					// while sleeping here, redis key should be removed
					// and we can understand that the Collab session is expired
					time.Sleep(sleepTime)

					req := req
					err = handler.wait(req)
					So(err, ShouldEqual, errSessionInvalid)
				})

				Convey("deadlined session should get errDeadlineReached", func() {
					st := sleepTime
					sleepTime = time.Millisecond * 110

					dd := deadLineDuration
					deadLineDuration = 100

					// set durations back to the original value
					defer func() {
						sleepTime = st
						deadLineDuration = dd
					}()

					req := req
					err := handler.wait(req)
					So(err, ShouldEqual, errDeadlineReached)
				})
			})
		})

		Convey("while testing checkIfKeyIsValid", func() {

			req := req
			req.CreatedAt = time.Now().UTC()

			// prepare a valid key
			err := mongoCache.SetEx(
				PrepareFileKey(req.FileId),
				ExpireSessionKeyDuration, // expire the key after this period
				req.CreatedAt.Unix(),     // value - unix time
			)

			So(err, ShouldBeNil)

			Convey("valid key should return nil", func() {
				err = handler.checkIfKeyIsValid(req)
				So(err, ShouldBeNil)
			})

			Convey("invalid key should return errSessionInvalid", func() {
				req := req
				// override fileId
				req.FileId = fmt.Sprintf("%d", rand.Int63())
				err = handler.checkIfKeyIsValid(req)
				So(err, ShouldEqual, errSessionInvalid)
			})

			Convey("invalid (non-timestamp) value should return errSessionInvalid", func() {
				req := req
				req.CreatedAt = time.Now().UTC()
				err = mongoCache.SetEx(
					PrepareFileKey(req.FileId),
					ExpireSessionKeyDuration, // expire the key after this period
					"req.CreatedAt.Unix()",   // replace timestamp with unix time
				)

				err = handler.checkIfKeyIsValid(req)

				So(err, ShouldEqual, errSessionInvalid)
			})

			Convey("old ping time should return errSessionInvalid", func() {
				req := req
				req.CreatedAt = time.Now().UTC()
				err = mongoCache.SetEx(
					PrepareFileKey(req.FileId),
					ExpireSessionKeyDuration, // expire the key after this period
					req.CreatedAt.Add(-terminateSessionDuration).Unix(),
				)

				err = handler.checkIfKeyIsValid(req)
				So(err, ShouldEqual, errSessionInvalid)
			})

			Convey("previous ping time is in safe area", func() {
				req := req
				testPingTimes(req, -1, mongoCache, handler, nil)
			})

			Convey("0 ping time is in safe area", func() {
				req := req
				testPingTimes(req, 0, mongoCache, handler, nil)
			})

			Convey("2 ping time is in safe area", func() {
				req := req
				testPingTimes(req, 2, mongoCache, handler, nil)
			})

			Convey("3 ping time is in safe area", func() {
				req := req
				testPingTimes(req, 3, mongoCache, handler, nil)
			})

			Convey("4 ping time is not in safe area - because we already reverted the time ", func() {
				req := req
				testPingTimes(req, 4, mongoCache, handler, errSessionInvalid)
			})

			Convey("5 ping time is not in safe area ", func() {
				req := req
				testPingTimes(req, 5, mongoCache, handler, errSessionInvalid)
			})
		})
	})
}

func testPingTimes(
	req *models.Ping,
	pingCount int,
	mongoCache *cache.MongoCache,
	handler *Controller,
	expectedErr error,
) {
	req.FileId = req.FileId + strconv.Itoa(pingCount)
	req.CreatedAt = time.
		Now().
		UTC().
		Add(-pingDuration * time.Duration(pingCount))

	mongoCache.SetEx(
		PrepareFileKey(req.FileId),
		ExpireSessionKeyDuration, // expire the key after this period
		req.CreatedAt.Unix(),
	)

	err := handler.checkIfKeyIsValid(req)
	So(err, ShouldEqual, expectedErr)
}
