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

func TestPaidUserExempt(t *testing.T) {
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
			yes := PaidUserExempt(user)
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
			modelhelper.RemoveUser(user.Name)
			modelhelper.RemoveAccountByUsername(user.Name)
		})
	})
}
