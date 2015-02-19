package collaboration

import (
	"bytes"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"math/rand"
	apimodels "socialapi/models"
	"socialapi/rest"
	"socialapi/workers/collaboration/models"
	"socialapi/workers/common/runner"
	"testing"
	"time"

	"code.google.com/p/google-api-go-client/drive/v2"

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

	redis := helper.MustGetRedisConn()

	handler := New(r.Log, redisConn, r.Conf)

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

		Convey("while testing Ping", func() {
			Convey("reponse should be success with valid ping", func() {
				err := handler.Ping(req)
				So(err, ShouldBeNil)
			})

			Convey("reponse should be success with invalid FileId", func() {
				req.FileId = ""
				err := handler.Ping(req)
				So(err, ShouldBeNil)
			})

			Convey("reponse should be success with invalid AccountId", func() {
				req.AccountId = 0
				err := handler.Ping(req)
				So(err, ShouldBeNil)
			})

			Convey("reponse should be success with invalid session", func() {
				req := req
				// prepare an invalid session here
				req.CreatedAt = time.Now().UTC()
				err := redis.Setex(
					PrepareFileKey(req.FileId),
					collaboration.ExpireSessionKeyDuration, // expire the key after this period
					req.CreatedAt.Add(-terminateSessionDuration),
				)

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
					err := redis.Setex(
						PrepareFileKey(req.FileId),
						terminateSessionDuration, // expire the key after this period
						req.CreatedAt.Unix(),     // value - unix time
					)

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
			err := redis.Setex(
				PrepareFileKey(req.FileId),
				collaboration.ExpireSessionKeyDuration, // expire the key after this period
				req.CreatedAt.Unix(),                   // value - unix time
			)

			So(err, ShouldBeNil)

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
				req := req
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

		Convey("while testing drive operations", func() {
			req := req
			req.CreatedAt = time.Now().UTC()
			Convey("should be able to create the file", func() {
				f, err := createFile(handler)
				So(err, ShouldBeNil)
				req.FileId = f.Id
				Convey("should be able to get the created file", func() {
					f2, err := handler.getFile(f.Id)
					So(err, ShouldBeNil)
					So(f2, ShouldNotBeNil)
					Convey("should be able to delete the created file", func() {
						err = handler.deleteFile(req.FileId)
						So(err, ShouldBeNil)
						Convey("should not be able to get the deleted file", func() {
							f2, err = handler.getFile(f.Id)
							So(err, ShouldNotBeNil)
							So(f2, ShouldBeNil)
						})
						Convey("deleting the deleted file should not give error", func() {
							err = handler.deleteFile(req.FileId)
							So(err, ShouldBeNil)
						})
					})
				})
			})
		})
	})
}

func createFile(c *Controller) (*drive.File, error) {
	svc, err := c.createService()
	if err != nil {
		return nil, err
	}

	// Define the metadata for the file we are going to create.
	f := &drive.File{
		Title:       "My Document",
		Description: "My test document",
	}

	m := bytes.NewReader([]byte(`selamlar nasilsin?`))
	// Make the API request to upload metadata and file data.
	r, err := svc.Files.Insert(f).Media(m).Do()
	if err != nil {
		return nil, err
	}

	return r, nil
}
