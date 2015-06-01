package main

import (
	"net/http"
	"testing"
	"time"

	"github.com/dgrijalva/jwt-go"
	. "github.com/smartystreets/goconvey/convey"
)

func init() {
	Jwttoken = "ac25b4e6009c1b6ba336a3eb17fbc3b7"
}

func newTestReq(token string) (*http.Request, error) {
	url := "http://koding.com/-/token/confirm?token=" + token
	return http.NewRequest("GET", url, nil)
}

func TestValidateJWTToken(t *testing.T) {
	Convey("It should return err if request has token param", t, func() {
		req, err := newTestReq("")
		So(err, ShouldBeNil)

		_, err = validateJWTToken(req)
		So(err, ShouldEqual, ErrNoTokenInQuery)
	})

	Convey("It should return err if token can't be parsed", t, func() {
		req, err := newTestReq("randomtoken")
		So(err, ShouldBeNil)

		_, err = validateJWTToken(req)
		So(err, ShouldNotBeNil)
	})

	Convey("It should return err if token is expired", t, func() {
		token := jwt.New(jwt.SigningMethodHS256)
		token.Claims = map[string]interface{}{
			"exp": time.Now().Add(-1 * time.Hour).Unix(),
		}

		tokenStr, err := token.SignedString([]byte(Jwttoken))
		So(err, ShouldBeNil)

		req, err := newTestReq(tokenStr)
		So(err, ShouldBeNil)

		_, err = validateJWTToken(req)
		So(err, ShouldNotBeNil)
	})

	Convey("It should return err if no username in claims", t, func() {
		token := jwt.New(jwt.SigningMethodHS256)
		token.Claims = map[string]interface{}{
			"exp": time.Now().Add(tokenExpiresIn).Unix(),
		}

		tokenStr, err := token.SignedString([]byte(Jwttoken))
		So(err, ShouldBeNil)

		req, err := newTestReq(tokenStr)
		So(err, ShouldBeNil)

		_, err = validateJWTToken(req)
		So(err, ShouldEqual, ErrNoUsernameInClaims)
	})

	Convey("It should return claims", t, func() {
		token := jwt.New(jwt.SigningMethodHS256)
		token.Claims = map[string]interface{}{
			"username": "indianajones",
			"exp":      time.Now().Add(tokenExpiresIn).Unix(),
		}

		tokenStr, err := token.SignedString([]byte(Jwttoken))
		So(err, ShouldBeNil)

		req, err := newTestReq(tokenStr)
		So(err, ShouldBeNil)

		claims, err := validateJWTToken(req)
		So(err, ShouldBeNil)

		username, ok := claims["username"].(string)
		So(ok, ShouldBeTrue)
		So(username, ShouldEqual, "indianajones")
	})
}
