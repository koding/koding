package main

import (
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/db/mongodb/modelhelper/modeltesthelper"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"labix.org/v2/mgo/bson"

	"github.com/dgrijalva/jwt-go"
	. "github.com/smartystreets/goconvey/convey"
)

func TestTokenConfirmHandler(t *testing.T) {
	Convey("", t, func() {
		mux := http.NewServeMux()
		mux.HandleFunc("/", TokenConfirmHandler)

		// above handler redirects on success, this prevents problems
		mux.HandleFunc("/IDE", func(w http.ResponseWriter, r *http.Request) {
		})

		server := httptest.NewServer(mux)
		defer server.Close()

		Convey("It should return error if no token param", func() {
			res, err := http.Get(server.URL)
			So(err, ShouldBeNil)

			So(res.StatusCode, ShouldEqual, 500)
		})

		Convey("It should return error if user doesn't exist", func() {
			token := jwt.New(jwt.SigningMethodHS256)
			token.Claims = map[string]interface{}{
				"username": "nonexistentuser",
				"exp":      time.Now().Add(tokenExpiresIn).Unix(),
			}

			tokenStr, err := token.SignedString([]byte(secretKey))
			So(err, ShouldBeNil)

			url := fmt.Sprintf("%s/?token=%s", server.URL, tokenStr)
			res, err := http.Get(url)
			So(err, ShouldBeNil)

			So(res.StatusCode, ShouldEqual, 500)
		})

		Convey("It should confirm user", func() {
			user := &models.User{
				ObjectId: bson.NewObjectId(),
				Name:     "indianajones",
				Email:    "indianajones@koding.com",
				Status:   modelhelper.UserStatusConfirmed,
			}

			defer modeltesthelper.DeleteUsersByUsername(user.Name)

			_, err := modeltesthelper.CreateUserWithQuery(user)
			So(err, ShouldBeNil)

			token := jwt.New(jwt.SigningMethodHS256)
			token.Claims = map[string]interface{}{
				"username": "indianajones",
				"exp":      time.Now().Add(tokenExpiresIn).Unix(),
			}

			tokenStr, err := token.SignedString([]byte(secretKey))
			So(err, ShouldBeNil)

			url := fmt.Sprintf("%s/?token=%s&redirect_url=%s", server.URL, tokenStr, "%2FIDE")
			res, err := http.Get(url)
			So(err, ShouldBeNil)

			So(res.StatusCode, ShouldEqual, 200)

			user, err = modelhelper.GetUser(user.Name)
			So(err, ShouldBeNil)

			So(user.Status, ShouldEqual, modelhelper.UserStatusConfirmed)
		})
	})
}
