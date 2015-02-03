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

		err = modelhelper.Mongo.Run(modelhelper.AccountsCollection, query)
		So(err, ShouldBeNil)

		Convey("Then it returns true if error fetching plan", func() {
			yes := IsUserPaid(user)
			So(yes, ShouldBeTrue)
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

func TestIsUserBlocked(t *testing.T) {
	Convey("Given user who is blocked", t, func() {
		username := "paiduser"
		user := &models.User{
			Name: username, ObjectId: bson.NewObjectId(), Status: "blocked",
		}

		err := modelhelper.CreateUser(user)
		So(err, ShouldBeNil)

		Convey("Then it returns true for exempt", func() {
			yes := IsUserBlocked(user)
			So(yes, ShouldBeTrue)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})
}

func TestIsUserVMsEmpty(t *testing.T) {
	Convey("Given user who has no vms", t, func() {
		user, err := createUser()

		So(err, ShouldBeNil)
		Convey("Then it returns true for exempt", func() {
			yes := IsUserVMsEmpty(user)
			So(yes, ShouldBeTrue)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})

	Convey("Given user who has vms", t, func() {
		user, err := createUserWithVM()

		So(err, ShouldBeNil)
		Convey("Then it returns true for exempt", func() {
			no := IsUserVMsEmpty(user)
			So(no, ShouldBeFalse)
		})

		Reset(func() {
			deleteUserWithUsername(user)
		})
	})
}
