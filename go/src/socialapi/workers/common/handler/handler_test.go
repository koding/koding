package handler

import (
	"koding/db/mongodb/modelhelper"
	"net/http"
	"socialapi/models"
	"socialapi/workers/common/runner"
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelUpdatedCalculateUnreadItemCount(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	modelhelper.Initialize(r.Conf.Mongo)
	defer modelhelper.Close()

	Convey("while testing get account", t, func() {
		Convey("if cookie is not set, should return nil", func() {
			So(getAccount(&http.Request{}), ShouldBeNil)
		})

		Convey("if cookie value is not set, should return nil", func() {
			req, _ := http.NewRequest("GET", "/", nil)

			expire := time.Now().AddDate(0, 0, 1)
			cookie := http.Cookie{
				Name:    "clientId",
				Value:   "",
				Path:    "/",
				Domain:  "localhost",
				Expires: expire,
			}

			req.AddCookie(&cookie)

			So(getAccount(req), ShouldBeNil)
		})

		Convey("if session doesnt have username, should return nil", func() {
			ses, err := modelhelper.CreateSessionForAccount("")
			So(err, ShouldBeNil)
			So(ses, ShouldNotBeNil)

			req, _ := http.NewRequest("GET", "/", nil)
			expire := time.Now().AddDate(0, 0, 1)
			cookie := http.Cookie{
				Name:    "clientId",
				Value:   ses.ClientId,
				Path:    "/",
				Domain:  "localhost",
				Expires: expire,
			}

			req.AddCookie(&cookie)

			So(getAccount(req), ShouldBeNil)
		})

		Convey("if session is valid, should return account", func() {
			acc, err := models.CreateAccountInBothDbs()
			So(err, ShouldBeNil)
			So(acc, ShouldNotBeNil)

			ses, err := modelhelper.CreateSessionForAccount(acc.Nick)
			So(err, ShouldBeNil)
			So(ses, ShouldNotBeNil)

			req, _ := http.NewRequest("GET", "/", nil)
			expire := time.Now().AddDate(0, 0, 1)
			cookie := http.Cookie{
				Name:    "clientId",
				Value:   ses.ClientId,
				Path:    "/",
				Domain:  "localhost",
				Expires: expire,
			}

			req.AddCookie(&cookie)

			res := getAccount(req)
			So(res, ShouldNotBeNil)
			So(acc.Id, ShouldEqual, res.Id)
		})
	})
}
