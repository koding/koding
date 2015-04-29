package main

import (
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"net/http"
	"net/http/httptest"
	"net/url"
	"socialapi/workers/payment/paymentapi"
	"testing"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	. "github.com/smartystreets/goconvey/convey"
)

func TestIsUserPaid(t *testing.T) {
	warning := &Warning{}

	Convey("Given user who is paid", t, func() {
		username := "paiduser"
		user := &models.User{
			Name: username, ObjectId: bson.NewObjectId(),
		}

		err := modelhelper.CreateUser(user)
		So(err, ShouldBeNil)

		query := func(c *mgo.Collection) error {
			return c.Insert(bson.M{
				"_id":     bson.NewObjectId(),
				"profile": bson.M{"nickname": username},
			})
		}

		err = modelhelper.Mongo.Run(modelhelper.AccountsColl, query)
		So(err, ShouldBeNil)

		Convey("Then it returns error if error fetching plan", func() {
			_, err := IsUserPaid(user, warning)
			So(err, ShouldNotBeNil)
		})

		Convey("Then it returns true if user is paid", func() {
			mux := http.NewServeMux()
			mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
				fmt.Fprint(w, `{"planTitle":"hobbyist"}`)
			})

			server := httptest.NewServer(mux)
			url, _ := url.Parse(server.URL)

			defer func() {
				server.Close()
			}()

			account, err := modelhelper.GetAccount(username)
			So(err, ShouldBeNil)

			paymentclient := paymentapi.New(url.String())

			yes, err := paymentclient.IsPaidAccount(account)

			So(err, ShouldBeNil)
			So(yes, ShouldBeTrue)
		})

		Convey("Then it returns false if user is free", func() {
			mux := http.NewServeMux()
			mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
				fmt.Fprint(w, `{"planTitle":"free"}`)
			})

			server := httptest.NewServer(mux)
			url, _ := url.Parse(server.URL)

			defer func() {
				server.Close()
			}()

			account, err := modelhelper.GetAccount(username)
			So(err, ShouldBeNil)

			paymentclient := paymentapi.New(url.String())

			no, err := paymentclient.IsPaidAccount(account)
			So(err, ShouldBeNil)
			So(no, ShouldBeFalse)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})
}

func TestIsUserNotConfirmed(t *testing.T) {
	warning := &Warning{}

	Convey("Given user who is blocked", t, func() {
		username := "paiduser"
		user := &models.User{
			Name: username, ObjectId: bson.NewObjectId(), Status: "blocked",
		}

		err := modelhelper.CreateUser(user)
		So(err, ShouldBeNil)

		Convey("Then it returns true for exempt", func() {
			isBlocked, err := IsUserNotConfirmed(user, warning)
			So(err, ShouldBeNil)
			So(isBlocked, ShouldBeTrue)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})
}

func TestIsUserVMsEmpty(t *testing.T) {
	warning := &Warning{}

	Convey("Given user who has no vms", t, func() {
		user, err := createUser()

		So(err, ShouldBeNil)
		Convey("Then it returns true for exempt", func() {
			noVms, err := IsUserVMsEmpty(user, warning)

			So(err, ShouldBeNil)
			So(noVms, ShouldBeTrue)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})

	Convey("Given user who has vms", t, func() {
		user, err := createUserWithVM()

		So(err, ShouldBeNil)
		Convey("Then it returns true for exempt", func() {
			noVms, err := IsUserVMsEmpty(user, warning)

			So(err, ShouldBeNil)
			So(noVms, ShouldBeFalse)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})
}

func TestIsTooSoon(t *testing.T) {
	warning := SecondEmail

	Convey("Given user who is inactive and has been warned", t, func() {
		user, err := createInactiveUserWithWarning(warning.Interval+1, warning.Level)
		So(err, ShouldBeNil)

		Convey("Then it returns true if warned time < warning interval", func() {
			tooSoon, err := IsTooSoon(user, warning)

			So(err, ShouldBeNil)
			So(tooSoon, ShouldBeFalse)

			Reset(func() {
				deleteUserWithUsername(user)
			})
		})
	})

	Convey("Given user who is inactive and has been warned", t, func() {
		user, err := createInactiveUserWithWarning(warning.Interval*2, warning.Level-1)
		So(err, ShouldBeNil)

		lastWarningDate := timeNow().Add(-warning.IntervalSinceLastWarning * 2)

		selector := bson.M{"username": user.Name}
		update := bson.M{
			"inactive.warnings": bson.M{
				fmt.Sprintf("%d", warning.Level-1): lastWarningDate,
			},
		}

		err = modelhelper.UpdateUser(selector, update)
		So(err, ShouldBeNil)

		Convey("Then it returns false if warned time > warning interval", func() {
			user, err := modelhelper.GetUser(user.Name)
			So(err, ShouldBeNil)

			tooSoon, err := IsTooSoon(user, warning)

			So(err, ShouldBeNil)
			So(tooSoon, ShouldBeFalse)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})
}
