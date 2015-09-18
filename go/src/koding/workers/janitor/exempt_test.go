package main

import (
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/db/mongodb/modelhelper/modeltesthelper"
	"net/http"
	"net/http/httptest"
	"net/url"
	"socialapi/workers/payment/paymentapi"
	"testing"
	"time"

	"labix.org/v2/mgo/bson"

	. "github.com/smartystreets/goconvey/convey"
)

func TestIsUserPaid(t *testing.T) {
	Convey("Given user who is paid", t, func() {
		username := "paiduser"
		user, _, err := modeltesthelper.CreateUser(username)
		So(err, ShouldBeNil)

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
			isPaid, err := paymentclient.IsPaidAccount(account)
			So(err, ShouldBeNil)
			So(isPaid, ShouldBeTrue)
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

	Convey("Given user who is unconfirmed", t, func() {
		username := "unconfirmed"
		user := &models.User{
			Name: username, ObjectId: bson.NewObjectId(), Status: "unconfirmed",
		}

		err := modelhelper.CreateUser(user)
		So(err, ShouldBeNil)

		Convey("Then it returns true for 'not confirmed' exempt", func() {
			isConfirmed, err := IsUserNotConfirmedFn(user, warning)
			So(err, ShouldBeNil)
			So(isConfirmed, ShouldBeTrue)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})
}

func TestIsUserVMsEmpty(t *testing.T) {
	warning := &Warning{}

	Convey("Given user who has no vms", t, func() {
		username := "emptyVmUser"
		user, _, err := modeltesthelper.CreateUser(username)

		So(err, ShouldBeNil)
		Convey("Then it returns true for 'no vm' exempt", func() {
			noVms, err := IsUserVMsEmptyFn(user, warning)

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
		Convey("Then it returns false for 'no vm' exempt", func() {
			noVms, err := IsUserVMsEmptyFn(user, warning)

			So(err, ShouldBeNil)
			So(noVms, ShouldBeFalse)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})

	Convey("Given user who has only managed vms", t, func() {
		user, err := createUserWithManagedVM()

		So(err, ShouldBeNil)
		Convey("Then it returns true for 'no vm' exempt", func() {
			noVms, err := IsUserVMsEmptyFn(user, warning)

			So(err, ShouldBeNil)
			So(noVms, ShouldBeTrue)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})
}

func TestIsTooSoon(t *testing.T) {
	previous := &Warning{
		ID: "previous-testtoosoon",
	}

	warning := &Warning{
		ID: "testtoosoon",
		IntervalSinceLastWarning: time.Hour * 24 * 1,
		PreviousWarning:          previous,
	}

	Convey("Given user who is inactive and was warned yesterday", t, func() {
		user, err := createInactiveUserWithWarning(1, previous.ID)
		So(err, ShouldBeNil)

		Convey("Then it returns true for check", func() {
			tooSoon, err := IsTooSoonFn(user, warning)

			So(err, ShouldBeNil)
			So(tooSoon, ShouldBeTrue)

			Reset(func() {
				deleteUserWithUsername(user)
			})
		})
	})

	Convey("Given user who is inactive and was warned two days ago", t, func() {
		user, err := createInactiveUserWithWarning(1, previous.ID)
		So(err, ShouldBeNil)

		selector := bson.M{"username": user.Name}
		update := bson.M{
			"inactive.warnings": bson.M{
				previous.ID: timeNow().Add(-warning.IntervalSinceLastWarning * 2),
			},
		}

		err = modelhelper.UpdateUser(selector, update)
		So(err, ShouldBeNil)

		Convey("Then it returns false for check", func() {
			user, err := modelhelper.GetUser(user.Name)
			So(err, ShouldBeNil)

			tooSoon, err := IsTooSoonFn(user, warning)

			So(err, ShouldBeNil)
			So(tooSoon, ShouldBeFalse)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})
}

func TestIsUserKodingEmployee(t *testing.T) {
	warning := &Warning{}

	Convey("Given user who has koding email", t, func() {
		username := "not-employee"
		user := &models.User{
			Name: username, ObjectId: bson.NewObjectId(), Status: "confirmed",
			Email: "indiana@gmail.com",
		}

		err := modelhelper.CreateUser(user)
		So(err, ShouldBeNil)

		Convey("Then it returns true for check", func() {
			isEmployee, err := IsUserKodingEmployeeFn(user, warning)
			So(err, ShouldBeNil)
			So(isEmployee, ShouldBeFalse)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})

	Convey("Given user who has koding email", t, func() {
		username := "koding-employee"
		user := &models.User{
			Name: username, ObjectId: bson.NewObjectId(), Status: "confirmed",
			Email: "indiana@koding.com",
		}

		err := modelhelper.CreateUser(user)
		So(err, ShouldBeNil)

		Convey("Then it returns true for check", func() {
			isEmployee, err := IsUserKodingEmployeeFn(user, warning)
			So(err, ShouldBeNil)
			So(isEmployee, ShouldBeTrue)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})
}
