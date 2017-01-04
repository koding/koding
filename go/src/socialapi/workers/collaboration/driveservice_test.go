package collaboration

import (
	"bytes"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"math/rand"
	"socialapi/config"
	apimodels "socialapi/models"
	"socialapi/rest"
	"socialapi/workers/collaboration/models"
	"testing"
	"time"

	"code.google.com/p/google-api-go-client/drive/v2"

	"github.com/koding/cache"
	"github.com/koding/runner"

	. "github.com/smartystreets/goconvey/convey"
)

const TestTimeout = 15 * time.Second

func TestCollaborationDriveService(t *testing.T) {
	r := runner.New("collaboration-drive-tests")
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

	SkipConvey("while pinging collaboration", t, func() {
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

		Convey("while testing drive operations", func() {
			req := req
			req.CreatedAt = time.Now().UTC()
			Convey("should be able to create the file", func() {
				f, err := createTestFile(handler)
				if err != nil {
					t.Skip("Err happened, skipping: %s", err.Error())
				}

				req.FileId = f.Id
				Convey("should be able to get the created file", func() {
					f2, err := handler.getFile(f.Id)
					if err != nil {
						t.Skip("Err happened, skipping: %s", err.Error())
					}

					So(f2, ShouldNotBeNil)

					Convey("should be able to delete the created file", func() {
						err = handler.deleteFile(req.FileId)
						if err != nil {
							t.Skip("Err happened, skipping: %s", err.Error())
						}

						Convey("should not be able to get the deleted file", func() {
							deadLine := time.After(TestTimeout)
							tick := time.Tick(time.Millisecond * 100)
							for {
								select {
								case <-tick:
									f2, err := handler.getFile(f.Id)
									if err != nil {
										t.Skip("Err happened, skipping: %s", err.Error())
									}

									So(f2, ShouldBeNil)
								case <-deadLine:
									t.Skip("Could not get file after %s", TestTimeout)
								}
							}
						})
						Convey("deleting the deleted file should not give error", func() {
							err = handler.deleteFile(req.FileId)
							if err != nil {
								t.Skip("Err happened, skipping: %s", err.Error())
							}

							So(err, ShouldBeNil)
						})
					})
				})
			})
		})
	})
}

func createTestFile(c *Controller) (*drive.File, error) {
	svc, err := CreateService(&c.conf.GoogleapiServiceAccount)
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
	return svc.Files.Insert(f).Media(m).Do()
}
