package main

import (
	"encoding/json"
	"koding/db/models"
	"koding/db/mongodb/modelhelper/modeltesthelper"
	"net/http"
	"net/http/httptest"
	"testing"

	"labix.org/v2/mgo/bson"

	"github.com/dgrijalva/jwt-go"
	. "github.com/smartystreets/goconvey/convey"
)

func TestTokenGetHandler(t *testing.T) {
	Convey("", t, func() {
		mux := http.NewServeMux()
		mux.HandleFunc("/", TokenGetHandler)

		server := httptest.NewServer(mux)
		defer server.Close()

		Convey("It should return error if no email param", func() {
			res, err := http.Get(server.URL)
			So(err, ShouldBeNil)

			So(res.StatusCode, ShouldEqual, 500)
		})

		Convey("It should generate signed token", func() {
			user := &models.User{
				ObjectId: bson.NewObjectId(),
				Name:     "indianajones",
				Email:    "indianajones@koding.com",
			}

			defer modeltesthelper.DeleteUsersByUsername(user.Name)

			_, err := modeltesthelper.CreateUserWithQuery(user)
			So(err, ShouldBeNil)

			res, err := http.Get(server.URL + "?email=" + user.Email)
			So(err, ShouldBeNil)

			So(res.StatusCode, ShouldEqual, 200)

			var response map[string]string
			err = json.NewDecoder(res.Body).Decode(&response)
			So(err, ShouldBeNil)

			token, err := jwt.Parse(response["token"], tokenKeyFunc)
			So(err, ShouldBeNil)

			username, ok := token.Claims["username"]
			So(ok, ShouldBeTrue)
			So(username, ShouldEqual, user.Name)

			_, ok = token.Claims["exp"]
			So(ok, ShouldBeTrue)
		})
	})
}
