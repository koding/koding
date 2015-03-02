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
}
