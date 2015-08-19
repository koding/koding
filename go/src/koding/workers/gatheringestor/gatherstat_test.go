package main

import (
	"bytes"
	"koding/db/models"
	"koding/db/mongodb/modelhelper/modeltesthelper"
	"net/http"
	"net/http/httptest"
	"testing"

	"labix.org/v2/mgo/bson"

	"github.com/koding/logging"
	"github.com/koding/metrics"
	"github.com/koding/redis"
	. "github.com/smartystreets/goconvey/convey"
)

func TestGatherStat(t *testing.T) {
	Convey("", t, func() {
		dogclient, err := metrics.NewDogStatsD(WorkerName)
		So(err, ShouldBeNil)

		defer dogclient.Close()

		redisConn, err := redis.NewRedisSession(&redis.RedisConf{Server: conf.Redis.URL})
		So(err, ShouldBeNil)

		defer redisConn.Close()

		redisConn.SetPrefix(WorkerName)

		log := logging.NewLogger(WorkerName)

		g := &GatherStat{dog: dogclient, log: log, redis: redisConn}

		mux := http.NewServeMux()
		mux.Handle("/", g)

		server := httptest.NewServer(mux)
		defer server.Close()

		Convey("It should save stats", func() {
			reqBuf := bytes.NewBuffer([]byte(`{"username":"indianajones"}`))

			res, err := http.Post(server.URL, "application/json", reqBuf)
			So(err, ShouldBeNil)

			defer res.Body.Close()

			So(res.StatusCode, ShouldEqual, 200)

			docs, err := modeltesthelper.GetGatherStatsForUser("indianajones")
			So(err, ShouldBeNil)

			So(len(docs), ShouldEqual, 1)
			So(docs[0].Username, ShouldEqual, "indianajones")

			Reset(func() {
				modeltesthelper.DeleteGatherStatsForUser("indianajones")
			})
		})

		Convey("It should return status of global stop", func() {
			_, err := g.redis.Del(GlobalDisableKey)
			So(err, ShouldBeNil)

			So(g.globalStopEnabled(), ShouldBeTrue)

			So(g.redis.Set(GlobalDisableKey, "true"), ShouldBeNil)
			So(g.globalStopEnabled(), ShouldBeFalse)

			defer g.redis.Del(GlobalDisableKey)
		})

		Convey("It should exempt if user is Koding employee", func() {
			acc1 := &models.Account{
				Id:          bson.NewObjectId(),
				Profile:     models.AccountProfile{Nickname: "indianajones"},
				GlobalFlags: []string{models.AccountFlagStaff},
			}
			err := modeltesthelper.CreateAccount(acc1)
			So(err, ShouldBeNil)

			defer modeltesthelper.DeleteUsersByUsername(acc1.Profile.Nickname)

			isExempt, err := g.isUserExempt(acc1.Profile.Nickname)
			So(err, ShouldBeNil)
			So(isExempt, ShouldBeTrue)

			acc2 := &models.Account{
				Id:      bson.NewObjectId(),
				Profile: models.AccountProfile{Nickname: "genghiskhan"},
			}
			err = modeltesthelper.CreateAccount(acc2)
			So(err, ShouldBeNil)

			defer modeltesthelper.DeleteUsersByUsername(acc2.Profile.Nickname)

			isExempt, err = g.isUserExempt(acc2.Profile.Nickname)
			So(err, ShouldBeNil)
			So(isExempt, ShouldBeFalse)
		})
	})
}
