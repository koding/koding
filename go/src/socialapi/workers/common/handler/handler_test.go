package handler

import (
	"koding/db/mongodb/modelhelper"
	"net/http"
	"socialapi/config"
	"socialapi/models"
	"testing"
	"time"

	"github.com/koding/runner"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelUpdatedCalculateUnreadItemCount(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	groupName := models.RandomGroupName()

	Convey("while testing get account", t, func() {
		Convey("if cookie is not set, should return nil", func() {
			a := getAccount(&http.Request{})
			So(a, ShouldNotBeNil)
			So(a.Id, ShouldBeZeroValue)
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

			a := getAccount(req)
			So(a, ShouldNotBeNil)
			So(a.Id, ShouldBeZeroValue)
		})

		Convey("if session doesnt have username, should return nil", func() {
			ses, err := modelhelper.CreateSessionForAccount("", groupName)
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

			a := getAccount(req)
			So(a, ShouldNotBeNil)
			So(a.Id, ShouldBeZeroValue)
		})

		Convey("if session is valid, should return account", func() {
			acc, err := models.CreateAccountInBothDbs()
			So(err, ShouldBeNil)
			So(acc, ShouldNotBeNil)

			ses, err := modelhelper.CreateSessionForAccount(acc.Nick, groupName)
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
