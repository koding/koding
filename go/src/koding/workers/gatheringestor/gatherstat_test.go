package main

import (
	"bytes"
	"koding/db/mongodb/modelhelper/modeltesthelper"
	"net/http"
	"net/http/httptest"
	"testing"

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
	})
}
